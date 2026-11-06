-- Visual preparation only. The future Legendary must use this exact center key.
-- No Joker, ability, spawn weight or edition is registered by this module.
local ruggiero_key = 'j_supereditions_ruggiero'
local art = {
    base = 'ruggiero',
    foil = 'ruggiero_foil',
    holo = 'ruggiero_holo',
    polychrome = 'ruggiero_polychrome',
}
for _, item in ipairs({
    {art.base, 'ruggiero.png'},
    {art.foil, 'ruggiero-foil.png'},
    {art.holo, 'ruggiero-holo.png'},
    {art.polychrome, 'ruggiero-polychrome.png'},
}) do
    SMODS.Atlas {
        key = item[1], path = item[2], px = 1085, py = 1450,
        force_pixel = true, disable_mipmap = true,
    }
end

local function is_ruggiero(card)
    return card and card.config and card.config.center
        and card.config.center.key == ruggiero_key
end

local edition_shaders = {
    foil = true, holo = true, polychrome = true,
    negative = true, negative_shine = true,
}

local function is_edition_shader(card, shader)
    if edition_shaders[shader] then return true end
    -- Also respect an edition's registered shader, including prefixed keys.
    -- This does not intercept arbitrary custom graphics drawn outside sprites.
    local edition = card.edition
    local definition = edition and edition.key and G and G.P_CENTERS
        and G.P_CENTERS[edition.key]
    return definition and type(definition.shader) == 'string'
        and definition.shader == shader
end

local function guard_sprite(card, slot)
    local sprite = card.children[slot]
    if not sprite or type(sprite.draw_shader) ~= 'function' then return end
    local state = sprite.supereditions_ruggiero_guard
    if state and state.card == card and state.wrapper == sprite.draw_shader then return end
    local previous = sprite.draw_shader
    local wrapper = function(self, shader, ...)
        if is_ruggiero(card) and card.children and card.children[slot] == self
            and is_edition_shader(card, shader) then
            return
        end
        -- Preserve dissolve/materialization, debuff, shadow and other effects,
        -- plus any earlier sprite hook. Never clear or replace card.edition.
        return previous(self, shader, ...)
    end
    sprite.draw_shader = wrapper
    sprite.supereditions_ruggiero_guard = {card = card, wrapper = wrapper}
end

local function select_art(card)
    local edition = card.edition or {}
    local name = art.base
    if edition.negative or edition.key == 'e_negative' then
        -- No separate Negative artwork was requested; retain the approved base.
        name = art.base
    elseif edition.polychrome or edition.key == 'e_polychrome' then
        name = art.polychrome
    elseif edition.holo or edition.key == 'e_holo' then
        name = art.holo
    elseif edition.foil or edition.key == 'e_foil' then
        name = art.foil
    end
    local sprite = card.children.center
    local atlas = G and G.ASSET_ATLAS and G.ASSET_ATLAS['supereditions_' .. name]
    if sprite and atlas and sprite.atlas ~= atlas then
        sprite.atlas = atlas
        sprite:set_sprite_pos({x = 0, y = 0})
    end
end

-- Chain the existing renderer; do not replace its drawing sequence or mutate
-- the global Sprite class. Bind only this Joker's own artwork sprites before
-- the renderer uses them, including newly created/loaded/replaced sprites.
local previous_draw = assert(Card.draw, 'Ruggiero visual support requires Card.draw.')
Card.draw = function(self, ...)
    if is_ruggiero(self) and self.children then
        select_art(self)
        guard_sprite(self, 'center')
        guard_sprite(self, 'front')
        guard_sprite(self, 'floating_sprite')
    end
    return previous_draw(self, ...)
end
