local joker_key = 'j_supereditions_shielding_jimbo'

SMODS.Tag {
    key = 'shield_summon',
    atlas = 'shield_summon_tag',
    pos = {x = 0, y = 0},
    discovered = true,
    min_ante = 0,
    weight = 10,
    config = {type = 'immediate'},
    loc_txt = {
        name = 'Shield summon tag',
        text = {
            'Creates a {C:dark_edition}Negative{}, {C:attention}Eternal{}',
            '{C:attention}Shielding jimbo{} pinned',
            'to the {C:attention}rightmost{} Joker slot',
            'Lose {C:money}$50{}',
            '{C:inactive}(Can put you in debt){}',
        },
    },
    apply = function(self, tag, context)
        if context.type ~= 'immediate' or tag.triggered then return end
        local locks = G.CONTROLLER.locks
        local previous_lock = locks[tag.ID]
        tag.triggered = true
        locks[tag.ID] = true
        local rewarded = false
        local function reward()
            if rewarded then return true end
            local ok, err = pcall(function()
                local card = SMODS.create_card {
                    set = 'Joker', key = joker_key, area = G.jokers,
                    edition = 'e_negative', no_edition = true,
                    force_stickers = {'eternal'},
                    skip_materialize = true,
                }
                -- No affordability or empty-slot check: Negative adds capacity.
                local sequence = G.GAME.supereditions_shield_summon_sequence or 0
                for _, existing in ipairs(G.jokers.cards) do
                    local saved = existing.ability and existing.ability.supereditions_shield_summon_order
                    if type(saved) == 'number' then sequence = math.max(sequence, saved) end
                end
                sequence = sequence + 1
                card.ability.supereditions_shield_summon_order = sequence
                G.GAME.supereditions_shield_summon_sequence = sequence
                SMODS.add_to_deck(card, {area = G.jokers})
                -- Use the game money API so HUD and spending effects stay in sync.
                -- Instant mode applies the complete debit without a zero clamp.
                ease_dollars(-50, true)
                rewarded = true
                G.jokers:align_cards()
                card:start_materialize()
            end)
            locks[tag.ID] = previous_lock
            if not ok then error(err, 0) end
            return true
        end
        local ok, err = pcall(tag.yep, tag, '-$50', G.C.MONEY, reward)
        if not ok then
            locks[tag.ID] = previous_lock
            tag.triggered = false
            error(err, 0)
        end
        return true
    end,
}
