SMODS.Atlas {
    key = 'the_foil_family',
    path = 'the-foil-family.png',
    px = 1084,
    py = 1451,
    force_pixel = true,
    disable_mipmap = true,
}

SMODS.Joker {
    key = 'the_foil_family',
    atlas = 'the_foil_family',
    pos = {x = 0, y = 0},
    rarity = 3,
    cost = 8,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    config = {extra = {xchips = 10, required_cards = 5}},

    loc_vars = function(self, info_queue, card)
        return {vars = {card.ability.extra.xchips, card.ability.extra.required_cards}}
    end,

    calculate = function(self, card, context)
        -- Joker scoring follows played-card scoring and its repetitions.
        -- Count distinct played cards, never scoring/retrigger events.
        if card.debuff or not context.joker_main then return end
        local required = card.ability.extra.required_cards
        local played, scored = context.full_hand, context.scoring_hand
        if type(played) ~= 'table' or type(scored) ~= 'table'
            or #played ~= required or #scored ~= required then return end

        local eligible = {}
        for _, playing_card in ipairs(played) do
            if playing_card.debuff or not (playing_card.edition and playing_card.edition.foil == true)
                or eligible[playing_card] then return end
            eligible[playing_card] = true
        end
        for _, playing_card in ipairs(scored) do
            if not eligible[playing_card] then return end
            eligible[playing_card] = nil
        end
        return {xchips = card.ability.extra.xchips}
    end,
}
