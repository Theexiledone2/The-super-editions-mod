-- A small native UI child keeps the countdown visible without adding any
-- ability-description text. The counter is live UI, not baked into the art.
local child_key = 'supereditions_infinity_counter'
if SMODS.DrawStep then
    SMODS.DrawStep {
        key = 'infinity_counter', order = 91,
        conditions = {vortex = false, facing = 'front'},
        func = function(card)
            local children = card.children
            if not children then return end
            local center = card.config and card.config.center
            local existing = children[child_key]
            if not center or center.key ~= 'j_supereditions_infinity' then
                if existing then existing:remove(); children[child_key] = nil end
                return
            end
            if not (UIBox and G and G.UIT and card.T and card.ability and card.ability.extra)
                or (type(card.dissolve) == 'number' and card.dissolve > 0)
                or (not center.discovered and not card.bypass_discovery_center) then return end
            local value = tostring(card.ability.extra.remaining)
            local height = card.T.h
            if existing and (existing.supereditions_value ~= value or existing.supereditions_height ~= height) then
                existing:remove(); children[child_key], existing = nil, nil
            end
            if not existing then
                existing = UIBox {
                    definition = {
                        n = G.UIT.ROOT, config = {align = 'cm', padding = 0, colour = {0, 0, 0, 0}},
                        nodes = {{n = G.UIT.T, config = {
                            text = value, scale = 0.4, colour = {1, 0.82, 0.25, 1}, shadow = true,
                        }}},
                    },
                    config = {align = 'cm', offset = {x = 0, y = height * 0.33}, major = card, parent = card},
                }
                existing.custom_draw = true
                existing.supereditions_value, existing.supereditions_height = value, height
                if existing.states and existing.states.collide then existing.states.collide.can = false end
                children[child_key] = existing
            end
            existing:draw()
        end,
    }
end
