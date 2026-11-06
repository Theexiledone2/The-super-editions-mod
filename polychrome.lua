-- Run-local edition rules; no global edition config or older mod module is changed.
local function active()
    local back = G and G.GAME and G.GAME.selected_back
    return back and back.effect and back.effect.config
        and back.effect.config.supereditions_polychrome_deck == true
        and G.STAGES and G.STAGE == G.STAGES.RUN
end

local function joker(card)
    return card and ((card.config and card.config.center and card.config.center.set == 'Joker')
        or (card.ability and card.ability.set == 'Joker'))
end

local function eligible(card)
    if not card then return false end
    local center = card.config and card.config.center or {}
    local ability = card.ability or {}
    local set = center.set or ability.set
    -- Positive inclusion of playing cards/Jokers, with an explicit consumable
    -- veto for custom sets and hybrid cards supplied by other mods.
    if center.consumeable or ability.consumeable
        or (SMODS.ConsumableTypes and SMODS.ConsumableTypes[set]) then return false end
    return joker(card) or SMODS.is_playing_card(card)
end

local function blocked(card)
    return joker(card) and card.ability and card.ability.supereditions_polychrome
end

local function polychrome(card)
    return card and card.edition
        and (card.edition.polychrome or card.edition.key == 'e_polychrome')
end

local function copy(value)
    local result = {}
    for k, v in pairs(value) do result[k] = v end
    return result
end
local function packed(...) return {n = select('#', ...), ...} end

local consumable_mod = SMODS.current_mod
local function edition_mult()
    local bonus = consumable_mod.supereditions_exoplanet_bonus
    local center = G and G.P_CENTERS and G.P_CENTERS.e_polychrome
    return (center and center.config and center.config.x_mult or 1.5) + (bonus and bonus() or 0)
end

local function boost(card)
    if polychrome(card) and card.edition.x_mult ~= edition_mult() then
        -- The per-card edition value is saved with the card and used by the
        -- ordinary edition tooltip/scoring. Never mutate a shared config table.
        card.edition = copy(card.edition)
        card.edition.x_mult = edition_mult()
    end
end

local function ensure(card)
    if not active() or not eligible(card) then return end
    if blocked(card) then
        -- No retry/Nope spam from upkeep. Explicit edition attempts still go
        -- through the existing sticker wrapper and produce its normal Nope.
        if card.edition then card:set_edition(nil, true, true) end
    elseif not polychrome(card) then
        card:set_edition('e_polychrome', true, true)
    else
        boost(card)
    end
end

local function refresh_owned()
    for _, card in ipairs(G.playing_cards or {}) do ensure(card) end
    for _, card in ipairs(G.jokers and G.jokers.cards or {}) do ensure(card) end
end

SMODS.Atlas {key = 'polychrome_deck', path = 'polychrome-deck.png',
    px = 1084, py = 1451, force_pixel = true, disable_mipmap = true}

SMODS.Back {
    key = 'polychrome', unlocked = true, discovered = true,
    atlas = 'polychrome_deck', pos = {x = 0, y = 0},
    config = {supereditions_polychrome_deck = true},
    -- Capitalized Ranks follows the official initial_deck release example.
    -- This is a starting filter only; later face cards are not prohibited.
    initial_deck = {exclude = true, Ranks = {'King'}},
    loc_txt = {
        name = 'Polychrome Deck',
        text = {
            'All {C:attention}Jokers{} and {C:attention}playing cards{}',
            'are {C:dark_edition}Polychrome{}',
            '{C:inactive}(No starting Kings){}',
            'Choose {C:attention}0-10 Exoplanets{} at run start',
            'Lose that many completed {C:attention}Blind payouts{}',
            '{C:inactive}(Consumables excluded){}',
        },
    },
    apply = function(self, back)
        -- Starting cards are created after Back.apply; let the engine finish.
        local game = G.GAME
        game.supereditions_polychrome_start = game.supereditions_polychrome_start
            or {pending = true, input = '0', remaining = 0, granted = 0}
        G.E_MANAGER:add_event(Event({func = function()
            if G.GAME == game and active() then refresh_owned() end
            return true
        end}))
    end,
    calculate = function(self, back, context)
        if not active() then return end
        if context.modify_shop_card or context.modify_booster_card or context.card_added then
            ensure(context.card)
        elseif context.playing_card_added then
            for _, card in ipairs(context.cards or {}) do ensure(card) end
        elseif context.setting_blind or context.starting_shop or context.before then
            -- Also covers resumed runs and cards restored by external effects.
            refresh_owned()
        end
    end,
}

-- Keep editions Polychrome throughout this deck's run, including forced pack,
-- tag and consumable applications. The existing sticker always has priority.
local set_edition = assert(Card.set_edition)
Card.set_edition = function(self, edition, ...)
    local applies = active() and eligible(self) and not blocked(self)
    if applies then edition = 'e_polychrome' end
    local result = packed(set_edition(self, edition, ...))
    if applies then boost(self) end
    return unpack(result, 1, result.n)
end

-- Creation catches editionless offers before they are displayed/priced.
-- Addition catches native creation, copies and directly supplied gifts before
-- their add-to-deck callbacks (e.g. Forest protector's growth) are dispatched.
local create_card = assert(SMODS.create_card)
SMODS.create_card = function(...)
    local result = packed(create_card(...))
    ensure(result[1])
    return unpack(result, 1, result.n)
end
local add_to_deck = assert(Card.add_to_deck)
Card.add_to_deck = function(self, ...)
    ensure(self)
    return add_to_deck(self, ...)
end

-- Normalize legacy X4 saves to the ordinary base plus Exoplanet bonuses.
-- This also covers adapters that emit the vanilla constant, and passes the
-- adjusted table to Poli-faker so each replay uses the normal base plus earned Exoplanet bonuses.
-- We neither add a second multiplier nor grant any new scoring/held-card trigger.
local calculate_effect = assert(SMODS.calculate_effect)
SMODS.calculate_effect = function(effect, card, from_edition, ...)
    if active() and from_edition == true and eligible(card) and not blocked(card)
        and not card.debuff and polychrome(card) and type(effect) == 'table' then
        local adjusted
        for _, key in ipairs({'xmult', 'x_mult', 'Xmult_mod'}) do
            if effect[key] ~= nil and effect[key] ~= edition_mult() then
                adjusted = adjusted or copy(effect)
                adjusted[key] = edition_mult()
            end
        end
        effect = adjusted or effect
    end
    return calculate_effect(effect, card, from_edition, ...)
end
