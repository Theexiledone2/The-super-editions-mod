local function shallow(t)
    local r = {}; for k, v in pairs(t) do r[k] = v end; return r
end

local function left_of(card)
    local cards = G and G.jokers and G.jokers.cards or {}
    for i, candidate in ipairs(cards) do
        if candidate == card then
            local target = cards[i - 1]
            if target and not target.removed and not target.getting_sliced then return target end
            return
        end
    end
end

local function scoring(context)
    if not context or context.before or context.after or context.end_of_round
        or context.repetition or context.repetition_only or context.post_trigger
        or context.retrigger_joker_check or context.edition or context.debuffed_hand then return false end
    return context.joker_main or context.other_joker
        or (context.individual and (context.cardarea == G.play or context.cardarea == G.hand))
end

local function replay(context)
    return context.retrigger_joker or context.supereditions_mayor_replay
        or context.supereditions_gum_replay or context.supereditions_poli_faker_replay
end

-- Inspect only the copied ability's returned effects, never its configuration,
-- card object, edition, or text. Follow the effect's extra chain, cycle-safely.
local function awards_xmult(effect, seen)
    if type(effect) ~= 'table' then return false end
    seen = seen or {}; if seen[effect] then return false end; seen[effect] = true
    for _, key in ipairs({'x_mult', 'Xmult', 'xmult', 'x_mult_mod', 'Xmult_mod'}) do
        local value = effect[key]
        if type(value) == 'number' and value == value and value ~= 1 then return true end
        if type(value) == 'table' or type(value) == 'userdata' then
            local ok, different = pcall(function() return value > 1 or value < 1 end)
            if ok and different then return true end
        end
    end
    return awards_xmult(effect.extra, seen)
end

SMODS.Atlas {
    key = 'mayor', path = 'mayor.png', px = 1084, py = 1451,
    force_pixel = true, disable_mipmap = true,
}
SMODS.Joker {
    key = 'mayor', atlas = 'mayor', pos = {x = 0, y = 0},
    rarity = 3, cost = 12, unlocked = true, discovered = true,
    blueprint_compat = true, eternal_compat = true, perishable_compat = true,
    loc_txt = {name = 'Mayor', text = {
        'Copies ability of {C:attention}Joker{} to the left',
        'If copied ability gives {X:mult,C:white}XMult{}',
        'during scoring, {C:attention}retrigger{} this Joker once',
        '{C:inactive}(Compatible abilities only){}',
    }},
    calculate = function(self, card, context)
        if card.debuff or card.removed or card.getting_sliced then return end
        local target = left_of(card)
        if not target or target.debuff or not target.config.center.blueprint_compat
            or context.no_blueprint then return end
        local actor = context.blueprint_card or card

        if context.retrigger_joker_check then
            local original = context.other_context
            if context.other_card == actor and not actor.debuff
                and scoring(original) and not replay(original)
                and awards_xmult(context.other_ret and context.other_ret.jokers) then
                return {repetitions = 1, message = 'Again!', card = actor, no_retrigger = true}
            end
            return
        end
        -- A replay re-evaluates the copied ability, not a cached multiplier.
        -- Clear only Mayor's own native replay marker for guarded abilities;
        -- keep Blueprint context so copied permanent upgrades are not doubled.
        local forwarded = context
        if context.retrigger_joker == actor then
            forwarded = shallow(context)
            forwarded.retrigger_joker = nil
            forwarded.supereditions_mayor_replay = true
        end
        local effect = SMODS.blueprint_effect(card, target, forwarded)
        if type(effect) == 'table' and scoring(context) then
            if replay(context) then
                effect = shallow(effect); effect.no_retrigger = true
            elseif awards_xmult(effect) and effect.no_retrigger then
                effect = shallow(effect); effect.no_retrigger = nil
            end
        end
        return effect
    end,
}
