local pack_mod = SMODS.current_mod
SMODS.Atlas {
    key = 'polychrome_pack_mega',
    path = 'polychrome-pack-mega.png',
    px = 1086,
    py = 1448,
    force_pixel = true,
    disable_mipmap = true,
}

SMODS.Booster {
    key = 'polychrome_mega',
    kind = 'supereditions_polychrome',
    atlas = 'polychrome_pack_mega',
    pos = {x = 0, y = 0},
    discovered = true,
    cost = 8,
    -- Retain the requested Spectral-matched Mega category weight.
    weight = 0.07,
    config = {extra = 5, choose = 2},
    draw_hand = false,
    select_card = {Joker = 'jokers'},
    in_pool = function() return pack_mod.supereditions_pack_in_pool('polychrome') end,
    loc_txt = {
        name = 'Mega Polychrome Pack',
        group_name = 'Mega Polychrome Pack',
        text = {
            'Choose {C:attention}#1#{} of up to',
            '{C:attention}#2#{} {C:dark_edition}Polychrome{} Jokers',
        },
    },
    create_card = function(self, pack, index)
        return {
            set = 'Joker',
            area = G.pack_cards,
            skip_materialize = true,
            soulable = false,
            no_edition = true,
            edition = 'e_polychrome',
            key_append = 'supereditions_polychrome_contents',
        }
    end,
}
