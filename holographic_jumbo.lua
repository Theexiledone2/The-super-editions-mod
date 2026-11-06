local mod = SMODS.current_mod
SMODS.Atlas {
    key = 'holographic_pack_jumbo', path = 'holographic-pack-jumbo.png',
    px = 1086, py = 1448, force_pixel = true, disable_mipmap = true,
}

SMODS.Booster {
    key = 'holographic_jumbo', kind = 'supereditions_holographic',
    atlas = 'holographic_pack_jumbo', pos = {x = 0, y = 0},
    discovered = true, cost = 6, weight = 0.3,
    config = {extra = 5, choose = 1},
    draw_hand = false, select_card = {Joker = 'jokers'},
    in_pool = function() return mod.supereditions_pack_in_pool('holographic') end,
    loc_txt = {
        name = 'Jumbo Holographic Pack', group_name = 'Holographic Pack',
        text = {
            'Choose {C:attention}#1#{} of up to',
            '{C:attention}#2#{} {C:dark_edition}Holographic{} Jokers',
            '{s:0.8,C:inactive}(Edition-blocking stickers take priority){}',
        },
    },
    create_card = function(self, pack, index)
        return {
            set = 'Joker', area = G.pack_cards, skip_materialize = true,
            soulable = false, no_edition = true, edition = 'e_holo',
            key_append = 'supereditions_holographic_contents',
        }
    end,
}
