local flag = 'supereditions_ruggiero_packs'
local ruggiero = 'j_supereditions_ruggiero'
local families = {
    supereditions_foil_contents = true,
    supereditions_polychrome_contents = true,
    supereditions_holographic_contents = true,
    supereditions_negative_contents = true,
}
local function eligible_legendaries(append)
    local keys, others, has_ruggiero = {}, {}, false
    for key, center in pairs(G.P_CENTERS or {}) do
        if center.set == 'Joker' and center.rarity == 4 then keys[#keys + 1] = key end
    end
    table.sort(keys)
    -- Delegate bans, owned/offered duplicates, Showman and custom in_pool
    -- rules to the same public eligibility boundary as Negative Pack.
    local pool = SMODS.cull_pool(keys, {
        types = {'Joker'}, rarity = 4, allow_legendaries = true, append = append,
    })
    for _, key in ipairs(pool or {}) do
        local center = G.P_CENTERS[key]
        if center and center.set == 'Joker' and center.rarity == 4 then
            if key == ruggiero then has_ruggiero = true else others[#others + 1] = key end
        end
    end
    return has_ruggiero, others
end
local function selected_legendary(append)
    local favor = pseudorandom('supereditions_ruggiero_tag_favorite') < 0.5
    local has_ruggiero, others = eligible_legendaries(append)
    if has_ruggiero and (favor or #others == 0) then return ruggiero end
    if #others == 0 then return end
    local key = SMODS.poll_object {
        type = 'Joker', pool = others, rarity = 4, allow_legendaries = true,
        append = append, seed = 'supereditions_ruggiero_tag_other_legendary', guaranteed = true,
    }
    for _, candidate in ipairs(others) do if key == candidate then return key end end
end
local function applies(args)
    return type(args) == 'table' and args.set == 'Joker'
        and G and G.GAME and G.GAME[flag] and G.STAGES and G.STAGE == G.STAGES.RUN
        and G.pack_cards and args.area == G.pack_cards and families[args.key_append]
        and not args.legendary and not args.rarity and not args.attributes
        and (not args.key or (args.key_append == 'supereditions_negative_contents' and args.key == ruggiero))
end
local previous = assert(SMODS.create_card)
SMODS.create_card = function(args, ...)
    if not applies(args) then return previous(args, ...) end
    local offer = {}; for k, v in pairs(args) do offer[k] = v end
    -- While upgraded, the shared ten-percent lottery replaces Negative
    -- Pack's original one-percent special offer rather than stacking with it.
    offer.key = nil
    if pseudorandom('supereditions_ruggiero_tag_legendary') < 0.10 then
        offer.key = selected_legendary(args.key_append)
    end
    -- A missing eligible Legendary falls back to the unchanged ordinary
    -- Joker/rarity pool. Keep the pack's edition and sticker/deck rules.
    if offer.supereditions_mega_negative then
        if offer.key == ruggiero then
            offer.no_edition, offer.edition = nil, nil
        else
            offer.no_edition, offer.edition = true, 'e_negative'
        end
    end
    return previous(offer, ...)
end
