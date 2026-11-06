local key = 'tag_supereditions_triple'
local copying = 0

local function copy(value, seen)
    if type(value) ~= 'table' then return value end
    seen = seen or {}
    if seen[value] then return seen[value] end
    local result = {}; seen[value] = result
    for k, v in pairs(value) do result[copy(k, seen)] = copy(v, seen) end
    return result
end

-- Double and Triple Tags wait for a reward tag. In particular, collecting
-- Triple must not spend an existing Double Tag or start a copying cascade.
if Tag and type(Tag.apply_to_run) == 'function' then
    local previous = Tag.apply_to_run
    function Tag:apply_to_run(context, ...)
        if self.key == 'tag_double' and context and context.type == 'tag_add'
            and (copying > 0 or (context.tag and context.tag.key == key)) then return end
        return previous(self, context, ...)
    end
end

SMODS.Atlas {
    key = 'triple_tag', path = 'triple-tag.png', px = 1254, py = 1254,
    force_pixel = true, disable_mipmap = true,
}

SMODS.Tag {
    key = 'triple', atlas = 'triple_tag', pos = {x = 0, y = 0},
    discovered = true, min_ante = 0, weight = 10,
    config = {type = 'tag_add'},
    loc_txt = {
        name = 'Triple Tag',
        text = {
            'Gives {C:attention}2{} copies of the',
            'next selected {C:attention}Tag{}',
            '{s:0.8,C:inactive}(Excludes Double and Triple Tags){}',
        },
    },
    apply = function(self, tag, context)
        local target = context.tag
        if context.type ~= 'tag_add' or tag.triggered or copying > 0 or not target
            or not target.key or target.key == key or target.key == 'tag_double' then return end
        local run = G and G.GAME
        if not run then return end
        local target_key, ability, hand = target.key, copy(target.ability), target.orbital_hand
        local completed = 0
        -- Reserve before animation so each waiting copy only claims one reward.
        tag.triggered = true
        local ok, err = pcall(tag.yep, tag, '+2', G.C.GREEN, function()
            if G.GAME ~= run then return true end
            copying = copying + 1
            local copied, failure = pcall(function()
                while completed < 2 do
                    local duplicate = Tag(target_key, nil, ability and ability.blind_type)
                    if ability then duplicate.ability = copy(ability) end
                    duplicate.orbital_hand = hand
                    add_tag(duplicate)
                    completed = completed + 1
                end
            end)
            copying = copying - 1
            if not copied then error(failure, 0) end
            return true
        end)
        if not ok then
            -- Keep a partially delivered reward consumed rather than grant it twice.
            if completed == 0 then tag.triggered = false end
            error(err, 0)
        end
        return true
    end,
}
