-- Only cards explicitly marked by Shield summon tag are pinned to the right.
-- Do not set vanilla card.pinned: that property pins a card to the left.
-- Keep the mark/order in ability so it survives the game's normal card saves.
local function order(card)
    local value = card.ability and card.ability.supereditions_shield_summon_order
    return type(value) == 'number' and value or nil
end

local function pack(...) return {n = select('#', ...), ...} end
local align = assert(CardArea.align_cards)
CardArea.align_cards = function(self, ...)
    if not (G and self == G.jokers and self.cards) then return align(self, ...) end
    local found = false
    for _, card in ipairs(self.cards) do
        if order(card) then
            found = true
            if card.states and card.states.drag then card.states.drag.can = false end
        end
    end
    if not found then return align(self, ...) end

    -- Let the game handle dragging, ordinary pinned cards and layout first.
    local result = pack(align(self, ...))
    local regular, summoned, slots = {}, {}, {}
    for index, card in ipairs(self.cards) do
        if order(card) then
            if card.states and card.states.drag then card.states.drag.can = false end
            summoned[#summoned + 1] = {card = card, index = index, order = order(card)}
        else
            regular[#regular + 1] = card
        end
        -- Use native target positions; never replace the layout with our own.
        if card.T then slots[#slots + 1] = {x = card.T.x, y = card.T.y} end
    end
    table.sort(summoned, function(a, b)
        if a.order == b.order then return a.index < b.index end
        return a.order < b.order
    end)
    for _, entry in ipairs(summoned) do regular[#regular + 1] = entry.card end
    local changed = false
    for i, card in ipairs(regular) do
        if self.cards[i] ~= card then changed = true end
    end
    if changed then
        -- A drag/new Joker can move past the pinned group in the native array.
        -- Correct both scoring order and visible targets in the same callback.
        if #slots == #regular then
            table.sort(slots, function(a, b) return a.x < b.x end)
        end
        for i, card in ipairs(regular) do
            self.cards[i] = card
            card.rank = i
            if #slots == #regular then
                card.T.x, card.T.y = slots[i].x, slots[i].y
            end
        end
    end
    return unpack(result, 1, result.n)
end

-- Alignment above enforces the rightmost group and disables its drag state.
-- Some environments additionally expose start_drag; only wrap it when present.
-- Balatro 1.0.1o with Steamodded 26.927.0~dev-a has no Card.start_drag.
local start_drag = Card and Card.start_drag
if type(start_drag) == 'function' then
    Card.start_drag = function(self, ...)
        if G and self.area == G.jokers and order(self) then return end
        return start_drag(self, ...)
    end
end
