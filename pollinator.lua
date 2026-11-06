SMODS.Atlas {
    key = 'pollinator',
    path = 'pollinator.png',
    px = 1084,
    py = 1451,
    force_pixel = true,
    disable_mipmap = true,
}

SMODS.Joker {
    key = 'pollinator',
    atlas = 'pollinator',
    pos = {x = 0, y = 0},
    rarity = 3,
    cost = 8,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    config = {extra = {xmult = 3}},
    loc_txt = {
        name = 'Pollinator',
        text = {
            'Each {C:dark_edition}Polychrome{} card',
            '{C:attention}held in hand{}',
            'gives {X:mult,C:white}X#1#{} Mult',
        },
    },
    loc_vars = function(self, info_queue, card)
        return {vars = {card.ability.extra.xmult}}
    end,
    calculate = function(self, card, context)
        -- Individual held-card evaluation also runs when Mime repeats a card.
        -- Do not aggregate the hand or suppress repetition_trigger callbacks.
        if card.debuff or not context.individual or context.cardarea ~= G.hand
            or context.end_of_round or context.repetition then return end

        local held = context.other_card
        if held and not held.debuff and held.edition and held.edition.polychrome then
            return {xmult = card.ability.extra.xmult}
        end
    end,
}
