-- Run an ability-only context before the first Joker evaluation, so priority
-- does not depend on Ruggiero's position and never rearranges the Joker row.
local joker_key = 'j_supereditions_ruggiero'
local max_number = 1.7976931348623157e308
local square_limit = math.sqrt(max_number)
local fifth_limit = max_number ^ (1 / 5)
local phase
local function pack(...) return {n = select('#', ...), ...} end

local function poly(card)
    return card and card.edition
        and (card.edition.polychrome == true or card.edition.key == 'e_polychrome')
end
local function owned(card)
    for _, candidate in ipairs(G and G.jokers and G.jokers.cards or {}) do
        if candidate == card then return true end
    end
    return false
end
local function active(card)
    return card and card.config and card.config.center
        and card.config.center.key == joker_key and poly(card)
        and not card.debuff and not card.getting_sliced
        and not (card.ability and card.ability.supereditions_polychrome)
        and owned(card)
end
local function qualifying(context)
    if context.scoring_name ~= 'supereditions_polychrome_flush_house' then return false end
    local full, scored = context.full_hand, context.scoring_hand
    if type(full) ~= 'table' or type(scored) ~= 'table'
        or #full ~= 5 or #scored ~= 5 then return false end
    local seen = {}
    for _, card in ipairs(full) do
        if seen[card] or card.debuff or not poly(card) then return false end
        seen[card] = true
    end
    for _, card in ipairs(scored) do
        if not seen[card] then return false end
        seen[card] = nil
    end
    return true
end
local function ordinary(context)
    return context and not context.blueprint and not context.retrigger_joker
        and not context.retrigger_joker_check and not context.repetition
        and not context.repetition_only and not context.individual
        and not context.post_trigger and not context.supereditions_poli_faker_replay
end

local mod = SMODS.current_mod
mod.supereditions_ruggiero_polychrome_effect = function(card, context)
    if not phase or context.supereditions_ruggiero_phase ~= phase
        or not phase.dispatched or phase.game ~= (G and G.GAME) or not active(card) then return end
    local this_phase = phase
    local used = false
    return {
        -- Resolve the current Mult when the effect actually runs, not when
        -- queued. Multiple copies/retriggers therefore power successively.
        func = function()
            if used then return end
            used = true
            if phase ~= this_phase or this_phase.game ~= (G and G.GAME) or not active(card) then return end
            local current = SMODS.get_scoring_parameter('mult')
            local numbers = mod.supereditions_numbers
            local extended = numbers and numbers.active and numbers.active()
            -- This release uses native Lua numbers, as the existing scoring
            -- features do. Never replace invalid/non-native values with zero.
            if not (type(current) == 'number' or extended and numbers.is(current)) or current ~= current or current < 0
                or current == math.huge then return end
            -- Count owned cards, including Negative/debuffed Jokers, rather
            -- than available slots. Read at execution in case the row changed.
            local fifth = #G.jokers.cards < 5
            local powered
            if extended then
                powered = numbers.pow(current, fifth and 5 or 2)
            elseif fifth then
                powered = current >= fifth_limit and max_number or current ^ 5
            else
                powered = current >= square_limit and max_number or current * current
            end
            if not extended then powered = math.min(max_number, powered) end
            SMODS.calculate_effect({
                mult = powered - current,
                message = localize(fifth and 'k_supereditions_ruggiero_fifth' or 'k_supereditions_ruggiero_square'),
                colour = G.C.MULT, remove_default_message = true,
                no_retrigger = true,
            }, card)
        end,
        no_retrigger = true,
    }
end

local calculate = mod.calculate
mod.calculate = function(self, context)
    local result = calculate and pack(calculate(self, context)) or {n = 0}
    if ordinary(context) then
        if context.before then
            phase = {game = G and G.GAME, dispatched = false}
        elseif context.after or context.debuffed_hand or context.end_of_round or context.ending_shop then
            phase = nil
        end
    end
    return unpack(result, 1, result.n)
end

local evaluate = assert(eval_card, 'Ruggiero priority requires the card evaluation boundary.')
eval_card = function(card, context, ...)
    if phase and not phase.dispatched and phase.game == (G and G.GAME)
        and ordinary(context) and (context.pre_joker or context.joker_main)
        and G and G.jokers and context.cardarea == G.jokers and owned(card) then
        -- Latch before dispatch so nested evaluations and later Joker slots
        -- cannot repeat this phase. Even an ineligible hand consumes the slot.
        phase.dispatched = true
        if qualifying(context) then
            local has_source = false
            for _, candidate in ipairs(G.jokers.cards) do
                if active(candidate) then has_source = true; break end
            end
            if has_source then
                -- Only Ruggiero responds to this new context. Let the native
                -- dispatcher handle genuine Joker retriggers (including
                -- Poli-faker) here, before any ordinary Joker/edition effects.
                SMODS.calculate_context({
                    supereditions_ruggiero_polychrome = true,
                    supereditions_ruggiero_phase = phase,
                    cardarea = G.jokers,
                    full_hand = context.full_hand, scoring_hand = context.scoring_hand,
                    scoring_name = context.scoring_name, poker_hands = context.poker_hands,
                })
            end
        end
    end
    return evaluate(card, context, ...)
end
