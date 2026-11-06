local joker_key = 'j_supereditions_poli_faker'
local function pack(...) return {n = select('#', ...), ...} end
local function copy(t)
    local result = {}; for key, value in pairs(t) do result[key] = value end
    return result
end
local function is_faker(card)
    -- Some native retrigger paths supply true rather than the source Card.
    return type(card) == 'table' and card.config and card.config.center and card.config.center.key == joker_key
end
local function polychrome(card)
    return type(card) == 'table' and not card.debuff and card.edition and card.edition.polychrome
end
local function owned(card)
    for _, value in ipairs(G and G.jokers and G.jokers.cards or {}) do
        if value == card then return true end
    end
    return false
end
local function sources()
    local count = 0
    for _, card in ipairs(G and G.jokers and G.jokers.cards or {}) do
        if is_faker(card) and not card.debuff then count = count + card.ability.extra.repetitions end
    end
    return count
end
local function ordinary(context)
    return context and not context.repetition and not context.retrigger_joker_check
        and not context.post_trigger and not context.retrigger_joker
        and not context.supereditions_poli_faker_replay
end

-- Retain the mod's previously enabled features, notably Foil Deck weights.
local mod = SMODS.current_mod
if type(mod.optional_features) == 'function' then
    local previous = mod.optional_features
    mod.optional_features = function(...)
        local features = copy(previous(...) or {})
        features.retrigger_joker = true
        return features
    end
else
    mod.optional_features = mod.optional_features or {}
    mod.optional_features.retrigger_joker = true
end

SMODS.Atlas {
    key = 'poli_faker', path = 'poli-faker.png', px = 1084, py = 1451,
    force_pixel = true, disable_mipmap = true,
}
SMODS.Joker {
    key = 'poli_faker', atlas = 'poli_faker', pos = {x = 0, y = 0},
    rarity = 3, cost = 8, unlocked = true, discovered = true,
    -- Edition replay is an owned-Joker effect, not an ability Blueprint copies.
    blueprint_compat = false, eternal_compat = true, perishable_compat = true,
    config = {extra = {repetitions = 1}},
    loc_txt = {
        name = 'Poli-faker',
        text = {
            'Retrigger {C:dark_edition}Polychrome{}',
            'playing cards and {C:attention}Jokers{}',
            '{C:attention}#1#{} additional time',
            'Includes their {C:dark_edition}edition{} effects',
        },
    },
    loc_vars = function(self, info_queue, card)
        return {vars = {card.ability.extra.repetitions}}
    end,
    calculate = function(self, card, context)
        if card.debuff or context.blueprint or context.retrigger_joker
            or context.supereditions_poli_faker_replay then return end
        local target = context.other_card
        if not polychrome(target) then return end
        if context.repetition and (context.cardarea == G.play or context.cardarea == G.hand) then
            -- Native card repeats include enhancements, seals, played editions
            -- and held effects supplied by an editionless Pollinator or Baron.
            return {repetitions = card.ability.extra.repetitions,
                message = 'Again!', card = card, no_retrigger = true}
        end
        if context.retrigger_joker_check and owned(target) and not is_faker(target)
            and ordinary(context.other_context) then
            return {repetitions = card.ability.extra.repetitions,
                message = 'Again!', card = card, no_retrigger = true}
        end
    end,
}

-- Existing custom Jokers deliberately reject generic Joker retriggers.
-- For this explicitly requested effect, allow a fresh ability evaluation only
-- when the retrigger comes from an owned Poli-faker and the target is Polychrome.
-- Calls without Poli-faker keep their exact original context and return values.
if Card and type(Card.calculate_joker) == 'function' then
    local calculate_joker = Card.calculate_joker
    Card.calculate_joker = function(self, context, ...)
        local replay = context and is_faker(context.retrigger_joker)
            and owned(context.retrigger_joker) and not context.retrigger_joker.debuff
            and polychrome(self) and owned(self) and not is_faker(self)
        local forwarded = context
        if replay then
            forwarded = copy(context)
            forwarded.retrigger_joker = nil
            forwarded.supereditions_poli_faker_replay = true
        end
        local result = pack(calculate_joker(self, forwarded, ...))
        if type(result[1]) == 'table' then
            if replay then
                result[1] = copy(result[1]); result[1].no_retrigger = true
            elseif polychrome(self) and owned(self) and not is_faker(self)
                and ordinary(context) and sources() > 0 and result[1].no_retrigger then
                result[1] = copy(result[1]); result[1].no_retrigger = nil
            end
        end
        return unpack(result, 1, result.n)
    end
end

-- Joker ability retriggers do not replay the separate edition-effect boundary.
-- Repeat owned Jokers' actual edition activation here, including Poli-faker's
-- own edition. Playing-card editions are already handled by native card repeats.
local calculate_effect = assert(SMODS.calculate_effect, 'Poli-faker requires Steamodded.calculate_effect.')
local replay_depth = 0
SMODS.calculate_effect = function(effect, scored_card, from_edition, ...)
    local count = 0
    if replay_depth == 0 and from_edition == true and type(effect) == 'table'
        and polychrome(scored_card) and owned(scored_card) then count = sources() end
    local args = pack(...)
    local result = pack(calculate_effect(effect, scored_card, from_edition, unpack(args, 1, args.n)))
    if count > 0 then
        replay_depth = replay_depth + 1
        local ok, err = pcall(function()
            for _ = 1, count do
                calculate_effect(effect, scored_card, from_edition, unpack(args, 1, args.n))
            end
        end)
        replay_depth = replay_depth - 1
        if not ok then error(err, 0) end
    end
    return unpack(result, 1, result.n)
end
