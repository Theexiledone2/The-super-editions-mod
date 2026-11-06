local mod = SMODS.current_mod
SMODS.Atlas {
    key = 'scalper', path = 'scalper.png', px = 1084, py = 1451,
    force_pixel = true, disable_mipmap = true,
}
SMODS.Joker {
    key = 'scalper', rarity = 3, cost = 8, unlocked = true, discovered = true,
    atlas = 'scalper', pos = {x = 0, y = 0},
    blueprint_compat = false, eternal_compat = true, perishable_compat = true,
    config = {extra = {buy_cost = 5, sell_price = 3, click_seconds = 5}},
    loc_txt = {
        name = 'Scalper',
        text = {
            '{C:attention}Triple left-click{} within {C:attention}#3#s{}:',
            'Pay {C:money}$#1#{} for a {C:dark_edition}Holographic{}',
            '{C:attention}face card{} with random enhancement and seal',
            '{C:attention}Triple right-click{} within {C:attention}#3#s{}:',
            'Destroy {C:attention}1-3 selected editioned face cards{},',
            'receive {C:money}$#2#{} for each destroyed card',
            '{s:0.8,C:inactive}(Use while choosing cards to play){}',
        },
    },
    loc_vars = function(self, info_queue, card)
        local extra = card.ability.extra
        return {vars = {extra.buy_cost, extra.sell_price, extra.click_seconds}}
    end,
    update = function(self, card, dt) mod.supereditions_scalper_update(card) end,
}
