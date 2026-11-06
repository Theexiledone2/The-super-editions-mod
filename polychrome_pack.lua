local pack_mod = SMODS.current_mod
SMODS.Atlas {
    key = 'polychrome_pack_tag', path = 'polychrome-pack-tag.png',
    px = 1254, py = 1254, force_pixel = true, disable_mipmap = true,
}

local pack_key = 'p_supereditions_polychrome_mega'

SMODS.Tag {
    key = 'polychrome_pack',
    atlas = 'polychrome_pack_tag', pos = {x = 0, y = 0},
    discovered = true, min_ante = 0, weight = 10,
    config = {type = 'new_blind_choice'},
    in_pool = function() return pack_mod.supereditions_pack_in_pool('polychrome') end,
    loc_txt = {
        name = 'Polychrome Pack Tag',
        text = {'Gives a free', '{C:dark_edition}Mega Polychrome Pack{}'},
    },
    get_weight = function(self, weight)
        -- Ethereal Tag is vanilla's Spectral-pack tag. This is a tag weight,
        -- separate from the much smaller Mega Spectral booster weight.
        local spectral = G and G.P_TAGS and G.P_TAGS.tag_ethereal
        if not spectral then return 10 end
        local value = spectral.weight or 10
        if spectral.get_weight then value = spectral:get_weight(value) end
        return value
    end,
    apply = function(self, tag, context)
        if context.type ~= 'new_blind_choice' or tag.triggered then return end
        local locks = G.CONTROLLER.locks
        local previous_lock = locks[tag.ID]
        local rewarded = false
        tag.triggered, locks[tag.ID] = true, true
        local function reward()
            if rewarded then return true end
            local ok, err = pcall(function()
                local pack = SMODS.create_card {
                    set = 'Booster', key = pack_mod and pack_mod.supereditions_pack_reward_key
                        and pack_mod.supereditions_pack_reward_key('polychrome', 'mega') or pack_key, area = G.play,
                    skip_materialize = true, no_edition = true,
                }
                pack.ability.couponed = true
                pack:set_cost()
                pack.cost, pack.from_tag = 0, true
                G.FUNCS.use_card({config = {ref_table = pack}})
                rewarded = true
                pack:start_materialize()
            end)
            locks[tag.ID] = previous_lock
            if not ok then error(err, 0) end
            return true
        end
        local ok, err = pcall(tag.yep, tag, '+', G.C.PURPLE, reward)
        if not ok then
            locks[tag.ID], tag.triggered = previous_lock, false
            error(err, 0)
        end
        return true
    end,
}
