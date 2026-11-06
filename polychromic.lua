local state_key = 'supereditions_polychromic'
local limit = 10
local function pack(...) return {n = select('#', ...), ...} end
local function copy(t)
    local result = {}; for k, v in pairs(t) do result[k] = v end; return result
end
local function state(create)
    local game = G and G.GAME
    if not game then return end
    if create and not game[state_key] then
        game[state_key] = {pending = 0, active = 0, in_round = false}
    end
    return game[state_key]
end
local function ordinary(context)
    return not (context.blueprint or context.retrigger_joker or context.retrigger_joker_check
        or context.post_trigger or context.repetition_only)
end

SMODS.Atlas {
    key = 'polychromic_tag', path = 'polychromic-tag.png',
    px = 1254, py = 1254, force_pixel = true, disable_mipmap = true,
}

SMODS.Tag {
    key = 'polychromic', atlas = 'polychromic_tag',
    pos = {x = 0, y = 0},
    discovered = true, min_ante = 0, weight = 10,
    config = {type = 'new_blind_choice'},
    loc_txt = {
        name = 'Polychromic Tag',
        text = {
            'Retrigger {C:dark_edition}Polychrome{} playing',
            'cards {C:attention}1{} extra time throughout',
            'the next {C:attention}played round{}',
            '{C:inactive}(Stacks up to 10 times; excludes Jokers){}',
        },
    },
    in_pool = function()
        local saved = state(false)
        return not saved or (saved.pending or 0) < limit
    end,
    apply = function(self, tag, context)
        if context.type ~= 'new_blind_choice' or tag.triggered then return end
        local saved = state(true)
        if not saved then return end
        local accepted = (saved.pending or 0) < limit
        -- Reserve immediately, before animation callbacks. Double Tag copies
        -- can arrive in the same queue; they must share the same ten-tag cap.
        if accepted then saved.pending = (saved.pending or 0) + 1 end
        tag.triggered = true
        local ok, err = pcall(tag.yep, tag, accepted and '+1' or 'Max!', G.C.PURPLE,
            function() return true end)
        if not ok then
            if accepted then saved.pending = saved.pending - 1 end
            tag.triggered = false
            error(err, 0)
        end
        return true
    end,
}

local mod = SMODS.current_mod
local previous = mod.calculate
mod.calculate = function(self, context)
    local result = previous and pack(previous(self, context)) or {n = 0}
    local saved = state(false)
    if not saved or not ordinary(context) then return unpack(result, 1, result.n) end

    if context.setting_blind and not saved.in_round then
        saved.active = math.min(limit, saved.pending or 0)
        saved.pending, saved.in_round = 0, true
    end

    -- Cashout occurs after held-card end-of-round effects (e.g. Gold cards).
    -- Skipping a Blind never activates or expires these charges.
    if context.round_eval and not context.individual and not context.repetition then
        saved.active, saved.in_round = 0, false
    end

    local target = context.other_card
    if saved.in_round and (saved.active or 0) > 0 and context.repetition
        and not context.individual and (context.cardarea == G.play or context.cardarea == G.hand)
        and target and not target.debuff and target.edition and target.edition.polychrome
        and not (target.config and target.config.center and target.config.center.set == 'Joker')
        and not (target.ability and target.ability.set == 'Joker') then
        local effect = type(result[1]) == 'table' and copy(result[1]) or {}
        effect.repetitions = (effect.repetitions or 0) + math.min(limit, saved.active)
        effect.message = effect.message or 'Again!'
        effect.card = effect.card or target
        effect.no_retrigger = true
        result[1], result[2], result.n = effect, true, math.max(2, result.n)
    end
    return unpack(result, 1, result.n)
end
