local sticker_key = 'supereditions_polychrome'
local function joker(card)
    return card and ((card.config and card.config.center and card.config.center.set == 'Joker')
        or (card.ability and card.ability.set == 'Joker'))
end
local function blocked(card)
    return joker(card) and card.ability and card.ability[sticker_key]
end
local function edition_request(edition)
    if type(edition) == 'table' then
        for _, value in pairs(edition) do if value then return true end end
        return false
    end
    return edition ~= nil and edition ~= false and edition ~= ''
end

SMODS.Atlas {
    key = 'polychrome_sticker', path = 'polychrome-sticker.png',
    px = 1084, py = 1451, force_pixel = true, disable_mipmap = true,
}

SMODS.Sticker {
    key = 'polychrome',
    atlas = 'polychrome_sticker', pos = {x = 0, y = 0},
    default_compat = true, sets = {Joker = true},
    rate = 0.25, needs_enable_flag = true,
    badge_colour = {0.72, 0.36, 0.87, 1},
    draw = function(self, card)
        local sprite = G.shared_stickers and G.shared_stickers[self.key]
        local center = card.children and card.children.center
        if not (sprite and center and center.T and center.VT and sprite.scale) then return end
        -- Native sticker drawing borrows the Joker's pixel density (usually
        -- 71x95). This full-resolution atlas needs its own density, while
        -- following the same position, rotation and animated card dimensions.
        local frame = setmetatable({}, {__index = center})
        frame.T = {}; for k, v in pairs(center.T) do frame.T[k] = v end
        frame.scale_mag = sprite.scale.x / center.T.w
        frame.T.h = sprite.scale.y / frame.scale_mag
        sprite.role.draw_major = card
        -- Keep dissolve/materialization; skip the extra shine/hover warp on
        -- the already-coloured sticker. Do not mutate the Joker's transform.
        sprite:draw_shader('dissolve', nil, nil, true, frame)
    end,
    loc_txt = {
        name = 'Polychrome Sticker', label = 'Polychrome Sticker',
        text = {
            'Removes this Joker\'s {C:dark_edition}edition{}',
            'This Joker {C:attention}cannot gain an edition{}',
            'Edition attempts display {C:purple}Nope!{}',
        },
    },
    should_apply = function(self, card, center, area, bypass_roll)
        if not (G and ((G.shop_jokers and area == G.shop_jokers)
            or (G.pack_cards and area == G.pack_cards))) then return false end
        return SMODS.Sticker.should_apply(self, card, center, area, bypass_roll)
    end,
    apply = function(self, card, val)
        SMODS.Sticker.apply(self, card, val)
        if val and joker(card) and card.edition then
            -- Use the engine's setter for costs, shader cleanup and Negative
            -- capacity accounting. Never clear the edition table directly.
            card:set_edition(nil, true, true)
        end
    end,
}

-- Block at the shared edition boundary, including forced/silent applications
-- and all vanilla or modded editions. Removing an edition remains permitted.
-- Conditional installation allows the older registration-only test fixtures;
-- Card.set_edition is present when the real game loads a mod.
if Card and type(Card.set_edition) == 'function' then
    local set_edition = Card.set_edition
    Card.set_edition = function(self, edition, ...)
        if blocked(self) and edition_request(edition) then
            card_eval_status_text(self, 'extra', nil, nil, nil, {
                message = localize('k_nope_ex'), colour = G.C.PURPLE,
            })
            return
        end
        return set_edition(self, edition, ...)
    end
end
