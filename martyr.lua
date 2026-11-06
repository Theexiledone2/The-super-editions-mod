local mod = SMODS.current_mod
SMODS.Atlas {
    key = 'martyr', path = 'martyr.png', px = 1085, py = 1450,
    force_pixel = true, disable_mipmap = true,
}
SMODS.Joker {
    key = 'martyr', atlas = 'martyr', pos = {x = 0, y = 0},
    rarity = 'supereditions_epic', cost = 12, unlocked = true, discovered = true,
    blueprint_compat = false, eternal_compat = false, perishable_compat = true,
    config = {},
    loc_txt = {name = 'Martyr', text = {
        '{C:attention}Triple left-click{}, then click',
        'up to {C:attention}#1#{} other Joker(s) to link',
        'After a linked Joker is {C:money}sold{},',
        'sell this card to {C:attention}restore{} it',
        'Keeps its edition, stickers and upgrades',
        '{C:dark_edition}Negative{}: up to {C:attention}3{} links',
        '{C:inactive}(Linked: #2#; ready: #3#){}',
    }},
    loc_vars = function(self, info_queue, card)
        local maximum, linked, ready = mod.supereditions_martyr_status(card)
        return {vars = {maximum, linked, ready}}
    end,
    update = function(self, card, dt) mod.supereditions_martyr_update(card) end,
}
