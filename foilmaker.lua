-- Keep the owner after Steamodded clears current_mod at the end of loading.
local mod = SMODS.current_mod

-- Public Steamodded callbacks only; no replacement of the scoring engine.
local max_score = 1.7976931348623157e308

local function chips_per_scored_card(card)
    -- Compute from the current edition without changing the saved base rate
    -- or retroactively multiplying the accumulated bonus.
    local foil = card.edition and card.edition.foil == true
    return card.ability.extra.chips_per_card * (foil and 2 or 1)
end

SMODS.Atlas {
    key = 'foilmaker',
    path = 'foilmaker.png',
    px = 1084,
    py = 1451,
    force_pixel = true,
    disable_mipmap = true,
}

SMODS.Joker {
    key = 'foilmaker',
    atlas = 'foilmaker',
    pos = {x = 0, y = 0},
    rarity = 3,
    cost = 8,
    unlocked = true,
    discovered = true,
    blueprint_compat = false,
    eternal_compat = true,
    perishable_compat = true,
    config = {extra = {
        chips = 0,
        chips_per_card = 5,
        threshold = 10000,
        factor = 3,
        awaiting_finish = false,
    }},

    loc_vars = function(self, info_queue, card)
        local extra = card.ability.extra
        return {vars = {chips_per_scored_card(card), extra.chips, extra.factor, extra.threshold}}
    end,

    calculate = function(self, card, context)
        local extra = card.ability.extra
        if context.blueprint or context.retrigger_joker then return end

        -- These lifecycle flags cannot award anything and must clear even if
        -- a copy is debuffed, preventing an old hand from being paid later.
        if context.before then
            extra.awaiting_finish = not card.debuff
            return
        end
        if context.debuffed_hand or context.end_of_round then
            extra.awaiting_finish = false
            return
        end
        if card.debuff then
            extra.awaiting_finish = false
            return
        end

        if context.individual and context.cardarea == G.play
            and context.other_card and not context.other_card.debuff then
            -- Real playing-card retriggers earn the current +5 / Foil +10.
            -- Repetition queries and Joker retriggers do not earn chips.
            local gain = chips_per_scored_card(card)
            extra.chips = extra.chips + gain
            return {
                message = localize {type = 'variable', key = 'a_supereditions_factory_gain', vars = {gain}},
                colour = G.C.CHIPS,
                no_retrigger = true,
            }
        end

        if context.joker_main and extra.chips > 0 then
            return {chips = extra.chips, no_retrigger = true}
        end

        if context.after and extra.awaiting_finish then
            extra.awaiting_finish = false
            -- last_hand_score is the finished hand (including deck effects),
            -- whereas G.GAME.chips also contains points from earlier hands.
            local base = SMODS.last_hand_score
            local numbers = mod.supereditions_numbers
            local extended = numbers and numbers.active and numbers.active()
            if not (type(base) == 'number' or extended and numbers.is(base)) or base ~= base or base == math.huge
                or base < extra.threshold then return end
            local triggers = math.floor(base / extra.threshold)
            -- Freeze the count before multiplying: this copy must not earn
            -- additional triggers from its own increased score.
            -- Evaluate in constant time rather than queueing millions of effects.
            local exponent = triggers * math.log(extra.factor)
            local boosted
            if extended then
                boosted = numbers.mul(base, numbers.pow(extra.factor, triggers))
            elseif exponent >= math.log(max_score) - math.log(base) then
                boosted = max_score
            else
                boosted = math.min(max_score, base * extra.factor ^ triggers)
            end
            -- Keep native Lua scores finite, including an existing round total.
            local bonus = extended and numbers.sub(boosted, base)
                or math.min(boosted - base, math.max(0, max_score - G.GAME.chips))
            if bonus <= 0 then return end
            SMODS.last_hand_score = base + bonus
            SMODS.last_hand_oneshot = SMODS.last_hand_score >= G.GAME.blind.chips
            local game, final_score = G.GAME, SMODS.last_hand_score
            local queued = false
            -- The base score has already been queued as an ease event. Paying
            -- a score effect now would be overwritten by that event's target.
            -- Publish the final hand value now for other after-hand abilities,
            -- but award the bonus after the native tally/reset events finish.
            return {
                func = function()
                    if queued then return end
                    queued = true
                    G.E_MANAGER:add_event(Event({
                        trigger = 'immediate',
                        func = function()
                            if G.GAME ~= game then return true end
                            local awarded = extended and bonus
                                or math.min(bonus, math.max(0, max_score - game.chips))
                            if awarded > 0 then
                                SMODS.calculate_effect({
                                    score = awarded,
                                    message = localize {type = 'variable', key = 'a_supereditions_factory_boost', vars = {extra.factor, triggers}},
                                    colour = G.C.CHIPS,
                                    remove_default_message = true,
                                }, card)
                                -- The engine recorded the unboosted hand before
                                -- context.after. Keep the best-hand record and
                                -- score unlocks consistent with this award too.
                                check_and_set_high_score('hand', final_score)
                                check_for_unlock({type = 'chip_score', chips = math.floor(final_score)})
                            end
                            return true
                        end,
                    }))
                end,
                no_retrigger = true,
            }
        end
    end,
}
