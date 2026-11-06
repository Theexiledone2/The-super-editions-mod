local mod = SMODS.current_mod
local function joker(card)
    return card and card.ability and card.ability.set == 'Joker' and not card.playing_card
end
SMODS.Sticker {
    key = 'negative', atlas = 'stickers', pos = {x = 0, y = 0},
    prefix_config = {atlas = false},
    default_compat = true, sets = {Joker = true},
    rate = 0.10, needs_enable_flag = true,
    config = {extra_slots_used = 1},
    badge_colour = {0.18, 0.18, 0.23, 1},
    -- The native sticker icon is provisional; name/effect are custom.
    loc_txt = {name = 'Negative Sticker', label = 'Negative Sticker', text = {
        'Uses {C:attention}1 extra{} Joker slot',
        '{C:inactive}(Normally uses 2 slots){}',
        'Slot-saving effects still apply',
    }},
    should_apply = function(self, card, center, area, bypass_roll)
        if not (G and ((G.shop_jokers and area == G.shop_jokers)
            or (G.pack_cards and area == G.pack_cards))) then return false end
        return SMODS.Sticker.should_apply(self, card, center, area, bypass_roll)
    end,
    apply = function(self, card, val)
        if not joker(card) then return end
        -- Native config storage persists with Card.save/load and copy_card.
        -- Guard reapplication: the base API would add its slot cost again.
        if (not not card.ability[self.key]) ~= (not not val) then
            SMODS.Sticker.apply(self, card, val)
        end
        if mod.supereditions_reconcile_negative_ruggiero then
            mod.supereditions_reconcile_negative_ruggiero()
        end
        if card.area and card.area.handle_card_limit then card.area:handle_card_limit() end
    end,
}
