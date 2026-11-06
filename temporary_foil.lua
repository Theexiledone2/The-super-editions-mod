local lease_key = 'supereditions_temporary_foil'

-- A saved status with a tooltip, not a randomly spawning visual sticker.
-- The normal Foil shader supplies the visual during the five-round duration.
SMODS.Sticker {
    key = 'temporary_foil',
    config = {remaining = 5, last_round = -1},
    default_compat = true,
    sets = {Joker = true},
    rate = 0,
    badge_colour = {0.55, 0.75, 0.88, 1},
    loc_txt = {
        name = 'Temporary Foil',
        label = 'Temporary Foil',
        text = {
            '{C:attention}#1#{} rounds remaining',
            'Then loses {C:dark_edition}Foil{}',
            'and gains {C:attention}Rental{}',
        },
    },
    should_apply = function() return false end,
    draw = function() end,
    loc_vars = function(self, info_queue, card)
        local state = card and card.ability and card.ability[lease_key]
        return {vars = {type(state) == 'table' and state.remaining or 5}}
    end,
}

local function update_timers(context)
    if not context.round_eval or context.blueprint or context.retrigger_joker
        or context.individual or context.repetition or context.game_over then return end
    local game = G and G.GAME
    if not game or type(game.round) ~= 'number' then return end
    -- Round numbers and card ability fields survive saves. Cashout may be
    -- evaluated more than once; each card advances only once for that round.
    game.supereditions_last_foil_round = game.round
    for _, joker in ipairs(G.jokers and G.jokers.cards or {}) do
        local state = joker.ability and joker.ability[lease_key]
        if type(state) == 'table' and type(state.remaining) == 'number' then
            if state.remaining > 0 and state.last_round ~= game.round then
                state.remaining = state.remaining - 1
                state.last_round = game.round
            end
            if state.remaining <= 0 then
                -- A later edition change does not cancel the Rental due date,
                -- but expiration must not erase a different new edition.
                if joker.edition and joker.edition.foil then
                    joker:set_edition(nil, true)
                end
                if not joker.ability.rental then joker:add_sticker('rental', true) end
                joker:remove_sticker(lease_key)
            end
        end
    end
end

local mod = SMODS.current_mod
local previous_calculate = mod.calculate
mod.calculate = function(self, context)
    local effect, triggered
    if previous_calculate then effect, triggered = previous_calculate(self, context) end
    update_timers(context)
    return effect, triggered
end
