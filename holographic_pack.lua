local mod = SMODS.current_mod
local icon = G and G.P_TAGS and G.P_TAGS.tag_buffoon or {}
SMODS.Tag {
    key = 'holographic_pack',
    -- Native booster-tag icon is provisional until custom art is designed.
    atlas = icon.atlas or 'tags', pos = icon.pos or {x = 0, y = 0},
    prefix_config = {atlas = false},
    discovered = true, min_ante = 0, weight = 3,
    config = {type = 'new_blind_choice'},
    in_pool = function() return mod.supereditions_pack_in_pool('holographic') end,
    loc_txt = {
        name = 'Holographic Pack Tag',
        text = {'Gives a free', '{C:dark_edition}Mega Holographic Pack{}'},
    },
    get_weight = function(self, weight)
        local spectral = G and G.P_TAGS and G.P_TAGS.tag_ethereal
        if not spectral then return 3 end
        local value = spectral.weight or 3
        return spectral.get_weight and spectral:get_weight(value) or value
    end,
    apply = function(self, tag, context)
        if context.type ~= 'new_blind_choice' or tag.triggered then return end
        local run, locks = G.GAME, G.CONTROLLER.locks
        local old_lock, rewarded = locks[tag.ID], false
        tag.triggered, locks[tag.ID] = true, true
        local ok, err = pcall(tag.yep, tag, '+', G.C.PURPLE, function()
            if rewarded then return true end
            if G.GAME ~= run then locks[tag.ID] = old_lock; return true end
            local success, failure = pcall(function()
                local pack = SMODS.create_card {
                    set = 'Booster', area = G.play,
                    key = mod.supereditions_pack_reward_key('holographic', 'mega'),
                    skip_materialize = true, no_edition = true,
                }
                pack.ability.couponed = true
                pack:set_cost()
                pack.cost, pack.from_tag = 0, true
                G.FUNCS.use_card({config = {ref_table = pack}})
                rewarded = true
                pack:start_materialize()
            end)
            locks[tag.ID] = old_lock
            if not success then error(failure, 0) end
            return true
        end)
        if not ok then
            locks[tag.ID] = old_lock
            if not rewarded then tag.triggered = false end
            error(err, 0)
        end
        return true
    end,
}
