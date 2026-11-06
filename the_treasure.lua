local key = 'j_supereditions_the_treasure'
local pending = setmetatable({}, {__mode = 'k'})
local function owned(card)
    if not (card and card.ability and card.config and card.config.center
        and card.config.center.key == key and G and G.GAME and G.jokers)
        or card.removed or card.getting_sliced
        or (type(card.dissolve) == 'number' and card.dissolve > 0) then return false end
    for _,c in ipairs(G.jokers.cards or {}) do if c == card then return true end end
    return false
end
local function expire(card)
    if not owned(card) or card.ability.extra.remaining > 0 or pending[card] == G.GAME then return end
    local game = G.GAME
    pending[card] = game
    -- Queue after the cash-out callback so its final $10 is returned normally.
    -- A saved empty chest schedules its disappearance again through update.
    G.E_MANAGER:add_event(Event({trigger = 'after', delay = 0.3, func = function()
        if pending[card] == game and G.GAME == game and owned(card)
            and card.ability.extra.remaining <= 0 then
            -- Exhaustion is destruction, never a sale. Disallowing random
            -- Eternal also keeps ordinary acquisition true to the food rule.
            SMODS.destroy_cards({card}, {bypass_eternal = true})
        end
        if pending[card] == game then pending[card] = nil end
        return true
    end}))
end

SMODS.Atlas {
    key = 'the_treasure', path = 'the-treasure.png', px = 1084, py = 1451,
    force_pixel = true, disable_mipmap = true,
}
SMODS.Joker {
    key = 'the_treasure', atlas = 'the_treasure', pos = {x = 0, y = 0},
    rarity = 'supereditions_epic', cost = 12, unlocked = true, discovered = true,
    blueprint_compat = false, eternal_compat = false, perishable_compat = false,
    config = {extra = {payout = 10, remaining = 100, last_round = -1}},
    loc_txt = {name = 'The Treasure', text = {
        'Earn {C:money}$#1#{} at end of round',
        '{C:money}$#2#{} remaining in this chest',
        '{C:attention}Destroys itself{} when empty',
    }},
    loc_vars = function(self, info_queue, card)
        return {vars = {card.ability.extra.payout, card.ability.extra.remaining}}
    end,
    calc_dollar_bonus = function(self, card)
        if not owned(card) or card.debuff then return end
        local extra, round = card.ability.extra, G.GAME.round
        if type(round) ~= 'number' or round <= 0 or extra.last_round == round then return end
        if extra.remaining <= 0 then expire(card); return end
        if extra.payout <= 0 then return end
        local amount = math.min(extra.payout, extra.remaining)
        -- Saved per-round accounting prevents repeated cash-out evaluations
        -- from spending or paying twice. Native cash-out owns the money/HUD.
        extra.remaining, extra.last_round = extra.remaining - amount, round
        if extra.remaining == 0 then expire(card) end
        return amount
    end,
    update = function(self, card, dt) expire(card) end,
}
