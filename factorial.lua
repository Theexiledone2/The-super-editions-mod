-- Keep the owner after Steamodded clears current_mod at the end of loading.
local mod = SMODS.current_mod

local function rank_of(target)
    if type(target) ~= 'table' or type(target.get_id) ~= 'function'
        or (SMODS.has_no_rank and SMODS.has_no_rank(target)) then return end
    local rank = target:get_id()
    if type(rank) == 'number' and rank > 0 and rank < math.huge
        and rank == math.floor(rank) then return rank end
end

local function factorial(rank)
    local value = 1
    local numbers = mod.supereditions_numbers
    local extended = numbers and numbers.active and numbers.active()
    for n = 2, rank do
        value = extended and numbers.mul(value, n) or value * n
        -- Preserve natural native-number overflow instead of clamping. Once
        -- infinite, further factors cannot change the result or need a loop.
        if value == math.huge then return value end
    end
    return value
end

SMODS.Atlas {
    key = 'factorial', path = 'factorial.png', px = 1085, py = 1450,
    force_pixel = true, disable_mipmap = true,
}

SMODS.Joker {
    key = 'factorial', atlas = 'factorial', pos = {x = 0, y = 0},
    rarity = 'supereditions_epic', cost = 12, unlocked = true, discovered = true,
    blueprint_compat = true, eternal_compat = true, perishable_compat = true,
    loc_txt = {
        name = 'Factorial',
        text = {
            'If played hand contains a {C:attention}Straight{},',
            'multiply {C:mult}Mult{} by the {C:attention}factorial{}',
            'of its {C:attention}lowest card rank{}',
            '{C:inactive}(J = 11, Q = 12, K = 13){}',
            '{C:inactive}(Ace = 14 with King in Straight, else 1){}',
            '{C:inactive}(Example: 5! = 120){}',
        },
    },
    calculate = function(self, card, context)
        if card.debuff or not context.joker_main or context.debuffed_hand
            or context.individual or context.repetition or context.repetition_only
            or context.retrigger_joker_check or context.post_trigger then return end

        -- Use the engine's primary Straight group, not full_hand/scoring_hand:
        -- extra Investor kickers and always-scoring cards must not lower it.
        -- Native detection retains Four Fingers, Shortcut and Straight Flush.
        local groups = context.poker_hands and context.poker_hands['Straight']
        local straight = type(groups) == 'table' and groups[1]
        if type(straight) ~= 'table' then return end
        local ranks, has_king = {}, false
        for _, target in ipairs(straight) do
            local rank = rank_of(target)
            if rank then
                ranks[#ranks + 1] = rank
                if rank == 13 then has_king = true end
            end
        end
        local lowest
        for _, rank in ipairs(ranks) do
            if rank == 14 and not has_king then rank = 1 end
            if not lowest or rank < lowest then lowest = rank end
        end
        if lowest then return {xmult = factorial(lowest)} end
    end,
}
