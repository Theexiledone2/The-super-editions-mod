-- Each PNG is one complete icon; preserve the original pixels and alpha.
for _, item in ipairs({
    {'negative_pack_tag', 'negative-pack-tag.png'},
    {'ruggiero_tag', 'ruggiero-tag.png'},
    {'foil_stake', 'foil-stake.png'},
    {'polychrome_stake', 'polychrome-stake.png'},
    {'holographic_stake', 'holographic-stake.png'},
    {'negative_stake', 'negative-stake.png'},
}) do
    SMODS.Atlas {
        key = item[1], path = item[2], px = 1254, py = 1254,
        force_pixel = true, disable_mipmap = true,
    }
end
