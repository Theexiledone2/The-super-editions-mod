-- Combine the engine's rank/flush parts so Wild Cards and suit modifiers use
-- the same rules as vanilla hands. This does not replace any vanilla hand.
SMODS.PokerHand {
    key = 'flush_four',
    chips = 140,
    mult = 14,
    l_chips = 40,
    l_mult = 4,
    above_hand = 'Flush House',
    visible = false,
    example = {{'H_7', true}, {'H_7', true}, {'H_7', true}, {'H_7', true}},
    loc_txt = {
        name = 'Flush 4',
        description = {
            'Four cards with the same rank and suit.',
            'Requires an active Four Fingers.',
        },
    },
    evaluate = function(parts, hand)
        if #SMODS.find_card('j_four_fingers') == 0 then return {} end
        for _, ranked in ipairs(parts._4 or {}) do
            for _, flushed in ipairs(parts._flush or {}) do
                local flush_members, seen, matching = {}, {}, {}
                for _, card in ipairs(flushed) do flush_members[card] = true end
                for _, card in ipairs(ranked) do
                    if flush_members[card] and not seen[card] then
                        matching[#matching + 1] = card
                        seen[card] = true
                    end
                end
                -- Five matching cards remain Flush Five. A fifth unrelated
                -- card is allowed, but is not part of the four scoring cards.
                if #matching == 4 then return {matching} end
            end
        end
        return {}
    end,
}
