-- Run counters live in G.GAME so ordinary run saves retain both consumables.
local mod = SMODS.current_mod
local function pack(...) return {n = select('#', ...), ...} end
local function copy(t) local r = {}; for k,v in pairs(t) do r[k] = v end; return r end
local function active()
    return G and G.GAME and G.STAGES and G.STAGE == G.STAGES.RUN
end
local function count(key)
    local n = active() and G.GAME[key] or 0
    return type(n) == 'number' and n == n and math.max(0, n) or 0
end
local function bonus() return count('supereditions_exoplanet_uses') * 0.5 end
mod.supereditions_exoplanet_bonus = bonus
local function eligible(card)
    if not card then return false end
    local center, ability = card.config and card.config.center or {}, card.ability or {}
    local set = center.set or ability.set
    if center.consumeable or ability.consumeable
        or (SMODS.ConsumableTypes and SMODS.ConsumableTypes[set]) then return false end
    return set == 'Joker' or SMODS.is_playing_card(card)
end
local function polychrome(card)
    return card and card.edition and (card.edition.polychrome or card.edition.key == 'e_polychrome')
end
local function deck_active()
    local back = G.GAME.selected_back
    return back and back.effect and back.effect.config and back.effect.config.supereditions_polychrome_deck
end
local function refresh(card)
    if not active() or not eligible(card) or not polychrome(card) then return end
    local edition = card.edition
    local added = bonus()
    local prior = edition.supereditions_exoplanet_applied or 0
    if added == 0 and prior == 0 then return end
    local center = G.P_CENTERS and G.P_CENTERS.e_polychrome
    local normal = center and center.config and center.config.x_mult or 1.5
    local base = deck_active() and normal or (edition.x_mult or normal) - prior
    local value = base + added
    if edition.x_mult ~= value or prior ~= added then
        card.edition = copy(edition)
        card.edition.x_mult = value
        card.edition.supereditions_exoplanet_applied = added
    end
end
local function refresh_all()
    if not active() then return end
    local seen = {}
    local function visit(cards)
        for _, card in ipairs(cards or {}) do
            if not seen[card] then refresh(card); seen[card] = true end
        end
    end
    visit(G.playing_cards)
    for _, name in ipairs({'jokers','hand','play','deck','discard','shop_jokers','pack_cards'}) do
        visit(G[name] and G[name].cards)
    end
end
mod.supereditions_refresh_exoplanet = refresh_all

local setter = assert(Card.set_edition)
Card.set_edition = function(self, ...)
    local result = pack(setter(self, ...)); refresh(self)
    return unpack(result, 1, result.n)
end
local create = assert(SMODS.create_card)
SMODS.create_card = function(...)
    local result = pack(create(...)); refresh(result[1])
    return unpack(result, 1, result.n)
end
local add = assert(Card.add_to_deck)
Card.add_to_deck = function(self, ...)
    refresh(self); return add(self, ...)
end
if type(Card.load) == 'function' then
    local load = Card.load
    Card.load = function(self, ...)
        local result = pack(load(self, ...)); refresh(self)
        return unpack(result, 1, result.n)
    end
end
local calculate = mod.calculate
mod.calculate = function(self, context)
    local result = calculate and pack(calculate(self, context)) or {n = 0}
    if context.before or context.starting_shop or context.setting_blind then refresh_all() end
    if context.card_added or context.modify_shop_card or context.modify_booster_card then refresh(context.card) end
    if context.playing_card_added then
        for _, card in ipairs(context.cards or {}) do refresh(card) end
    end
    return unpack(result, 1, result.n)
end
local effect = assert(SMODS.calculate_effect)
SMODS.calculate_effect = function(value, card, from_edition, ...)
    if bonus() > 0 and from_edition == true and eligible(card) and polychrome(card)
        and not card.debuff and not (card.ability and card.ability.supereditions_polychrome)
        and type(value) == 'table' then
        refresh(card)
        local adjusted
        for _, key in ipairs({'xmult','x_mult','Xmult_mod'}) do
            if value[key] ~= nil and value[key] ~= card.edition.x_mult then
                adjusted = adjusted or copy(value); adjusted[key] = card.edition.x_mult
            end
        end
        value = adjusted or value
    end
    return effect(value, card, from_edition, ...)
end

-- Showmanry adds probability mass, not a relative weight multiplier. Delegate
-- pool building, filters and weighted choice to the documented engine API.
-- A guaranteed poll exposes the eligible pool even if the ordinary chance would
-- have failed. An independent seeded gate restores that chance plus the bonus.
local poll = assert(SMODS.poll_object)
local dispatch = assert(SMODS.calculate_context)
local frame
SMODS.calculate_context = function(context, ...)
    local current = frame
    local result = pack(dispatch(context, ...))
    if current and context.modify_weights and type(context.pool) == 'table' then
        -- Store the reference so later synchronous weight adjustments are seen.
        current.pool = context.pool
    end
    return unpack(result, 1, result.n)
end
local function edition_poll(args)
    if type(args) ~= 'table' or args.attributes then return false end
    if args.type == 'Edition' and not args.types then return true end
    return args.types and #args.types == 1 and args.types[1] == 'Edition'
end
local function clamp(n) return math.max(0, math.min(1, n)) end
SMODS.poll_object = function(args, ...)
    local extra = math.min(1, count('supereditions_showmanry_uses') * 0.01)
    local enabled = extra > 0 and edition_poll(args)
    local previous = frame
    frame = enabled and {} or nil
    local current, forwarded = frame, args
    if enabled then forwarded = copy(args); forwarded.guaranteed = true end
    local result = pack(pcall(poll, forwarded, ...))
    frame = previous
    if not result[1] then error(result[2], 0) end
    if not enabled then return unpack(result, 2, result.n) end

    local chance = args.chance
    if chance == nil then chance = SMODS.base_rate_percentage and SMODS.base_rate_percentage.Edition or 0.04 end
    chance = args.guaranteed and 1 or clamp(chance * (args.mod or 1))
    local total, poly = 0, 0
    for _, entry in pairs(current.pool or {}) do
        local weight = entry.weight
        if entry.key ~= 'UNAVAILABLE' and type(weight) == 'number' and weight > 0 then
            total = total + weight
            if entry.key == 'e_polychrome' or (args.no_negative and entry.key == 'e_negative') then
                poly = poly + weight
            end
        end
    end
    local forced, ordinary = 0, chance
    if poly > 0 and total > 0 and result[2] ~= nil then
        local ratio = poly / total
        local delta = math.min(extra, 1 - chance * ratio)
        forced = delta
        if chance + delta > 1 then
            -- Once editionless probability is exhausted, redistribute the other
            -- editions proportionally until Polychrome reaches 100%.
            ordinary = ratio < 1 and math.max(0, (1 - chance * ratio - delta) / (1 - ratio)) or 0
            forced = 1 - ordinary
        end
    end
    local seed = 'supereditions_showmanry_' .. tostring(args.seed or args.type_key or 'Edition')
        .. '_' .. tostring(args.append or '')
    local roll = pseudorandom(seed)
    if roll < forced then result[2] = 'e_polychrome'
    elseif roll >= forced + ordinary then result[2] = nil end
    return unpack(result, 2, result.n)
end
