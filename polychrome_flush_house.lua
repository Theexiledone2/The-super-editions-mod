-- Read the framework's rank/suit parts, preserving Wild/Smeared and rank
-- modifiers. A four-card flush cannot substitute for five matching suits.
SMODS.PokerHand {
    key = 'polychrome_flush_house',
    chips = 300, mult = 20, l_chips = 50, l_mult = 5,
    above_hand = 'Flush Five', visible = false,
    example = {{'H_K', true}, {'H_K', true}, {'H_K', true}, {'H_7', true}, {'H_7', true}},
    loc_txt = {
        name = 'Polychrome Flush House',
        description = {
            'Three of one rank and two of another,',
            'all five sharing a suit and all Polychrome.',
        },
    },
    evaluate = function(parts, hand)
        if type(hand) ~= 'table' or #hand ~= 5 then return {} end
        local members = {}
        for _, card in ipairs(hand) do
            local edition = card.edition
            if members[card] or not edition
                or not (edition.polychrome == true or edition.key == 'e_polychrome') then return {} end
            members[card] = true
        end
        local function contained(group, size)
            if #group ~= size then return false end
            local seen = {}
            for _, card in ipairs(group) do
                if not members[card] or seen[card] then return false end
                seen[card] = true
            end
            return true
        end
        local flush = false
        for _, group in ipairs(parts._flush or {}) do
            if contained(group, 5) then flush = true; break end
        end
        if not flush then return {} end
        for _, three in ipairs(parts._3 or {}) do
            if contained(three, 3) then
                local triplet = {}; for _, card in ipairs(three) do triplet[card] = true end
                for _, pair in ipairs(parts._2 or {}) do
                    if contained(pair, 2) and not triplet[pair[1]] and not triplet[pair[2]] then
                        return {{hand[1], hand[2], hand[3], hand[4], hand[5]}}
                    end
                end
            end
        end
        return {}
    end,
}
