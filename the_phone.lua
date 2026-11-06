local probability_id = 'supereditions_the_phone'
local function eligible(target)
    return target and SMODS.is_playing_card(target) and not target.debuff
        and not target.edition
        and not (target.ability and target.ability.supereditions_polychrome)
end

SMODS.Atlas {
    key = 'the_phone', path = 'the-phone.png', px = 1084, py = 1451,
    force_pixel = true, disable_mipmap = true,
}
SMODS.Joker {
    key = 'the_phone', atlas = 'the_phone', pos = {x = 0, y = 0},
    rarity = 3, cost = 8, unlocked = true, discovered = true,
    blueprint_compat = true, eternal_compat = true, perishable_compat = true,
    config = {extra = {numerator = 1, denominator = 10}},
    loc_txt = {
        name = 'The phone',
        text = {
            '{C:green}#1# in #2#{} chance for each',
            '{C:attention}scoring card{} without an edition',
            'to become {C:dark_edition}Holographic{}',
            '{C:attention}before{} the hand scores',
            '{C:inactive}(One roll per card; respects stickers){}',
        },
    },
    loc_vars = function(self, info_queue, card)
        info_queue[#info_queue + 1] = G.P_CENTERS.e_holo
        local extra = card.ability.extra
        local numerator, denominator = SMODS.get_probability_vars(
            card, extra.numerator, extra.denominator, probability_id)
        return {vars = {numerator, denominator}}
    end,
    calculate = function(self, card, context)
        if card.debuff or not context.before or context.debuffed_hand
            or context.individual or context.repetition
            or context.retrigger_joker_check or context.post_trigger then return end

        local extra, seen, changed = card.ability.extra, {}, false
        -- The finalized scoring hand excludes non-scoring played cards. Apply
        -- editions synchronously here so their bonus exists on the first score.
        -- Playing-card retriggers never run this before-hand roll again.
        for _, target in ipairs(context.scoring_hand or {}) do
            if not seen[target] then
                seen[target] = true
                if eligible(target) and SMODS.pseudorandom_probability(
                    card, probability_id, extra.numerator, extra.denominator, probability_id)
                    -- Probability listeners may have changed the card meanwhile.
                    and eligible(target) then
                    target:set_edition('e_holo', true)
                    if target.edition and (target.edition.holo or target.edition.key == 'e_holo') then
                        changed = true
                    end
                end
            end
        end
        if changed then return {message = 'Holographic!', colour = G.C.DARK_EDITION} end
    end,
}
