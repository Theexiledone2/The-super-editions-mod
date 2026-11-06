local mod = SMODS.current_mod
SMODS.Atlas {
    key = 'sparta', path = 'sparta.png', px = 1024, py = 1536,
    force_pixel = true, disable_mipmap = true,
}
SMODS.Joker {
    key = 'sparta', rarity = 3, cost = 10, unlocked = true, discovered = true,
    atlas = 'sparta', pos = {x = 0, y = 0},
    blueprint_compat = false, eternal_compat = true, perishable_compat = true,
    config = {},
    loc_txt = {name = 'Sparta!!!!!!!', text = {
        'At {C:attention}30%{} Boss Blind progress,',
        '{C:attention}left-click{} to add {C:chips}50%{}',
        'of its target to your round score',
        '{C:attention}Cannot complete{} the Blind',
        '{s:0.8,C:inactive}(Reusable while choosing cards to play){}',
    }},
    update = function(self, card, dt) mod.supereditions_sparta_update(card) end,
}
