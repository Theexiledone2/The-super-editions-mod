local pack_mod = SMODS.current_mod
local pack_key = 'p_supereditions_foil_mega'

SMODS.Atlas {
    key = 'foil_pack_tag',
    path = 'foil-pack-tag.png',
    px = 1254,
    py = 1254,
    force_pixel = true,
    disable_mipmap = true,
}

SMODS.Tag {
    key = 'foil_pack',
    atlas = 'foil_pack_tag',
    pos = {x = 0, y = 0},
    discovered = true,
    min_ante = 0,
    -- Object weights are already enabled by the existing Foil Deck module.
    -- The normal default is 10; 5 gives half that relative selection weight.
    weight = 5,
    config = {type = 'new_blind_choice'},
    in_pool = function() return pack_mod.supereditions_pack_in_pool('foil') end,
    loc_txt = {
        name = 'Foil Pack Tag',
        text = {
            'Gives a free',
            '{C:dark_edition}Mega Foil Pack',
        },
    },
    apply = function(self, tag, context)
        -- SMODS does not filter contexts using config.type for custom tags.
        if context.type ~= 'new_blind_choice' or tag.triggered then return end
        local locks = G.CONTROLLER.locks
        local previous_lock = locks[tag.ID]
        tag.triggered = true
        locks[tag.ID] = true
        local function reward()
            local ok, err = pcall(function()
                local pack = SMODS.create_card {
                    set = 'Booster', key = pack_mod and pack_mod.supereditions_pack_reward_key
                        and pack_mod.supereditions_pack_reward_key('foil', 'mega') or pack_key, area = G.play,
                    skip_materialize = true, no_edition = true,
                }
                -- Keep the gift free if costs are recalculated or saved.
                pack.ability.couponed = true
                pack:set_cost()
                pack.cost = 0
                pack.from_tag = true
                G.FUNCS.use_card({config = {ref_table = pack}})
                pack:start_materialize()
            end)
            locks[tag.ID] = previous_lock
            if not ok then error(err, 0) end
            return true
        end
        local ok, err = pcall(tag.yep, tag, '+', G.C.PURPLE, reward)
        if not ok then
            locks[tag.ID] = previous_lock
            tag.triggered = false
            error(err, 0)
        end
        return true
    end,
}
