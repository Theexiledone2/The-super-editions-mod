local mod = SMODS.current_mod
local joker_key = 'j_supereditions_ruggiero'
local max_score = 1.7976931348623157e308
local function pack(...) return {n = select('#', ...), ...} end

local function is_ruggiero(card)
    return card and card.config and card.config.center
        and card.config.center.key == joker_key
end

local function mode(card)
    local edition = card.edition
    if not edition or next(edition) == nil then return 'base' end
    if edition.foil == true or edition.key == 'e_foil' then return 'foil' end
    if edition.polychrome == true or edition.key == 'e_polychrome' then return 'polychrome' end
    if edition.holo == true or edition.key == 'e_holo' then return 'holo' end
    if edition.negative == true or edition.key == 'e_negative' then return 'negative' end
    return 'other'
end

local function multiplier(card)
    local extra = card.ability.extra
    return 1 + math.floor(extra.score / extra.threshold) * extra.gain
end

local function copy_allowed(card)
    local round = G and G.GAME and G.GAME.current_round
    local hands = round and round.hands_left
    return mode(card) == 'base' and not card.debuff
        and type(hands) == 'number' and hands >= 0 and hands < 20
end

SMODS.Joker {
    key = 'ruggiero',
    atlas = 'ruggiero',
    pos = {x = 0, y = 0},
    rarity = 4,
    cost = 20,
    unlocked = true,
    discovered = true,
    -- Enable the public copier dispatch; permission remains per card/context.
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    config = {extra = {score = 0, threshold = 100, gain = 1, foil_factor = 3, awaiting_score = false}},

    loc_vars = function(self, info_queue, card)
        local extra = card.ability.extra
        local current = mode(card)
        if current == 'foil' then
            return {key = joker_key .. '_foil', vars = {extra.foil_factor}}
        elseif current == 'polychrome' then
            return {key = joker_key .. '_polychrome'}
        elseif current == 'holo' then
            return {key = joker_key .. '_holo', vars = {10}}
        elseif current == 'negative' then
            local source = card.ability.supereditions_negative_source
            return {key = joker_key .. '_negative', vars = {source and source.remaining or 5}}
        elseif current == 'other' then
            return {key = joker_key .. '_other'}
        end
        return {vars = {extra.gain, extra.threshold, multiplier(card)}}
    end,

    calculate = function(self, card, context)
        if card.debuff or context.retrigger_joker then return end
        if context.blueprint then
            if context.no_blueprint or not copy_allowed(card) or not context.joker_main then return end
            local amount = multiplier(card)
            if amount > 1 then return {xmult = amount, no_retrigger = true} end
            return
        end
        if mode(card) == 'holo' and context.individual and context.cardarea == G.play
            and not context.repetition and not context.repetition_only and not context.end_of_round then
            local target = context.other_card
            local edition = target and not target.debuff and target.edition
            if edition and SMODS.is_playing_card(target)
                and (edition.holo == true or edition.key == 'e_holo') then
                return {xmult = 10, card = card}
            end
        end
        if mode(card) == 'polychrome' and context.supereditions_ruggiero_polychrome then
            return mod.supereditions_ruggiero_polychrome_effect(card, context)
        end
        if mode(card) == 'base' and context.joker_main then
            local amount = multiplier(card)
            if amount > 1 then return {xmult = amount, no_retrigger = true} end
        end
        -- Foil reacts at the actual edition-effect boundary below, including
        -- this Joker's own +Chips. It never runs the editionless XMult ability.
    end,
}

local function owned()
    return G and G.jokers and G.jokers.cards or {}
end

-- The engine's default Blueprint label only reads the shared center flag.
-- Resolve vanilla copying chains here so this card's live condition is shown
-- without changing compatibility for another Ruggiero in a different mode.
local function copied_ruggiero(copier)
    local cards, seen = owned(), {}
    local current = copier
    while current and not seen[current] do
        seen[current] = true
        if is_ruggiero(current) then return current end
        local key = current.config and current.config.center and current.config.center.key
        if key == 'j_blueprint' then
            local next_card
            for i, candidate in ipairs(cards) do
                if candidate == current then next_card = cards[i + 1]; break end
            end
            current = next_card
        elseif key == 'j_brainstorm' then
            current = cards[1]
        else
            return
        end
    end
end

if G and G.FUNCS and G.FUNCS.blueprint_compat then
    local previous = G.FUNCS.blueprint_compat
    G.FUNCS.blueprint_compat = function(e, ...)
        local copier = e and e.config and e.config.ref_table
        local target = copied_ruggiero(copier)
        if target and copier and copier.ability then
            copier.ability.blueprint_compat = copy_allowed(target) and 'compatible' or 'incompatible'
        end
        return previous(e, ...)
    end
end

local previous_calculate = mod.calculate
mod.calculate = function(self, context)
    local result = previous_calculate and pack(previous_calculate(self, context)) or {n = 0}
    local game = G and G.GAME
    if not game or context.blueprint or context.retrigger_joker then
        return unpack(result, 1, result.n)
    end

    if context.ending_shop then
        -- Cleanup must reach debuffed copies and copies in another edition.
        for _, card in ipairs(owned()) do
            if is_ruggiero(card) then
                card.ability.extra.score = 0
                card.ability.extra.awaiting_score = false
            end
        end
        game.supereditions_ruggiero_scoring = false
        game.supereditions_ruggiero_foil_count = 0
    elseif context.before then
        game.supereditions_ruggiero_scoring = true
        game.supereditions_ruggiero_foil_count = 0
        for _, card in ipairs(owned()) do
            if is_ruggiero(card) then
                card.ability.extra.awaiting_score = not card.debuff and mode(card) == 'base'
            end
        end
    elseif context.after then
        -- Mod contexts follow Joker contexts, so our existing Foilmaker's
        -- completed-hand adjustment is included regardless of Joker position.
        local score = SMODS.last_hand_score
        local numbers = mod.supereditions_numbers
        local extended = numbers and numbers.active and numbers.active()
        local was_scoring = game.supereditions_ruggiero_scoring
        game.supereditions_ruggiero_scoring = false
        for _, card in ipairs(owned()) do
            if is_ruggiero(card) then
                local extra = card.ability.extra
                local eligible = was_scoring and extra.awaiting_score
                extra.awaiting_score = false
                if eligible and not card.debuff and mode(card) == 'base'
                    and (type(score) == 'number' or extended and numbers.is(score)) and score == score
                    and score > 0 and (extended or score < math.huge) then
                    -- Carry partial hundreds forward; never recount round totals.
                    extra.score = extended and numbers.add(extra.score, score)
                        or math.min(max_score, extra.score + score)
                end
            end
        end
    elseif context.debuffed_hand or context.end_of_round then
        game.supereditions_ruggiero_scoring = false
        for _, card in ipairs(owned()) do
            if is_ruggiero(card) then card.ability.extra.awaiting_score = false end
        end
    end
    return unpack(result, 1, result.n)
end

-- The documented effect helper identifies actual edition effects. Observing
-- it after the original call includes playing cards, Jokers and real repeats,
-- without mistaking another +Chips ability on a Foil card for a Foil activation.
local calculate_effect = assert(SMODS.calculate_effect, 'Ruggiero requires Steamodded.calculate_effect.')
SMODS.calculate_effect = function(effect, scored_card, from_edition, ...)
    local game = G and G.GAME
    local chips = type(effect) == 'table' and (effect.chips or effect.chip_mod)
    local activation = game and game.supereditions_ruggiero_scoring
        and from_edition == true and scored_card and not scored_card.debuff
        and mode(scored_card) == 'foil' and type(chips) == 'number' and chips > 0
    local result = pack(calculate_effect(effect, scored_card, from_edition, ...))
    if activation then
        game.supereditions_ruggiero_foil_count = (game.supereditions_ruggiero_foil_count or 0) + 1
        if game.supereditions_ruggiero_foil_count > 1 then
            for _, card in ipairs(owned()) do
                if is_ruggiero(card) and not card.debuff and mode(card) == 'foil' then
                    -- The engine applies the original +Chips first, then X3.
                    -- This is an ability effect, not another edition activation.
                    SMODS.calculate_effect({xchips = card.ability.extra.foil_factor,
                        no_retrigger = true}, card)
                end
            end
        end
    end
    return unpack(result, 1, result.n)
end
