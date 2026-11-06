local mod = SMODS.current_mod
SMODS.Tag {
    key = 'negative_pack', atlas = 'negative_pack_tag', pos = {x = 0, y = 0},
    discovered = true, min_ante = 0, weight = 5,
    config = {type = 'new_blind_choice'},
    in_pool = function() return mod.supereditions_pack_in_pool('negative') end,
    loc_txt = {name = 'Negative Pack Tag', text = {
        'Gives a free', '{C:dark_edition}Negative Pack{}',
    }},
    apply = function(self, tag, context)
        if context.type ~= 'new_blind_choice' or tag.triggered then return end
        local run, locks = G.GAME, G.CONTROLLER.locks
        local old_lock, rewarded = locks[tag.ID], false
        tag.triggered, locks[tag.ID] = true, true
        local ok, err = pcall(tag.yep, tag, '+', G.C.DARK_EDITION, function()
            if rewarded then return true end
            if G.GAME ~= run then locks[tag.ID] = old_lock; return true end
            local success, failure = pcall(function()
                local pack = SMODS.create_card {
                    set = 'Booster', area = G.play,
                    key = mod.supereditions_pack_reward_key('negative', 'normal'),
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
