local mod = SMODS.current_mod
local probability_id = 'supereditions_flipside'
local function negative(card)
    return card.edition and (card.edition.negative or card.edition.key == 'e_negative')
end
local function eligible(card)
    return card and card.ability and SMODS.is_playing_card(card)
        and not card.debuff and not card.removed and not card.getting_sliced
        and not negative(card)
end

SMODS.Atlas {
    key = 'flipside', path = 'flipside.png', px = 1084, py = 1451,
    force_pixel = true, disable_mipmap = true,
}
SMODS.Joker {
    key = 'flipside', atlas = 'flipside', pos = {x = 0, y = 0},
    rarity = 'supereditions_epic', cost = 16, unlocked = true, discovered = true,
    blueprint_compat = false, eternal_compat = true, perishable_compat = true,
    config = {extra = {numerator = 1, denominator = 20}},
    loc_txt = {name = 'Flipside', text = {
        '{C:green}#1# in #2#{} chance #4#',
        '{C:attention}#3#{} to become {C:dark_edition}Negative{}',
        'on {C:attention}each activation{}',
        'Cards changed this way {C:attention}cannot be duplicated{}',
        '{C:inactive}(Retriggers still work){}',
    }},
    loc_vars = function(self, info_queue, card)
        info_queue[#info_queue + 1] = G.P_CENTERS.e_negative
        info_queue[#info_queue + 1] = {key = 'supereditions_flipside_bound', set = 'Other'}
        local e = card.ability.extra
        local n, d = SMODS.get_probability_vars(card, e.numerator, e.denominator, probability_id)
        return {vars = {n, d, negative(card) and 'whole played row' or 'scoring card', negative(card) and 'for the' or 'for each'}}
    end,
    calculate = function(self, card, context)
        if card.debuff or context.blueprint or context.blueprint_card or context.debuffed_hand
            or not context.individual or context.cardarea ~= G.play
            or context.repetition or context.repetition_only or context.retrigger_joker_check
            or context.post_trigger then return end
        local target, e = context.other_card, card.ability.extra
        if negative(card) then return mod.supereditions_flipside_negative_calculate(card, context) end
        if eligible(target) and SMODS.pseudorandom_probability(card, probability_id,
            e.numerator, e.denominator, probability_id) and eligible(target) then
            target:set_edition('e_negative', true)
            -- Deck/sticker rules can reject or replace the requested edition.
            -- Only an actual Flipside conversion earns the permanent restriction.
            if negative(target) and not target.removed and not target.getting_sliced then
                mod.supereditions_flipside_bind(target)
                return {message = 'Negative!', colour = G.C.DARK_EDITION}
            end
        end
    end,
}
