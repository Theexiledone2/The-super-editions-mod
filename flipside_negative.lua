local mod = SMODS.current_mod
local key = 'j_supereditions_flipside'
local function negative(card)
    return card and card.edition and (card.edition.negative or card.edition.key == 'e_negative')
end
local function live(card)
    return card and card.ability and not card.removed and not card.getting_sliced
        and SMODS.is_playing_card(card)
end
local function contains(area, card)
    for _, candidate in ipairs(area.cards or {}) do if candidate == card then return true end end
    return false
end
local busy = setmetatable({}, {__mode = 'k'})
mod.supereditions_flipside_negative_calculate = function(card, context)
    local area, game, source = G.play, G.GAME, context.other_card
    if busy[card] or not negative(card) or card.debuff or not live(source)
        or source.debuff or not area or not contains(area, source) then return end
    local targets, seen = {}, {}
    for _, target in ipairs(area.cards or {}) do
        if live(target) and not negative(target) and not seen[target] then
            targets[#targets + 1], seen[target] = target, true
        end
    end
    if #targets == 0 then return end
    busy[card] = true
    local ok, result = pcall(function()
        local e = card.ability.extra
        if not SMODS.pseudorandom_probability(card, 'supereditions_flipside',
            e.numerator, e.denominator, 'supereditions_flipside') then return end
        local function valid()
            return G.GAME == game and G.play == area and negative(card) and not card.debuff
                and not card.removed and not card.getting_sliced
                and live(source) and not source.debuff and contains(area, source)
        end
        local changed = false
        for _, target in ipairs(targets) do
            if not valid() then break end
            if live(target) and contains(area, target) and not negative(target) then
                target:set_edition('e_negative', true)
                if G.GAME == game and G.play == area and live(target)
                    and contains(area, target) and negative(target) then
                    mod.supereditions_flipside_bind(target)
                    changed = true
                end
            end
        end
        if changed then return {message = 'Negative!', colour = G.C.DARK_EDITION} end
    end)
    busy[card] = nil
    if not ok then error(result, 0) end
    return result
end

SMODS.Atlas {
    key = 'flipside_negative', path = 'flipside-negative.png', px = 1024, py = 1536,
    force_pixel = true, disable_mipmap = true,
}
local function is_flipside(card)
    return card and card.config and card.config.center and card.config.center.key == key
end
local function suppress(card, shader)
    if not negative(card) then return false end
    local def = G and G.P_CENTERS and G.P_CENTERS.e_negative
    return shader == 'negative' or shader == 'negative_shine'
        or (def and type(def.shader) == 'string' and shader == def.shader)
end
local function guard(card, slot)
    local sprite = card.children[slot]
    if not sprite or type(sprite.draw_shader) ~= 'function' then return end
    local state = sprite.supereditions_flipside_guard
    if state and state.card == card and state.wrapper == sprite.draw_shader then return end
    local previous = sprite.draw_shader
    local wrapper = function(self, shader, ...)
        if is_flipside(card) and card.children and card.children[slot] == self
            and suppress(card, shader) then return end
        return previous(self, shader, ...)
    end
    sprite.draw_shader = wrapper
    sprite.supereditions_flipside_guard = {card = card, wrapper = wrapper}
end
if Card and type(Card.draw) == 'function' then
    local previous = Card.draw
    Card.draw = function(self, ...)
        if is_flipside(self) and self.children then
            local name = negative(self) and 'supereditions_flipside_negative' or 'supereditions_flipside'
            local atlas = G and G.ASSET_ATLAS and G.ASSET_ATLAS[name]
            local sprite = self.children.center
            if sprite and atlas and sprite.atlas ~= atlas then
                sprite.atlas = atlas
                sprite:set_sprite_pos({x = 0, y = 0})
            end
            guard(self, 'center'); guard(self, 'front'); guard(self, 'floating_sprite')
        end
        return previous(self, ...)
    end
end
