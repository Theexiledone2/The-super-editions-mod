local key = 'j_supereditions_jack_of_red_trades'
local scoring
local function packed(...) return {n = select('#', ...), ...} end
local function live(card)
    return card and not card.debuff and not card.removed and not card.getting_sliced
        and not card.destroyed and not (type(card.dissolve) == 'number' and card.dissolve > 0)
end
local function is_jack(card)
    return card and card.config and card.config.center and card.config.center.key == key
end
for _, suffix in ipairs({'', '_charged'}) do
    SMODS.Atlas {
        key = 'jack_of_red_trades' .. suffix,
        path = suffix == '' and 'jack-of-red-trades.png' or 'jack-of-red-trades-charged.png',
        px = 1084, py = 1451, force_pixel = true, disable_mipmap = true,
    }
end
SMODS.Joker {
    key = 'jack_of_red_trades', atlas = 'jack_of_red_trades_charged', pos = {x = 0, y = 0},
    rarity = 3, cost = 8, unlocked = true, discovered = true,
    blueprint_compat = false, eternal_compat = true, perishable_compat = true,
    config = {extra = {seals = 1, rounds = 0, last_round = -1}},
    loc_txt = {name = 'Jack of red trades', text = {
        'Every {C:attention}2{} rounds, gain a',
        '{C:red}Red Seal{} {C:inactive}(limit 1){}',
        'Apply it to the first card that',
        '{C:attention}retriggers{} in a hand',
        '{C:inactive}(Replaces its current seal){}',
        '{C:inactive}(Starts with 1 seal; retriggers immediately){}',
        '{C:inactive}(Stored: {C:attention}#1#{C:inactive}; rounds: #2#/2){}',
    }},
    loc_vars = function(self, info_queue, card)
        local e = card and card.ability and card.ability.extra or self.config.extra
        return {vars = {e.seals, e.rounds}}
    end,
    calculate = function(self, card, context)
        if not (live(card) and context.end_of_round and not context.individual
            and not context.repetition and not context.repetition_only and not context.game_over
            and not context.blueprint and not context.retrigger_joker and not context.retrigger_joker_check
            and not context.post_trigger and not context.supereditions_gum_replay
            and not context.supereditions_poli_faker_replay) then return end
        local e = card.ability.extra
        if e.last_round == G.GAME.round then return end
        e.last_round = G.GAME.round
        e.rounds = e.rounds + 1
        if e.rounds >= 2 then
            e.rounds = 0
            local gained = e.seals < 1
            e.seals = 1
            if gained then return {message = 'Red Seal!', colour = G.C.RED, no_retrigger = true} end
        end
    end,
}

-- The initial score has finished before the framework builds this queue.
-- A genuine extra score must already be queued; Jack cannot start a repeat
-- by itself or spend its seal on preview/query calls. Loaded before Stamp so
-- Stamp sees the newly-applied Red Seal without recalculating any Joker.
local old_score = rawget(SMODS, 'score_card')
local old_repetitions = rawget(SMODS, 'calculate_repetitions')
if type(old_score) == 'function' and type(old_repetitions) == 'function' then
    SMODS.score_card = function(card, context, ...)
        local parent = scoring
        scoring = {card = card, context = context, game = G and G.GAME}
        local result = packed(pcall(old_score, card, context, ...))
        scoring = parent
        if not result[1] then error(result[2], 0) end
        return unpack(result, 2, result.n)
    end
    SMODS.calculate_repetitions = function(card, context, reps, ...)
        local first = #reps + 1
        local result = packed(old_repetitions(card, context, reps, ...))
        if not (scoring and scoring.card == card and scoring.context == context
            and G and G.GAME == scoring.game and G.jokers and live(card)
            and not context.end_of_round and context.repetition
            and (context.cardarea == G.play or context.cardarea == G.hand)) then
            return unpack(result, 1, result.n)
        end
        local repeats = false
        for i = first, #reps do
            if type(reps[i]) == 'table' then
                local _, effect = next(reps[i])
                if type(effect) == 'table' and not effect.retrigger_flag then repeats = true; break end
            end
        end
        if repeats then
            for _, jack in ipairs(G.jokers.cards or {}) do
                if is_jack(jack) and live(jack) and jack.ability.extra.seals > 0 then
                    card:set_seal('Red', true, true)
                    if card.seal == 'Red' then
                        jack.ability.extra.seals = 0
                        reps[#reps + 1] = {retriggers = {card = card, repetitions = 1,
                            message = localize('k_again_ex'), colour = G.C.RED}}
                        if card_eval_status_text then
                            card_eval_status_text(jack, 'extra', nil, nil, nil,
                                {message = 'Red Seal!', colour = G.C.RED})
                        end
                    end
                end
            end
        end
        return unpack(result, 1, result.n)
    end
end

if Card and type(Card.draw) == 'function' then
    local previous = Card.draw
    Card.draw = function(self, ...)
        if is_jack(self) and self.children and self.ability and self.ability.extra then
            local suffix = self.ability.extra.seals > 0 and '_charged' or ''
            local atlas = G and G.ASSET_ATLAS and G.ASSET_ATLAS['supereditions_jack_of_red_trades' .. suffix]
            local sprite = self.children.center
            if sprite and atlas and sprite.atlas ~= atlas then
                sprite.atlas = atlas
                sprite:set_sprite_pos({x = 0, y = 0})
            end
        end
        return previous(self, ...)
    end
end
