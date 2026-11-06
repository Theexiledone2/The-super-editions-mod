SMODS.Atlas {
    key = 'gum', path = 'gum.png', px = 1084, py = 1451,
    force_pixel = true, disable_mipmap = true,
}
SMODS.Joker {
    key = 'gum', atlas = 'gum', pos = {x = 0, y = 0},
    rarity = 3, cost = 8, unlocked = true, discovered = true,
    blueprint_compat = false, eternal_compat = false, perishable_compat = false,
    loc_txt = {
        name = 'Gum',
        text = {
            'At shop exit, stick to the {C:attention}left Joker{}',
            'and give it {C:attention}+1 permanent retrigger{}',
            'Follows immediately to its {C:attention}right{}',
            'Disappears after {C:attention}5 played rounds{}',
            '{C:inactive}(#1#){}',
            '{C:inactive}(Leftmost or Blueprint: random Joker){}',
            '{C:inactive}(Cannot have an edition){}',
        },
    },
    loc_vars = function(self, info_queue, card)
        local b = card.ability and card.ability.supereditions_gum_bond
        return {vars = {b and (tostring(b.remaining) .. ' rounds remaining') or 'Waiting for shop exit'}}
    end,
}
