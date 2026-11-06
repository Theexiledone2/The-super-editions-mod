-- Approved balance change: ordinary tags retain default weight 10,
-- Ethereal (Spectral pack) becomes 3, and Holographic Joker Tag uses 5.
-- The existing Polychrome Pack Tag follows Ethereal's current weight.
if type(SMODS.Tag) == 'table' and type(SMODS.Tag.take_ownership) == 'function' then
    SMODS.Tag:take_ownership('ethereal', {weight = 3}, true)
end
