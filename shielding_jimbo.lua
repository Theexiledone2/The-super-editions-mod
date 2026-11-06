local joker_key = 'j_supereditions_shielding_jimbo'

local function has_foil(card)
    return card.edition and card.edition.foil == true
end

SMODS.Atlas {
    key = 'shielding_jimbo',
    path = 'shielding-jimbo.png',
    px = 1084,
    py = 1451,
    force_pixel = true,
    disable_mipmap = true,
}

SMODS.Joker {
    key = 'shielding_jimbo',
    atlas = 'shielding_jimbo',
    pos = {x = 0, y = 0},
    rarity = 3,
    cost = 6,
    unlocked = true,
    discovered = true,
    blueprint_compat = false,
    eternal_compat = true,
    perishable_compat = true,
    config = {extra = {
        reserve = 0,
        chips_per_draw = 15,
        foil_xchips = 1,
        foil_per_discard = 1,
    }},

    loc_vars = function(self, info_queue, card)
        local extra = card.ability.extra
        if has_foil(card) then
            return {
                key = joker_key .. '_foil',
                vars = {extra.foil_per_discard, extra.foil_xchips},
            }
        end
        info_queue[#info_queue + 1] = {
            set = 'Other',
            key = 'supereditions_shield_foil',
            vars = {extra.foil_per_discard},
        }
        return {vars = {extra.chips_per_draw, extra.reserve}}
    end,

    calculate = function(self, card, context)
        -- Count actual draws/discards once, including when retrigger mods exist.
        if card.debuff or context.blueprint or context.retrigger_joker then return end
        local extra = card.ability.extra

        if has_foil(card) then
            if context.discard and context.other_card then
                extra.foil_xchips = extra.foil_xchips + extra.foil_per_discard
                return {
                    message = localize {type = 'variable', key = 'a_supereditions_shield_foil', vars = {extra.foil_xchips}},
                    colour = G.C.CHIPS,
                    no_retrigger = true,
                }
            end
            if context.joker_main and G.GAME.current_round.hands_left == 0
                and extra.foil_xchips > 1 then
                return {xchips = extra.foil_xchips, no_retrigger = true}
            end
            -- Foil replaces both reserve charging and the emergency payout.
            return
        end

        local drawn = context.hand_drawn or context.other_drawn
        if type(drawn) == 'table' and #drawn > 0 then
            local gain = extra.chips_per_draw * #drawn
            extra.reserve = extra.reserve + gain
            return {
                message = localize {type = 'variable', key = 'a_supereditions_shield_store', vars = {gain}},
                colour = G.C.CHIPS,
                no_retrigger = true,
            }
        end

        -- End-of-round main evaluation happens after the hand's score is known.
        -- 'score' adds to the round total, so Mult cannot multiply the reserve.
        if context.end_of_round and context.main_eval and context.game_over
            and G.GAME.current_round.hands_left == 0
            and G.GAME.chips < G.GAME.blind.chips and extra.reserve > 0 then
            local payout = extra.reserve
            extra.reserve = 0
            local rescues_run = G.GAME.chips + payout >= G.GAME.blind.chips
            return {
                score = payout,
                saved = rescues_run and 'k_supereditions_shield_saved' or nil,
                no_retrigger = true,
            }
        end
    end,
}

-- Round cleanup must also reach debuffed/perished copies, which do not run
-- their own calculate callback. This does not trigger a scoring ability.
SMODS.current_mod.calculate = function(self, context)
    if context.end_of_round and not context.blueprint and not context.retrigger_joker then
        for _, card in ipairs(G.jokers and G.jokers.cards or {}) do
            if card.config and card.config.center and card.config.center.key == joker_key then
                card.ability.extra.foil_xchips = 1
            end
        end
    end
end
