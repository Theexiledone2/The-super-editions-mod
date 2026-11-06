local mod = SMODS.current_mod
if not mod then return end
local state
local function pack(...) return {n = select('#', ...), ...} end
local function enabled()
    return mod.config and mod.config.speedy_scoring == true
end
local function scoring()
    return state and G and state.game == G.GAME and G.STATES
        and G.STATE == G.STATES.HAND_PLAYED
end
local function begin_hand()
    state = {game = G and G.GAME, multiplier = 1, wait = 0, count = 0}
end
local function advance()
    if not (scoring() and enabled()) then return end
    state.count = state.count + 1
    -- Multiplication avoids computing an overflowing speed factor. Eventually
    -- this underflows to zero, meaning no animation wait, not skipped scoring.
    state.multiplier = state.multiplier / (mod.config.speedy_scoring_rate == 2 and 1.10 or 1.05)
end
local function options_with_delay(options)
    if not (scoring() and enabled() and type(options) == 'table'
        and type(options.delay) == 'number' and options.delay > 0
        and options.delay < math.huge) then return options end
    local copy = {}; for key, value in pairs(options) do copy[key] = value end
    -- A per-hand animation-wait budget supplements the uncapped acceleration.
    -- This is a sum of scheduled waits, not a guarantee about CPU/frame time.
    copy.delay = math.min(options.delay * state.multiplier, math.max(0, 60 - state.wait))
    state.wait = state.wait + copy.delay
    return copy
end

if SMODS.calculate_context then
    local previous = SMODS.calculate_context
    SMODS.calculate_context = function(context, ...)
        if context and context.before and context.full_hand then begin_hand() end
        return previous(context, ...)
    end
end
if SMODS.calculate_individual_effect then
    local previous = SMODS.calculate_individual_effect
    SMODS.calculate_individual_effect = function(effect, card, key, amount, ...)
        local result = pack(previous(effect, card, key, amount, ...))
        -- Query-only contexts and unhandled effects must not accelerate time.
        if result[1] == true and SMODS.Scoring_Parameter_Calculation
            and SMODS.Scoring_Parameter_Calculation[key] then advance() end
        return unpack(result, 1, result.n)
    end
end
if type(Event) == 'table' and Event.init then
    local previous = Event.init
    Event.init = function(self, options, ...)
        return previous(self, options_with_delay(options), ...)
    end
end
if Game and Game.update then
    local previous = Game.update
    Game.update = function(self, ...)
        local result = pack(previous(self, ...))
        if state and not scoring() then state = nil end
        return unpack(result, 1, result.n)
    end
end
