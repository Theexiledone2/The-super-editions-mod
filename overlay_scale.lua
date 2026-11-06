-- Shared overlays must use their own atlas density, not the card art's.
-- Keep the engine's draw order, conditions, dissolve and sticker selection.
if not (Sprite and type(Sprite.draw_shader) == 'function') then return end
local previous = Sprite.draw_shader
local function contains(t, sprite)
    for _, value in pairs(t or {}) do if value == sprite then return true end end
    return false
end
Sprite.draw_shader = function(self, shader, shadow, send, no_tilt, other, ...)
    local card = self.role and self.role.draw_major
    local center = card and card.children and card.children.center
    local key = card and card.config and card.config.center and card.config.center.key
    local ours = type(key) == 'string' and key:match('^%a_supereditions_')
    local seals = G and G.shared_seals
    local stickers = G and G.shared_stickers
    local custom_overlay = (seals and self == seals.supereditions_orange)
        or (stickers and (self == stickers.supereditions_negative
            or self == stickers.supereditions_polychrome))
    if other == center and center and center.T and center.VT
        and center.T.w > 0 and center.T.h > 0 and self.scale
        and self.scale.x > 0 and self.scale.y > 0
        and (custom_overlay or (ours and (contains(seals, self) or contains(stickers, self)))) then
        -- A proxy avoids changing either the shared overlay or the card, and
        -- preserves all animated position/rotation fields through inheritance.
        local frame = setmetatable({}, {__index = center})
        frame.T = {}; for k, v in pairs(center.T) do frame.T[k] = v end
        frame.scale_mag = self.scale.x / center.T.w
        frame.T.h = self.scale.y / frame.scale_mag
        other = frame
        -- Full-resolution overlays already follow the card transform. Applying
        -- the shader's native-pixel hover warp again can stretch them off-card.
        no_tilt = true
    end
    return previous(self, shader, shadow, send, no_tilt, other, ...)
end
