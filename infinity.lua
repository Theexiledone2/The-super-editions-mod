local bonus = 1.7e308
local function passive(context)
    return not context.blueprint and not context.retrigger_joker
        and not context.retrigger_joker_check and not context.post_trigger
        and not context.individual and not context.repetition and not context.repetition_only
        and not context.supereditions_gum_replay and not context.supereditions_poli_faker_replay
end

SMODS.Atlas {
    key = 'infinity', path = 'infinity.png', px = 1084, py = 1451,
    force_pixel = true, disable_mipmap = true,
}
SMODS.Joker {
    key = 'infinity', atlas = 'infinity', pos = {x = 0, y = 0},
    rarity = 'supereditions_epic', cost = 12, unlocked = true, discovered = true,
    blueprint_compat = true, eternal_compat = true, perishable_compat = false,
    config = {extra = {remaining = 10, last_round = -1, pending_reset = false}},
    loc_txt = {name = 'Infinity', text = {'∞'}},
    calculate = function(self, card, context)
        local extra = card.ability.extra
        -- A spent charge resets even if the Joker becomes debuffed later in
        -- the same hand. Keep 0 through its scoring/replay window so copied
        -- effects and normal Joker retriggers see the same charged hand.
        if passive(context) and context.after and extra.pending_reset then
            extra.remaining, extra.pending_reset = 10, false
            return
        end
        if passive(context) and context.end_of_round and not context.game_over then
            -- Fallback for an interrupted after-hand callback. This completed
            -- round still counts as the first round of the new charge cycle.
            if extra.pending_reset then extra.remaining, extra.pending_reset = 10, false end
            if not card.debuff and extra.remaining > 0 and extra.last_round ~= G.GAME.round then
                extra.last_round = G.GAME.round
                extra.remaining = extra.remaining - 1
                return {message = tostring(extra.remaining), colour = {1, 0.82, 0.25, 1}, no_retrigger = true}
            end
            return
        end
        if not card.debuff and context.joker_main and not context.debuffed_hand
            and not context.individual and not context.repetition and not context.repetition_only
            and not context.retrigger_joker_check and not context.post_trigger
            and extra.remaining == 0 then
            if not context.blueprint then extra.pending_reset = true end
            -- Exact requested native-number multiplier. It is finite on its
            -- own; subsequent game arithmetic can overflow normally.
            return {xmult = bonus}
        end
    end,
}
