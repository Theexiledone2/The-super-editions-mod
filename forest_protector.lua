SMODS.Atlas {
    key = 'forest_protector', path = 'forest-protector.png', px = 1084, py = 1451,
    force_pixel = true, disable_mipmap = true,
}
SMODS.Joker {
    key = 'forest_protector', atlas = 'forest_protector', pos = {x = 0, y = 0},
    rarity = 3, cost = 8, unlocked = true, discovered = true,
    blueprint_compat = true, eternal_compat = true, perishable_compat = true,
    config = {extra = {xmult = 1, gain = 0.3}},
    loc_txt = {
        name = 'Forest protector',
        text = {
            'Gains {X:mult,C:white}X#1#{} Mult for each',
            '{C:dark_edition}Polychrome{} playing card',
            'added to your {C:attention}deck{}',
            '{C:inactive}(Currently {X:mult,C:white}X#2#{C:inactive} Mult){}',
        },
    },
    loc_vars = function(self, info_queue, card)
        return {vars = {card.ability.extra.gain, card.ability.extra.xmult}}
    end,
    calculate = function(self, card, context)
        if card.debuff then return end
        local extra = card.ability.extra
        if context.playing_card_added and not context.blueprint then
            local count, seen = 0, {}
            for _, added in ipairs(context.cards or {}) do
                if not seen[added] and added.edition and added.edition.polychrome then
                    seen[added] = true
                    count = count + 1
                end
            end
            if count > 0 then
                extra.xmult = extra.xmult + extra.gain * count
                return {message = 'Upgraded!'}
            end
        elseif context.joker_main then
            return {xmult = extra.xmult}
        end
    end,
}
