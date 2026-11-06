local mod = SMODS.current_mod

SMODS.PokerHand {
    key = 'two_triplets', above_hand = 'Four of a Kind', visible = false,
    chips = 100, mult = 10, l_chips = 40, l_mult = 4,
    example = {{'S_K', true}, {'H_K', true}, {'C_K', true}, {'S_7', true}, {'H_7', true}, {'D_7', true}},
    loc_txt = {
        name = 'Two Triplets',
        description = {'Three cards of one rank and three of another.', 'All six matching cards score.'},
    },
    evaluate = function(parts, hand) return mod.supereditions_two_triplets(parts, hand) end,
}

SMODS.PokerHand {
    key = 'flush_six', above_hand = 'Flush Five', visible = false,
    chips = 180, mult = 18, l_chips = 55, l_mult = 4,
    example = {{'H_7', true}, {'H_7', true}, {'H_7', true}, {'H_7', true}, {'H_7', true}, {'H_7', true}},
    loc_txt = {
        name = 'Flush 6',
        description = {'Six cards sharing both rank and suit.', 'All six matching cards score.'},
    },
    evaluate = function(parts, hand) return mod.supereditions_flush_six(parts, hand) end,
}
