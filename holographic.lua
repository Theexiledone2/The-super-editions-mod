local mod = SMODS.current_mod
local state_key = 'supereditions_holographic_deck'
local pack_key = 'p_supereditions_holographic_mega'
local delivery

local function active()
    local back = G and G.GAME and G.GAME.selected_back
    local config = back and back.effect and back.effect.config
    return config and config.supereditions_holographic_deck == true
        and G.STAGES and G.STAGE == G.STAGES.RUN
end

-- Add the deck factor to the actual edition effect. Native calculation applies
-- +Mult before XMult; card retriggers reach this boundary again naturally.
-- Empty edition tables cleared by the Joker scoring loop must remain empty.
local multiply_keys = {'x_mult', 'Xmult', 'xmult', 'x_mult_mod', 'Xmult_mod'}
local function eligible(card)
    if type(card) ~= 'table' or card.debuff then return false end
    local edition = card.edition
    if not edition or not (edition.holo or edition.key == 'e_holo') then return false end
    local center, ability = card.config and card.config.center or {}, card.ability or {}
    local set = center.set or ability.set
    if center.consumeable or ability.consumeable
        or (SMODS.ConsumableTypes and SMODS.ConsumableTypes[set]) then return false end
    return set == 'Joker' or (SMODS.is_playing_card and SMODS.is_playing_card(card))
end
local effect = assert(SMODS.calculate_effect)
SMODS.calculate_effect = function(value, card, from_edition, ...)
    if active() and from_edition == true and eligible(card) and type(value) == 'table'
        and not value.supereditions_holographic_deck_bonus then
        local xkey
        for _, key in ipairs(multiply_keys) do
            if value[key] ~= nil and value[key] ~= false then xkey = key; break end
        end
        if xkey or value.mult or value.h_mult or value.mult_mod then
            local adjusted = {}; for key, entry in pairs(value) do adjusted[key] = entry end
            local amount = xkey and value[xkey] or 1
            local N = mod.supereditions_numbers
            adjusted[xkey or 'x_mult'] = N and N.active() and N.mul(amount, 1.1) or amount * 1.1
            adjusted.supereditions_holographic_deck_bonus = true
            value = adjusted
        end
    end
    return effect(value, card, from_edition, ...)
end

local function state()
    local run = G.GAME
    run[state_key] = run[state_key] or {pending = 0}
    return run[state_key]
end

local function release(current)
    if current and current.locks then
        current.locks.supereditions_holographic_deck = nil
    end
end

local function ready()
    if not active() or not G.STATES or G.STATE ~= G.STATES.BLIND_SELECT
        or not G.STATE_COMPLETE or not G.blind_select or not G.play
        or G.pack_cards or G.OVERLAY_MENU or G.screenwipe
        or (G.SETTINGS and G.SETTINGS.paused) then return false end
    for _, lock in pairs(G.CONTROLLER and G.CONTROLLER.locks or {}) do
        if lock then return false end
    end
    return true
end

-- Deliver at the normal tag-pack screen after the shop, without creating a
-- Tag. An earned deck reward must not spend stored Double or Triple Tags.
function mod.supereditions_open_holographic_deck_reward()
    if delivery and delivery.run ~= (G and G.GAME) then
        release(delivery)
        delivery = nil
    end
    if delivery or not ready() then return end
    local run, saved = G.GAME, G.GAME[state_key]
    if not saved or (saved.pending or 0) <= 0 then return end
    local current = {run = run, locks = G.CONTROLLER and G.CONTROLLER.locks}
    delivery = current
    if current.locks then current.locks.supereditions_holographic_deck = true end
    local ok, err = pcall(function()
        local pack = SMODS.create_card {
            set = 'Booster', area = G.play, key = pack_key,
            skip_materialize = true, no_edition = true,
        }
        current.card = pack
        if G.GAME ~= run then
            if pack.remove then pack:remove() end
            release(current)
            delivery = nil
            return
        end
        pack.ability.couponed = true
        pack:set_cost()
        pack.cost, pack.from_tag = 0, true
        local result = G.FUNCS.use_card({config = {ref_table = pack}})
        if result == false and not current.opened then
            if pack.remove then pack:remove() end
            release(current)
            delivery = nil
            return
        end
        current.submitted = true
        pack:start_materialize()
    end)
    if not ok then
        release(current)
        -- Native use may already have queued the opening event. A cosmetic
        -- failure afterward must not destroy that pack or submit a second one.
        if not current.opened and not current.submitted then
            delivery = nil
            if current.card and current.card.remove then current.card:remove() end
        end
        error(err, 0)
    end
end

SMODS.Atlas {key = 'holographic_deck', path = 'holographic-deck.png',
    px = 1085, py = 1450, force_pixel = true, disable_mipmap = true}

SMODS.Back {
    key = 'holographic', unlocked = true, discovered = true,
    atlas = 'holographic_deck', pos = {x = 0, y = 0},
    config = {supereditions_holographic_deck = true},
    loc_txt = {
        name = 'Holographic Deck',
        text = {
            'Start with {C:attention}52{}',
            '{C:dark_edition}Holographic{} playing cards',
            '{X:mult,C:white}X1.1{} Mult per {C:dark_edition}Holographic{} activation',
            '{s:0.8,C:inactive}(In addition to its normal bonus){}',
            'Defeating each {C:attention}Boss Blind{} gives',
            'a free {C:dark_edition}Mega Holographic Pack{}',
            '{s:0.8,C:inactive}(Opens after the shop){}',
        },
    },
    apply = function(self, back)
        local run = G.GAME
        -- Back.apply runs before starting playing cards are constructed.
        G.E_MANAGER:add_event(Event({func = function()
            if G.GAME ~= run or not active() then return true end
            local saved = state()
            if saved.initialized then return true end
            local cards = G.playing_cards or {}
            if #cards == 0 then return false end
            for i = 1, math.min(52, #cards) do
                cards[i]:set_edition('e_holo', true, true)
            end
            saved.initialized = true
            return true
        end}))
    end,
    calculate = function(self, back, context)
        if not active() then return end
        if context.open_booster and delivery and delivery.run == G.GAME
            and context.card == delivery.card and not delivery.opened then
            local saved = state()
            saved.pending = math.max(0, (saved.pending or 0) - 1)
            delivery.opened = true
            release(delivery)
        elseif context.ending_booster and delivery and delivery.run == G.GAME
            and delivery.opened and (not context.booster or context.booster.key == pack_key) then
            -- The framework clears booster_obj before Skip closes a pack.
            release(delivery)
            delivery = nil
        end
        if not context.round_eval or context.game_over or context.blueprint
            or context.retrigger_joker or context.individual or context.repetition
            or context.repetition_only then return end
        local run, blind = G.GAME, G.GAME.blind
        if not blind or type(run.round) ~= 'number' or run.round < 1
            or run.chips == nil or blind.chips == nil or run.chips < blind.chips then return end
        local definition = blind.config and blind.config.blind
        -- The actual definition identifies converted Small/Big bosses too.
        -- Steamodded's blind.boss flag describes their round slot instead.
        local boss = definition and definition.boss or (not definition and blind.boss)
        if not boss then return end
        local saved = state()
        if saved.last_reward_round == run.round then return end
        saved.last_reward_round = run.round
        saved.pending = (saved.pending or 0) + 1
    end,
}

-- Observe settled native UI and existing Chat Plays updates before opening.
-- Pending counts and round guards live in the ordinary saved run table.
if Game and type(Game.update) == 'function' then
    local previous = Game.update
    local function pack(...) return {n = select('#', ...), ...} end
    Game.update = function(self, ...)
        local result = pack(previous(self, ...))
        mod.supereditions_open_holographic_deck_reward()
        return unpack(result, 1, result.n)
    end
end
