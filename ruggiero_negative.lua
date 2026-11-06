local mod = SMODS.current_mod
local key = 'j_supereditions_ruggiero'
local pending = setmetatable({}, {__mode = 'k'})
local restoring = setmetatable({}, {__mode = 'k'})
local departed = setmetatable({}, {__mode = 'k'})
local tracked = setmetatable({}, {__mode = 'k'})
local function packed(...) return {n = select('#', ...), ...} end

local function joker(card)
    return card and card.ability and card.ability.set == 'Joker' and not card.playing_card
end

local function present(card)
    for _, owned in ipairs(G and G.jokers and G.jokers.cards or {}) do
        if owned == card then return true end
    end
    return false
end

local function negative_ruggiero(card)
    local edition = card.edition
    return card.config and card.config.center and card.config.center.key == key
        and edition and (edition.negative == true or edition.key == 'e_negative')
end

local function active(card)
    return joker(card) and negative_ruggiero(card) and not card.debuff
        and not card.removed and not card.getting_sliced and not departed[card]
end

-- Use the framework's saved per-card slot fields. Never modify the edition
-- or the area's base/mod limit. Back out only our own previous contribution.
local function adjust(card, free)
    local ability = card.ability
    local old = ability.supereditions_slot_adjustment or 0
    local base = (ability.extra_slots_used or 0) - old
    local net = 1 + base - (ability.card_limit or 0)
    local delta = free and -math.max(0, net) or 0
    if delta == old then return false end
    ability.extra_slots_used = base + delta
    ability.supereditions_slot_adjustment = delta ~= 0 and delta or nil
    return true
end

local reconciling = false
local function reconcile()
    if reconciling or not (G and G.GAME and G.jokers) then return end
    reconciling = true
    local sources, owned = {}, {}
    for _, card in ipairs(G.jokers.cards or {}) do
        if joker(card) then
            owned[card] = true
            tracked[card] = true
            local source = card.ability.supereditions_negative_source
            if source and active(card) then sources[source.id] = true end
        end
    end
    local changed = false
    for card in pairs(tracked) do
        if card.ability then
            local free = false
            if owned[card] and not departed[card] and not card.removed and not card.getting_sliced then
                for id in pairs(card.ability.supereditions_ruggiero_links or {}) do
                    if sources[id] then free = true; break end
                end
            end
            if adjust(card, free) then changed = true end
        end
        if not owned[card] then tracked[card] = nil end
    end
    reconciling = false
    if changed and G.jokers.handle_card_limit then G.jokers:handle_card_limit() end
end

-- Allow a newly applied/removed slot sticker to refresh existing grants
-- immediately, without re-acquiring cards or changing the original rules.
mod.supereditions_reconcile_negative_ruggiero = reconcile

local function link(card, id)
    local ability = card.ability
    ability.supereditions_ruggiero_links = ability.supereditions_ruggiero_links or {}
    ability.supereditions_ruggiero_links[id] = true
end

local function acquired(card)
    if not (joker(card) and present(card) and G.GAME) then return end
    departed[card] = nil
    local ability = card.ability
    if ability.supereditions_negative_acquired then reconcile(); return end
    ability.supereditions_negative_acquired = true

    -- A new source can itself be one of an earlier source's next five.
    for _, source_card in ipairs(G.jokers.cards) do
        local source = source_card.ability and source_card.ability.supereditions_negative_source
        if source_card ~= card and source and active(source_card) and source.remaining > 0 then
            link(card, source.id)
            source.remaining = source.remaining - 1
        end
    end
    if negative_ruggiero(card) then
        local game = G.GAME
        local serial = (game.supereditions_negative_source_counter or 0) + 1
        game.supereditions_negative_source_counter = serial
        local source = {id = tostring(serial), remaining = 0}
        ability.supereditions_negative_source = source
        local others = 0
        for _, target in ipairs(G.jokers.cards) do
            if target ~= card and joker(target) and not departed[target]
                and not target.removed and not target.getting_sliced then
                link(target, source.id)
                others = others + 1
            end
        end
        if others == 0 then source.remaining = 5 end
    end
    reconcile()
end

local previous_calculate = mod.calculate
mod.calculate = function(self, context)
    local result = previous_calculate and packed(previous_calculate(self, context)) or {n = 0}
    if context.card_added and joker(context.card) and G and G.GAME
        and not context.blueprint and not context.retrigger_joker and not context.repetition then
        local card = context.card
        if not restoring[card] then
            -- Native card_added often precedes emplace. Do not snapshot a
            -- shop/pack row or spend a grant until the card reaches G.jokers.
            pending[card] = G.GAME
            if present(card) then pending[card] = nil; acquired(card) end
        end
    end
    return unpack(result, 1, result.n)
end

if CardArea and CardArea.emplace then
    local previous = CardArea.emplace
    CardArea.emplace = function(self, card, ...)
        local result = packed(previous(self, card, ...))
        local restored = restoring[card]
        if restored then restoring[card], pending[card] = nil, nil end
        if G and self == G.jokers then
            if not restored and pending[card] == G.GAME then
                pending[card] = nil
                acquired(card)
            end
            reconcile()
        end
        return unpack(result, 1, result.n)
    end
end

if CardArea and CardArea.remove_card then
    local previous = CardArea.remove_card
    CardArea.remove_card = function(self, card, ...)
        if G and self == G.jokers and joker(card) then tracked[card] = true end
        local result = packed(previous(self, card, ...))
        if G and self == G.jokers then reconcile() end
        return unpack(result, 1, result.n)
    end
end

if Card.remove_from_deck then
    local previous = Card.remove_from_deck
    Card.remove_from_deck = function(self, from_debuff, ...)
        local result = packed(previous(self, from_debuff, ...))
        if not from_debuff then departed[self] = true; pending[self] = nil end
        reconcile()
        return unpack(result, 1, result.n)
    end
end

for _, method in ipairs({'set_edition', 'set_debuff'}) do
    if Card[method] then
        local previous = Card[method]
        Card[method] = function(self, ...)
            local result = packed(previous(self, ...))
            reconcile()
            return unpack(result, 1, result.n)
        end
    end
end

if Card.load then
    local previous = Card.load
    Card.load = function(self, ...)
        restoring[self], pending[self], departed[self] = true, nil, nil
        return previous(self, ...)
    end
end

if copy_card then
    local previous = copy_card
    copy_card = function(card, ...)
        local result = packed(previous(card, ...))
        local clone = result[1]
        if clone and clone ~= card and clone.ability then
            adjust(clone, false)
            clone.ability.supereditions_negative_acquired = nil
            clone.ability.supereditions_negative_source = nil
            clone.ability.supereditions_ruggiero_links = nil
            restoring[clone], pending[clone], departed[clone] = nil, nil, nil
        end
        return unpack(result, 1, result.n)
    end
end

if Game and Game.update then
    local previous = Game.update
    Game.update = function(self, ...)
        local result = packed(previous(self, ...))
        -- Covers save restoration, transformations and another mod changing
        -- slot fields directly. Reconciliation never creates new grants.
        reconcile()
        return unpack(result, 1, result.n)
    end
end
