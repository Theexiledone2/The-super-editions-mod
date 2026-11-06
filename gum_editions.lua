-- Install before deck edition coercion: even a forced deck/pack request must
-- cross this gate on its way to the ordinary setter and slot bookkeeping.
local function gum(card)
    return card and card.config and card.config.center
        and card.config.center.key == 'j_supereditions_gum'
end
local function packed(...) return {n = select('#', ...), ...} end
if Card and Card.set_edition then
    local previous = Card.set_edition
    Card.set_edition = function(self, edition, ...)
        if gum(self) then edition = nil end
        return previous(self, edition, ...)
    end
end
local function clear(card)
    if gum(card) and card.edition then card:set_edition(nil, true, true) end
end
for _, name in ipairs({'set_ability', 'load'}) do
    if Card and Card[name] then
        local previous = Card[name]
        Card[name] = function(self, ...)
            local result = packed(previous(self, ...))
            clear(self)
            return unpack(result, 1, result.n)
        end
    end
end
if SMODS.create_card then
    local previous = SMODS.create_card
    SMODS.create_card = function(...)
        local result = packed(previous(...)); clear(result[1])
        return unpack(result, 1, result.n)
    end
end
