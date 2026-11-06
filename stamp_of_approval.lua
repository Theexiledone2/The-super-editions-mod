local key = 'j_supereditions_stamp_of_approval'
local limits = setmetatable({}, {__mode = 'k'})
local function pack(...) return {n = select('#', ...), ...} end
local function alive(card)
    return card and not card.debuff and not card.removed and not card.getting_sliced
        and not card.destroyed and not (type(card.dissolve) == 'number' and card.dissolve > 0)
end
local function counters(stamp, target)
    local state = limits[stamp]
    if not state or state.game ~= G.GAME or state.hand ~= G.GAME.hands_played
        or state.round ~= G.GAME.round then
        state = {game = G.GAME, hand = G.GAME.hands_played, round = G.GAME.round,
            cards = setmetatable({}, {__mode = 'k'})}
        limits[stamp] = state
    end
    if not state.cards[target] then state.cards[target] = setmetatable({}, {__mode = 'k'}) end
    return state.cards[target]
end

SMODS.Atlas {
    key = 'stamp_of_approval', path = 'stamp-of-approval-v2.png', px = 1085, py = 1450,
    force_pixel = true, disable_mipmap = true,
}
SMODS.Joker {
    key = 'stamp_of_approval', atlas = 'stamp_of_approval', pos = {x = 0, y = 0},
    rarity = 'supereditions_epic', cost = 12, unlocked = true, discovered = true,
    blueprint_compat = false, eternal_compat = true, perishable_compat = true,
    config = {extra = {refresh_limit = 3}},
    loc_txt = {name = 'Stamp of Approval', text = {
        'When a {C:attention}Joker{} retriggers a',
        '{C:red}Red Seal{} card, refresh its seal',
        'for {C:attention}1{} extra retrigger',
        '{C:inactive}(Up to {C:attention}#1#{C:inactive} per Joker,',
        '{C:inactive}per card, per hand)',
    }},
    loc_vars = function(self, info_queue, card)
        return {vars = {(card and card.ability.extra or self.config.extra).refresh_limit}}
    end,
    calculate = function(self, card, context)
        if not context.blueprint and not context.retrigger_joker and not context.post_trigger
            and (context.before or context.after) then limits[card] = nil end
    end,
}

-- Augment the framework's completed repetition queue. This does not evaluate
-- Jokers a second time, and keeps each source's actual repetition effects/order.
-- Added repeats belong to the Red Seal card, not a Joker, so cannot self-refresh.
if type(SMODS.calculate_repetitions) == 'function' then
    local previous = SMODS.calculate_repetitions
    SMODS.calculate_repetitions = function(card, context, reps, ...)
        local first = #reps + 1
        local result = pack(previous(card, context, reps, ...))
        if not (G and G.GAME and G.jokers and context and not context.end_of_round
            and (context.cardarea == G.play or context.cardarea == G.hand)
            and alive(card) and card.seal == 'Red') then return unpack(result, 1, result.n) end
        local sources, stamps = {}, {}
        for _, joker in ipairs(G.jokers.cards or {}) do
            if alive(joker) then
                sources[joker] = true
                if joker.config and joker.config.center and joker.config.center.key == key then
                    stamps[#stamps + 1] = joker
                end
            end
        end
        if #stamps == 0 then return unpack(result, 1, result.n) end
        local added = {}
        for i = first, #reps do
            local entry = reps[i]
            added[#added + 1] = entry
            local effect = type(entry) == 'table' and entry.retriggers
            local source = effect and effect.card
            -- Flagged entries animate Joker replays/post effects; they do not
            -- represent an actual extra playing-card score.
            if effect and not effect.retrigger_flag and sources[source]
                and source.config.center.key ~= key then
                for _, stamp in ipairs(stamps) do
                    local used = counters(stamp, card)
                    local limit = stamp.ability.extra.refresh_limit
                    if (used[source] or 0) < limit then
                        used[source] = (used[source] or 0) + 1
                        added[#added + 1] = {retriggers = {
                            card = card, repetitions = 1, message = localize('k_again_ex'),
                            colour = G.C and G.C.RED, supereditions_stamp_refresh = true,
                        }}
                    end
                end
            end
        end
        for i = #reps, first, -1 do reps[i] = nil end
        for _, entry in ipairs(added) do reps[#reps + 1] = entry end
        return unpack(result, 1, result.n)
    end
end
