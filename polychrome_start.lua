local mod = SMODS.current_mod
local state_key = 'supereditions_polychrome_start'
local function active()
    local back = G and G.GAME and G.GAME.selected_back
    return G and G.STAGES and G.STAGE == G.STAGES.RUN and back
        and back.effect and back.effect.config and back.effect.config.supereditions_polychrome_deck
end
local function state() return active() and G.GAME[state_key] end
local function choice(saved)
    local value = saved and saved.input
    if type(value) ~= 'string' or not value:match('^%d+$') then return end
    local n = tonumber(value)
    if n and n >= 0 and n <= 10 and n == math.floor(n) then return n end
end
local prompt_run
local function row(text, scale, saved)
    return {n = G.UIT.R, config = {align = 'cm', padding = 0.04}, nodes = {
        {n = G.UIT.T, config = {text = saved and nil or text,
            ref_table = saved, ref_value = saved and 'message' or nil,
            scale = scale or 0.3, colour = G.C.UI.TEXT_LIGHT}}}}
end
local function definition(saved)
    saved.message = 'Enter a whole number from 0 to 10.'
    return create_UIBox_generic_options({no_back = true, no_esc = true, contents = {
        row('Polychrome Deck', 0.5),
        row('How many Exoplanets would you like?', 0.36),
        row('Receive 0-10 Exoplanet cards to use normally.', 0.3),
        row('Each adds +X0.5 to Polychrome for the entire run when used.', 0.27),
        row('For each requested card, one completed Blind pays $0.', 0.3),
        row('This includes rewards, unused hands, interest and cash-out bonuses.', 0.25),
        row('Other money gains are allowed. Skipped Blinds do not count.', 0.27),
        {n = G.UIT.R, config = {align = 'cm', padding = 0.1}, nodes = {
            create_text_input({id = 'supereditions_exoplanet_count', w = 2.5,
                max_length = 2, text_scale = 0.4, ref_table = saved, ref_value = 'input', prompt_text = '0-10'}),
        }},
        row(nil, 0.28, saved),
        UIBox_button({label = {'Confirm and start'}, button = 'supereditions_confirm_exoplanets',
            minw = 4.5, minh = 0.7, scale = 0.35}),
    }})
end

local function confirm()
    local saved = state()
    if not saved or not saved.pending or prompt_run ~= G.GAME then return end
    local n = saved.requested or choice(saved)
    if not n then saved.message = 'Please enter a whole number from 0 to 10.'; return end
    if not G.consumeables then return end
    -- Persist the requested count before creating cards. Granted is advanced
    -- per delivered card, so a resumed partially delivered choice cannot double it.
    saved.requested = n
    while (saved.granted or 0) < n do
        local card = SMODS.create_card({set = 'Planet', key = 'c_supereditions_exoplanet',
            area = G.consumeables, no_edition = true, skip_materialize = true})
        card:add_to_deck()
        G.consumeables:emplace(card)
        saved.granted = (saved.granted or 0) + 1
    end
    saved.remaining, saved.pending = n, false
    prompt_run = nil
    if G.CONTROLLER then G.CONTROLLER.text_input_hook = nil end
    G.FUNCS.exit_overlay_menu()
    if save_run then save_run() end
end
if G and G.FUNCS then G.FUNCS.supereditions_confirm_exoplanets = confirm end

function mod.supereditions_open_exoplanet_prompt()
    local saved = state()
    if not saved or not saved.pending or not G.FUNCS or not G.FUNCS.overlay_menu
        or not G.STATES or G.STATE ~= G.STATES.BLIND_SELECT or not G.STATE_COMPLETE
        or not G.consumeables or G.OVERLAY_MENU or G.screenwipe
        or (G.SETTINGS and G.SETTINGS.paused) then return end
    for _, locked in pairs(G.CONTROLLER and G.CONTROLLER.locks or {}) do
        if locked then return end
    end
    prompt_run = G.GAME
    G.FUNCS.supereditions_confirm_exoplanets = confirm
    G.SETTINGS.paused = true
    G.FUNCS.overlay_menu({definition = definition(saved), config = {no_esc = true}})
end

if Game and type(Game.update) == 'function' then
    local previous = Game.update
    Game.update = function(self, ...)
        local result = {n = 0}
        local function capture(...) result = {n = select('#', ...), ...} end
        capture(previous(self, ...))
        mod.supereditions_open_exoplanet_prompt()
        return unpack(result, 1, result.n)
    end
end

local previous = mod.calculate
mod.calculate = function(self, context, ...)
    local result = {n = 0}
    local function capture(...) result = {n = select('#', ...), ...} end
    if previous then capture(previous(self, context, ...)) end
    local saved = state()
    if saved and not saved.pending and context.modify_final_cashout
        and not (context.blueprint or context.retrigger_joker or context.retrigger_joker_check
            or context.repetition or context.individual or context.post_trigger) then
        local round = G.GAME.round or 0
        if saved.withheld_round == round then
            SMODS.cashout_dollars = 0
        elseif (saved.remaining or 0) > 0 then
            saved.remaining = saved.remaining - 1
            saved.withheld_round = round
            SMODS.cashout_dollars = 0
        end
    end
    return unpack(result, 1, result.n)
end
