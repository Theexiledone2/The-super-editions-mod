-- Foil Deck uses Steamodded's public weighted-pool and Blind APIs.
-- Saved selected-back configuration also works after loading a run.
local function active()
    local back = G and G.GAME and G.GAME.selected_back
    return back and back.effect and back.effect.config
        and back.effect.config.supereditions_foil_deck == true
end

local boosted = {
    e_foil = true,
    j_supereditions_shielding_jimbo = true,
    j_supereditions_foilmaker = true,
    j_supereditions_the_foil_family = true,
    p_supereditions_foil_normal = true,
    p_supereditions_foil_jumbo = true,
    p_supereditions_foil_mega = true,
}

local mod = SMODS.current_mod
mod.optional_features = mod.optional_features or {}
mod.optional_features.object_weights = true

SMODS.Atlas {key = 'foil_deck', path = 'foil-deck.png',
    px = 1084, py = 1451, force_pixel = true, disable_mipmap = true}

SMODS.Back {
    key = 'foil',
    unlocked = true,
    discovered = true,
    atlas = 'foil_deck',
    pos = {x = 0, y = 0},
    config = {supereditions_foil_deck = true, dollars = 1},
    loc_txt = {
        name = 'Foil Deck',
        text = {
            '{C:dark_edition}Foil{} cards, jokers, and packs',
            'are much more likely to appear.',
            'Blinds scale {C:attention}2 times{} faster',
            'and finisher boss blinds that',
            'appear every {C:attention}8{} antes',
            'now appear every {C:attention}4{} antes.',
            'Start with {C:money}$1{} extra',
        },
    },
    calculate = function(self, back, context)
        if not active() or not context.modify_weights or not context.pool then return end
        for _, entry in pairs(context.pool) do
            if boosted[entry.key] and type(entry.weight) == 'number' then
                entry.weight = entry.weight * 5
            end
        end
    end,
}

-- Advance twice as far along the existing curve, keeping Ante 1 unchanged.
-- Delegate the actual amount (including stake scaling) to the original API.
local blind_amount = assert(SMODS.get_blind_amount)
SMODS.get_blind_amount = function(ante, ...)
    if active() and type(ante) == 'number' and ante > 1 then
        ante = 1 + (ante - 1) * 2
    end
    return blind_amount(ante, ...)
end

-- Restrict the scheduling adjustment to the synchronous Boss selection call.
-- The original selector retains its seed, bans, forced selections, and history.
-- Never leave win_ante at 4: run victory must still be checked at the real target.
local vanilla_finishers = {
    'bl_final_acorn', 'bl_final_leaf', 'bl_final_vessel',
    'bl_final_heart', 'bl_final_bell',
}
local select_blind = assert(SMODS.get_new_blind)
local function packed(...) return {n = select('#', ...), ...} end
SMODS.get_new_blind = function(blind_type, ...)
    -- Steamodded's round reset and boss reroll paths pass lowercase 'boss'.
    if not active() or (blind_type ~= nil and blind_type ~= 'boss' and blind_type ~= 'Boss') then
        return select_blind(blind_type, ...)
    end
    local game = G.GAME
    local winning_ante = game.win_ante
    local restored = {}
    for _, key in ipairs(vanilla_finishers) do
        local blind = G.P_BLINDS and G.P_BLINDS[key]
        local boss = blind and blind.boss
        if boss and boss.showdown and type(boss.min) == 'number' and boss.min > 4 then
            restored[#restored + 1] = {boss = boss, min = boss.min}
            boss.min = 4
        end
    end
    game.win_ante = 4
    local result = packed(pcall(select_blind, blind_type, ...))
    game.win_ante = winning_ante
    for _, saved in ipairs(restored) do saved.boss.min = saved.min end
    if not result[1] then error(result[2], 0) end
    return unpack(result, 2, result.n)
end
