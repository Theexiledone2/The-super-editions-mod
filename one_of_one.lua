local function eligible(target)
    return target and not target.removed and not target.getting_sliced
        and not target.debuff and SMODS.is_playing_card(target)
        and target.edition and (target.edition.holo or target.edition.key == 'e_holo')
        and not SMODS.has_no_rank(target) and target:is_face()
end

SMODS.Atlas {
    key = 'one_of_one', path = 'one-of-one.png', px = 1085, py = 1450,
    force_pixel = true, disable_mipmap = true,
}
SMODS.Joker {
    key = 'one_of_one', atlas = 'one_of_one', pos = {x = 0, y = 0},
    rarity = 3, cost = 8, unlocked = true, discovered = true,
    blueprint_compat = false, eternal_compat = true, perishable_compat = true,
    config = {extra = {sell_value_gain = 20}},
    loc_txt = {
        name = '1 of 1',
        text = {
            'Scored {C:dark_edition}Holographic{} face cards',
            'gain {C:attention}Eternal{} and a random {C:attention}Seal{}',
            '{C:inactive}(Only replaces Blue Seals){}',
            'This Joker gains {C:money}$#1#{} sell value',
            'per qualifying card, {C:inactive}once per hand{}',
            '{C:inactive}(Currently sells for {C:money}$#2#{C:inactive}){}',
        },
    },
    loc_vars = function(self, info_queue, card)
        info_queue[#info_queue + 1] = G.P_CENTERS.e_holo
        info_queue[#info_queue + 1] = {key = 'eternal', set = 'Other'}
        return {vars = {card.ability.extra.sell_value_gain, card.sell_cost or 0}}
    end,
    calculate = function(self, card, context)
        -- Apply seals before the first scoring pass, using the actual scoring
        -- hand. Playing-card and Joker retriggers cannot repeat these upgrades.
        if card.debuff or not context.before or context.debuffed_hand
            or context.blueprint or context.retrigger_joker
            or context.retrigger_joker_check or context.post_trigger
            or context.individual or context.repetition then return end

        local seen, count = {}, 0
        for _, target in ipairs(context.scoring_hand or {}) do
            if not seen[target] then
                seen[target] = true
                if eligible(target) then
                    if not target.seal or target.seal == 'Blue' then
                        local seal = SMODS.poll_seal({guaranteed = true,
                            key = 'supereditions_one_of_one_seal',
                            type_key = 'supereditions_one_of_one_seal_type'})
                        -- Respect a seal or edition changed by another mod's
                        -- polling callback rather than overwriting a new seal.
                        if seal and eligible(target)
                            and (not target.seal or target.seal == 'Blue') then
                            target:set_seal(seal, true)
                        end
                    end
                    if eligible(target) then
                        if not target.ability.eternal then
                            -- Deliberate application to a playing card, outside
                            -- the ordinary shop-Joker sticker compatibility pool.
                            target:add_sticker('eternal', true)
                        end
                        -- Existing non-Blue seals are kept. Already upgraded
                        -- cards still earn value when scored on a later hand.
                        if eligible(target) and target.seal and target.ability.eternal then
                            count = count + 1
                        end
                    end
                end
            end
        end
        if count > 0 then
            local gain = count * card.ability.extra.sell_value_gain
            card.ability.extra_value = (card.ability.extra_value or 0) + gain
            card:set_cost()
            return {message = '+$' .. gain .. ' Sell Value', colour = G.C.MONEY,
                no_retrigger = true}
        end
    end,
}
