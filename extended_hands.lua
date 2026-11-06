local mod = SMODS.current_mod
local function packed(...) return {n = select('#', ...), ...} end

local function membership(hand)
    local seen = {}
    for _, card in ipairs(hand or {}) do
        if seen[card] then return nil end
        seen[card] = true
    end
    return seen
end

local function valid(group, hand_members, minimum)
    if not hand_members or type(group) ~= 'table' or #group < minimum then return false end
    local seen = {}
    for _, card in ipairs(group) do
        if not hand_members[card] or seen[card] then return false end
        seen[card] = true
    end
    return true
end

local function ordered(hand, selected, limit)
    local result = {}
    for _, card in ipairs(hand) do
        if selected[card] then
            result[#result + 1] = card
            if limit and #result == limit then break end
        end
    end
    return result
end

local function groups(parts, hand, size)
    if get_X_same then return get_X_same(size, hand, true) or {} end
    -- Also permits registration-only/isolated callback fixtures. In game,
    -- the public rank helper includes other mods' rank behavior.
    return parts['_' .. size] or (size == 6 and parts._5) or {}
end

local function flushes(parts, hand, minimum)
    local result = {}
    local members = membership(hand)
    if not members then return result end
    if SMODS.Suit and SMODS.Suit.obj_buffer then
        -- Inspect every suit: native get_flush can return only the first
        -- matching suit, which is insufficient once a hand can be very large.
        for _, suit in ipairs(SMODS.Suit.obj_buffer) do
            local group = {}
            for _, card in ipairs(hand) do
                -- Flush identification differs from scoring a suit bonus:
                -- a debuffed normal card keeps its suit for hand identity.
                if card:is_suit(suit, nil, true) then group[#group + 1] = card end
            end
            if #group >= minimum then result[#result + 1] = group end
        end
    else
        for _, group in ipairs(parts._flush or {}) do
            if valid(group, members, minimum) then result[#result + 1] = group end
        end
    end
    return result
end

local function matching_rank_flush(parts, hand, size, cap)
    local result, members = {}, membership(hand)
    if not members then return result end
    for _, rank in ipairs(groups(parts, hand, size)) do
        if valid(rank, members, size) then
            local ranks = membership(rank)
            for _, suit in ipairs(flushes(parts, hand, size)) do
                local selected = {}
                for _, card in ipairs(suit) do if ranks[card] then selected[card] = true end end
                local match = ordered(hand, selected, cap)
                if #match >= size then result[#result + 1] = match end
            end
        end
    end
    return result
end

local function two_groups(parts, hand, left_size, right_size)
    local result, members = {}, membership(hand)
    if not members then return result end
    local left, right = groups(parts, hand, left_size), groups(parts, hand, right_size)
    for _, a in ipairs(left) do
        if valid(a, members, left_size) then
            local a_members = membership(a)
            for _, b in ipairs(right) do
                if valid(b, members, right_size) then
                    local disjoint = true
                    for _, c in ipairs(b) do if a_members[c] then disjoint = false; break end end
                    if disjoint then
                        local chosen = {}
                        for _, c in ipairs(ordered(hand, a_members, left_size)) do chosen[c] = true end
                        for _, c in ipairs(ordered(hand, membership(b), right_size)) do chosen[c] = true end
                        result[#result + 1] = ordered(hand, chosen)
                    end
                end
            end
        end
    end
    return result
end

local function prefer_suit(hand, group, suit, count)
    local eligible, selected = membership(group), {}
    local remaining = count
    for _, matching in ipairs({true, false}) do
        for _, card in ipairs(hand) do
            if remaining > 0 and eligible[card] and (not not suit[card]) == matching then
                selected[card] = true
                remaining = remaining - 1
            end
        end
    end
    return selected
end

local function rank_compound(hand, first_size, second_size, flush_min)
    local matches = {}
    for _, suit in ipairs(flushes({}, hand, flush_min)) do
        local suit_members = membership(suit)
        for _, a in ipairs(groups({}, hand, first_size)) do
            local a_members = membership(a)
            local seconds = second_size and groups({}, hand, second_size) or {{}}
            for _, b in ipairs(seconds) do
                local disjoint = true
                for _, card in ipairs(b) do if a_members[card] then disjoint = false; break end end
                if disjoint then
                    local selected = prefer_suit(hand, a, suit_members, first_size)
                    for card in pairs(prefer_suit(hand, b, suit_members, second_size or 0)) do selected[card] = true end
                    local count = 0
                    for card in pairs(selected) do if suit_members[card] then count = count + 1 end end
                    if count >= flush_min then matches[#matches + 1] = ordered(hand, selected) end
                end
            end
        end
    end
    return matches
end

local function four_finger_witnesses(hand, suit, matches)
    local suit_members = membership(suit)
    for _, outsider in ipairs(hand) do
        if not suit_members[outsider] then
            local candidate = {}; for _, card in ipairs(suit) do candidate[#candidate + 1] = card end
            candidate[#candidate + 1] = outsider
            local found = get_straight(candidate, 4, SMODS.shortcut(), SMODS.wrap_around_straight()) or {}
            if found[1] then
                local straight = ordered(hand, membership(found[1]))
                -- Reduce to a four-card straight witness without enumerating
                -- every five-card subset of a potentially very large hand.
                local i = 1
                while #straight > 4 and i <= #straight do
                    local reduced = {}; for j, card in ipairs(straight) do if i ~= j then reduced[#reduced + 1] = card end end
                    local still = get_straight(reduced, 4, SMODS.shortcut(), SMODS.wrap_around_straight()) or {}
                    if still[1] then straight = ordered(hand, membership(still[1])) else i = i + 1 end
                end
                if #straight == 4 then
                    local selected, same_suit = membership(straight), 0
                    for _, card in ipairs(straight) do if suit_members[card] then same_suit = same_suit + 1 end end
                    for _, card in ipairs(suit) do
                        if same_suit < 4 and not selected[card] then selected[card] = true; same_suit = same_suit + 1 end
                    end
                    local witness = ordered(hand, selected)
                    if same_suit == 4 and #witness <= 5 then matches[#matches + 1] = witness end
                end
            end
        end
    end
end

mod.supereditions_two_triplets = function(parts, hand)
    if type(hand) ~= 'table' or #hand < 6 then return {} end
    return two_groups(parts, hand, 3, 3)
end
mod.supereditions_flush_six = function(parts, hand)
    if type(hand) ~= 'table' or #hand < 6 then return {} end
    return matching_rank_flush(parts, hand, 6, 6)
end

-- The framework already handles large rank groups, straights and flushes.
-- Its compound hands can merge unrelated rank/suit/straight groups when
-- more than five cards are played. Validate those compounds on shared cards.
-- The established one-to-five-card path and other mods' hand keys are intact.
if type(evaluate_poker_hand) == 'function' then
    local previous = evaluate_poker_hand
    evaluate_poker_hand = function(hand, ...)
        local result = packed(previous(hand, ...))
        if type(hand) ~= 'table' or #hand <= 5 or not membership(hand)
            or type(result[1]) ~= 'table' then return unpack(result, 1, result.n) end
        local hands = result[1]
        local parts = {}
        local flush_min = SMODS.four_fingers('flush')
        if hands['Flush Five'] then hands['Flush Five'] = rank_compound(hand, 5, nil, flush_min) end
        if hands['Flush House'] then hands['Flush House'] = rank_compound(hand, 3, 2, flush_min) end
        if hands['Straight Flush'] and get_straight then
            local matches = {}
            local straight_min = SMODS.four_fingers('straight')
            for _, suit in ipairs(flushes(parts, hand, flush_min)) do
                for _, straight in ipairs(get_straight(suit, straight_min, SMODS.shortcut(), SMODS.wrap_around_straight()) or {}) do
                    if valid(straight, membership(suit), math.max(flush_min, straight_min)) then
                        matches[#matches + 1] = ordered(hand, membership(straight))
                    end
                end
                -- Four Fingers permits a four-card flush and a four-card
                -- straight within the same five-card witness, even when the
                -- two sets are not identical. Preserve that existing rule.
                if straight_min == 4 and flush_min == 4 then four_finger_witnesses(hand, suit, matches) end
            end
            hands['Straight Flush'] = matches
        end
        hands.top = {}
        for _, name in ipairs(G.handlist or {}) do
            if hands[name] and next(hands[name]) then hands.top = hands[name]; break end
        end
        return unpack(result, 1, result.n)
    end
end
