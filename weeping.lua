local mod = SMODS.current_mod
local state_key = 'supereditions_weeping'
local click_run, click_time
local function pack(...) return {n = select('#', ...), ...} end
local function active()
    local back = G and G.GAME and G.GAME.selected_back
    return G and G.STAGES and G.STAGE == G.STAGES.RUN and back and back.effect
        and back.effect.config and back.effect.config.supereditions_weeping_deck == true
end
local function state()
    if not active() then return end
    G.GAME[state_key] = G.GAME[state_key] or {stored = 0, pending = 0}
    return G.GAME[state_key]
end
local function ready()
    if not active() or not G.consumeables or not G.STATES or G.OVERLAY_MENU
        or G.screenwipe or (G.SETTINGS and G.SETTINGS.paused) then return false end
    for _, locked in pairs(G.CONTROLLER and G.CONTROLLER.locks or {}) do
        if locked then return false end
    end
    for _, name in ipairs({'SELECTING_HAND', 'SHOP', 'BLIND_SELECT', 'TAROT_PACK',
        'SPECTRAL_PACK', 'PLANET_PACK', 'STANDARD_PACK', 'BUFFOON_PACK', 'SMODS_BOOSTER_OPENED'}) do
        if G.STATES[name] and G.STATE == G.STATES[name] then return true end
    end
    return false
end
local function save() if save_run then save_run() end end

SMODS.Atlas {key = 'weeping_deck', path = 'weeping-deck.png',
    px = 1083, py = 1452, force_pixel = true, disable_mipmap = true}
SMODS.Back {
    key = 'weeping', unlocked = true, discovered = true,
    atlas = 'weeping_deck', pos = {x = 0, y = 0},
    config = {supereditions_weeping_deck = true},
    loc_txt = {name = 'Weeping Deck', text = {
        '{C:purple}Purple Seal{} activations store',
        '{C:attention}1{} extra random {C:tarot}Tarot{}',
        '{C:attention}Double-click{} the counter to claim',
        'all stored cards, {C:attention}ignoring slot limits{}',
        '{C:tarot}Tarot{} duplicates may appear',
        '{s:0.8,C:inactive}(Normal seal rewards are kept){}',
    }},
}

-- Observe actual seal evaluation; normal reward creation and its capacity
-- check are left to the game. A full area still earns the banked reward.
if Card and type(Card.calculate_seal) == 'function' then
    local previous = Card.calculate_seal
    Card.calculate_seal = function(self, context, ...)
        local run = G and G.GAME
        local counts = active() and self.seal == 'Purple' and not self.debuff
            and context and context.discard and context.other_card == self
        local result = pack(previous(self, context, ...))
        if counts and G.GAME == run then
            local saved = state()
            if saved then saved.stored = saved.stored + 1 end
        end
        return unpack(result, 1, result.n)
    end
end

-- Tarot-only duplicate permission applies to normal seal rewards, shops,
-- packs and the bank. Keep all other pool restrictions and Showman behavior.
if type(SMODS.showman) == 'function' then
    local previous = SMODS.showman
    SMODS.showman = function(key, ...)
        local center = G and G.P_CENTERS and G.P_CENTERS[key]
        if active() and center and center.set == 'Tarot' then return true end
        return previous(key, ...)
    end
end

local function claim(e)
    local saved = state()
    if not ready() or not saved or saved.stored < 1 or saved.pending > 0
        or (e and e.config and e.config.ref_table ~= saved) then
        click_run, click_time = nil, nil
        return
    end
    local now = G.TIMERS and G.TIMERS.REAL or 0
    if click_run ~= G.GAME or not click_time or now < click_time or now - click_time > 0.65 then
        click_run, click_time = G.GAME, now
        return
    end
    click_run, click_time = nil, nil
    -- Persist an unfulfilled count, not card objects or events. Resuming a run
    -- can finish delivery without replaying already delivered cards.
    saved.pending, saved.stored = saved.stored, 0
    save()
end

function mod.supereditions_deliver_weeping()
    local saved = state()
    if not saved or saved.pending < 1 or not ready() then return end
    -- One per update keeps larger claims responsive. There is no capacity
    -- check or input lock; pending counts and delivered cards save together.
    local card = SMODS.create_card {set = 'Tarot', area = G.consumeables,
        allow_duplicates = true, key_append = 'supereditions_weeping',
        skip_materialize = true}
    card:add_to_deck()
    G.consumeables:emplace(card)
    saved.pending = saved.pending - 1
    save()
end

local function update_button(e)
    local saved = state()
    local enabled = saved and ready() and saved.stored > 0 and saved.pending == 0
    e.config.button = enabled and 'supereditions_claim_weeping' or nil
    e.config.colour = enabled and G.C.PURPLE or G.C.UI.BACKGROUND_INACTIVE
    if saved then
        saved.label = 'Tarots: '..tostring(saved.stored)
        saved.hint = saved.pending > 0 and ('Creating: '..tostring(saved.pending)) or 'Double-click'
    end
    if not enabled then click_run, click_time = nil, nil end
end
if G and G.FUNCS then
    G.FUNCS.supereditions_claim_weeping = claim
    G.FUNCS.supereditions_weeping_counter = update_button
end

local function find(node, id)
    if type(node) ~= 'table' then return end
    if node.config and node.config.id == id then return node end
    for _, child in ipairs(node.nodes or {}) do
        local result = find(child, id); if result then return result end
    end
end
if type(create_UIBox_HUD) == 'function' then
    local previous = create_UIBox_HUD
    create_UIBox_HUD = function(...)
        local result = pack(previous(...))
        local saved = state()
        local area = saved and find(result[1], 'button_area')
        if area and not find(area, 'supereditions_weeping_counter') then
            -- Fit below Run Info/Options in their existing HUD column.
            for _, child in ipairs(area.nodes or {}) do
                if child.config and child.config.minh == 1.75 then child.config.minh = 1.25 end
            end
            saved.label, saved.hint = 'Tarots: '..tostring(saved.stored), 'Double-click'
            area.nodes[#area.nodes+1] = {n = G.UIT.R, config = {
                id = 'supereditions_weeping_counter', align = 'cm', minh = 0.9, minw = 1.5,
                padding = 0.03, r = 0.1, hover = true, colour = G.C.PURPLE,
                button = 'supereditions_claim_weeping', func = 'supereditions_weeping_counter',
                ref_table = saved, shadow = true}, nodes = {
                    {n = G.UIT.R, config = {align = 'cm'}, nodes = {
                        {n = G.UIT.T, config = {ref_table = saved, ref_value = 'label',
                            scale = 0.3, colour = G.C.UI.TEXT_LIGHT, maxw = 1.4}}}},
                    {n = G.UIT.R, config = {align = 'cm'}, nodes = {
                        {n = G.UIT.T, config = {ref_table = saved, ref_value = 'hint',
                            scale = 0.21, colour = G.C.UI.TEXT_LIGHT, maxw = 1.4}}}},
                }}
        end
        return unpack(result, 1, result.n)
    end
end
if Game and type(Game.update) == 'function' then
    local previous = Game.update
    Game.update = function(self, ...)
        local result = pack(previous(self, ...))
        mod.supereditions_deliver_weeping()
        return unpack(result, 1, result.n)
    end
end
