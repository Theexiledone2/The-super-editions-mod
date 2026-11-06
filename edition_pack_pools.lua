local mod = SMODS.current_mod
local function deck_family()
    local back = G and G.GAME and G.GAME.selected_back
    local config = back and back.effect and back.effect.config
    if not config or not G.STAGES or G.STAGE ~= G.STAGES.RUN then return end
    if config.supereditions_polychrome_deck then return 'polychrome' end
    if config.supereditions_foil_deck then return 'foil' end
end

-- Attached only to this mod's packs and pack-granting tags. Vanilla and
-- third-party pack pools are not patched or filtered.
function mod.supereditions_pack_in_pool(family)
    local selected = deck_family()
    return selected == nil or selected == family
end

-- Already-owned pack tags from older saves still give a free Mega pack, but
-- its family follows the selected edition deck. No tags are deleted/lost.
function mod.supereditions_pack_reward_key(family, size)
    return 'p_supereditions_' .. (deck_family() or family) .. '_' .. size
end
