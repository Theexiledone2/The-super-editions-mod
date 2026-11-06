local mod = SMODS.current_mod
local ruggiero_key = 'j_supereditions_ruggiero'
local contents_seed = 'supereditions_negative_contents'

SMODS.Atlas {
    key = 'negative_pack_mega', path = 'negative-pack-mega.png',
    px = 1024, py = 1536, force_pixel = true, disable_mipmap = true,
}

local function ruggiero_available()
    if not (G and G.GAME and G.P_CENTERS and G.P_CENTERS[ruggiero_key]
        and G.STAGES and G.STAGE == G.STAGES.RUN and SMODS.cull_pool) then return false end
    -- Query the public eligibility API, preserving bans, Showman/duplicate
    -- rules and custom in_pool conditions without rolling another rarity.
    local pool = SMODS.cull_pool({ruggiero_key}, {
        types = {'Joker'}, allow_legendaries = true, append = contents_seed,
    })
    for _, key in ipairs(pool or {}) do
        if key == ruggiero_key then return true end
    end
    return false
end

SMODS.Booster {
    key = 'negative_mega', kind = 'supereditions_negative',
    atlas = 'negative_pack_mega', pos = {x = 0, y = 0},
    discovered = true, cost = 10, weight = 0.04,
    config = {extra = 6, choose = 3},
    draw_hand = false, select_card = {Joker = 'jokers'},
    in_pool = function() return mod.supereditions_pack_in_pool('negative') end,
    loc_txt = {
        name = 'Mega Negative Pack', group_name = 'Negative Pack',
        text = {
            'Choose {C:attention}#1#{} of up to',
            '{C:attention}#2#{} {C:dark_edition}Negative{} Jokers',
            '{C:attention}#3#%{} chance per offer for {C:legendary}Ruggiero{}',
            '{s:0.8}Ruggiero rolls his edition normally{}',
            '{s:0.8,C:inactive}(Other Jokers Negative; stickers take priority){}',
        },
    },
    loc_vars = function(self, info_queue, card)
        local upgraded = G and G.GAME and G.GAME.supereditions_ruggiero_packs
        if upgraded then info_queue[#info_queue + 1] = {key = 'tag_supereditions_ruggiero', set = 'Tag'} end
        local ability = card and card.ability or self.config
        return {vars = {ability.choose, ability.extra, 5}}
    end,
    create_card = function(self, pack, index)
        local args = {
            set = 'Joker', area = G.pack_cards, skip_materialize = true,
            soulable = false, no_edition = true, edition = 'e_negative',
            key_append = contents_seed, supereditions_mega_negative = true,
        }
        -- One seeded attempt per offer, including unavailable outcomes. A
        -- failed/ineligible special roll falls back to the ordinary Joker pool.
        if pseudorandom('supereditions_negative_ruggiero') < 0.05 and ruggiero_available() then
            args.key = ruggiero_key
            args.no_edition, args.edition = nil, nil
        end
        return args
    end,
}
