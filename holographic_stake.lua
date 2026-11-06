-- Keep the current round slot. Steamodded 26.829+ supports any blind
-- definition in Small/Big and uses the slot for defeat/Ante progression.
-- Do not set G.GAME.blind.boss or advance blind_on_deck ourselves.
local state_key = 'supereditions_holographic_blinds'
local mod = SMODS.current_mod
local busy

local function active()
    return G and G.GAME and G.GAME.modifiers
        and G.GAME.modifiers.supereditions_holographic_stake
end

local function converted(slot)
    if not active() then return false end
    local run = G.GAME
    local state = run[state_key]
    return state and run.round_resets and state.ante == run.round_resets.ante
        and state.slots and state.slots[slot] ~= nil
end

-- Ante can repeat after Hieroglyph/Petroglyph. A fresh native blind schedule
-- must clear old conversions even when its numerical Ante matches the last one.
if type(rawget(SMODS, 'reset_blind_choices')) == 'function' then
    local previous = SMODS.reset_blind_choices
    local function pack(...) return {n = select('#', ...), ...} end
    SMODS.reset_blind_choices = function(choices, ...)
        local result = pack(previous(choices, ...))
        if active() and G.GAME.round_resets and choices == G.GAME.round_resets.blind_choices then
            G.GAME[state_key] = nil
        end
        return unpack(result, 1, result.n)
    end
end

-- Removing the tag panel also removes its Skip button, for mouse, controller
-- and Chat Plays. No global blind prototype is made unskippable.
if type(create_UIBox_blind_tag) == 'function' then
    local previous = create_UIBox_blind_tag
    function create_UIBox_blind_tag(slot, ...)
        if converted(slot) then return nil end
        return previous(slot, ...)
    end
end

local function contains(node, target, seen)
    if node == target then return true end
    if type(node) ~= 'table' then return false end
    seen = seen or {}
    if seen[node] then return false end
    seen[node] = true
    for _, field in ipairs({'UIRoot', 'children', 'nodes'}) do
        local branch = rawget(node, field)
        if type(branch) == 'table' then
            if contains(branch, target, seen) then return true end
            for _, child in pairs(branch) do
                if contains(child, target, seen) then return true end
            end
        end
    end
    local config = rawget(node, 'config')
    return config and contains(config.object, target, seen) or false
end

local function ready(e)
    if busy == G.GAME or not G.STATES or G.STATE ~= G.STATES.BLIND_SELECT
        or G.OVERLAY_MENU or G.screenwipe or (G.SETTINGS and G.SETTINGS.paused)
        or not e or not e.config or e.config.button ~= 'skip_blind'
        or not contains(G.blind_select, e) then return end
    for _, lock in pairs(G.CONTROLLER and G.CONTROLLER.locks or {}) do
        if lock then return end
    end
    local run = G.GAME
    local slot, resets = run.blind_on_deck, run.round_resets
    if (slot ~= 'Small' and slot ~= 'Big') or not resets or converted(slot)
        or not resets.blind_states or resets.blind_states[slot] ~= 'Select'
        or not resets.blind_choices or not resets.blind_tags then return end
    local key, tag = resets.blind_choices[slot], resets.blind_tags[slot]
    local blind = G.P_BLINDS and G.P_BLINDS[key]
    if not blind or blind.unskippable or not (G.P_TAGS and G.P_TAGS[tag]) then return end
    return slot, key, tag
end

local function refresh_choices()
    local old = G.blind_select
    local config = {}
    -- Preserve native placement and object references, without aliasing the
    -- mutable offset table between the old and replacement UIBoxes.
    for k, v in pairs(old.config or {}) do config[k] = v end
    if type(config.offset) == 'table' then
        local offset = {}; for k, v in pairs(config.offset) do offset[k] = v end
        config.offset = offset
    end
    local replacement = UIBox {definition = create_UIBox_blind_select(), config = config}
    old:remove()
    G.blind_select = replacement
end

local function resolve_rewards(run, release)
    -- add_tag registers/copies tags, but the native skip callback separately
    -- dispatches immediate rewards. Complete that phase before opening packs.
    G.E_MANAGER:add_event(Event({trigger = 'after', delay = 0,
        func = function()
            if G.GAME ~= run then release(); return true end
            local ok, err = pcall(function()
                for _, tag in ipairs(run.tags or {}) do
                    tag:apply_to_run({type = 'immediate'})
                end
            end)
            if not ok then release(); error(err, 0) end
            G.E_MANAGER:add_event(Event({trigger = 'after', delay = 0,
                func = function()
                    if G.GAME ~= run then release(); return true end
                    -- Reward animations have settled. Release only our lock;
                    -- gifts that need a slot can remain pending without it.
                    release()
                    if mod.supereditions_claim_waiting_holographic_tags then
                        mod.supereditions_claim_waiting_holographic_tags()
                    end
                    for _, tag in ipairs(run.tags or {}) do
                        if tag:apply_to_run({type = 'new_blind_choice'}) then
                            -- Charges do not open a pack; apply both copies.
                            if tag.key ~= 'tag_supereditions_polychromic' then break end
                        end
                    end
                    G.E_MANAGER:add_event(Event({trigger = 'after', delay = 0.2,
                        func = function()
                            if G.GAME == run then save_run() end
                            return true
                        end,
                    }))
                    return true
                end,
            }))
            return true
        end,
    }))
end

if G and G.FUNCS and type(G.FUNCS.skip_blind) == 'function' then
    local previous = G.FUNCS.skip_blind
    G.FUNCS.skip_blind = function(e, ...)
        if not active() then return previous(e, ...) end
        if mod and mod.supereditions_philosophy_blocks
            and mod.supereditions_philosophy_blocks('holographic') then
            -- Previously converted bosses keep their no-skip protection.
            -- Only a new ordinary skip follows the native one-tag behavior.
            if converted(G.GAME.blind_on_deck) then return false end
            return previous(e, ...)
        end
        local slot, original, tag_key = ready(e)
        if not slot then return false end
        local run, resets = G.GAME, G.GAME.round_resets
        busy = run
        local locks = G.CONTROLLER and G.CONTROLLER.locks
        if locks then locks.blind_select = true end
        local function release()
            if busy == run then busy = nil end
            if locks then locks.blind_select = nil end
        end
        local ok, result = pcall(function()
            -- Omitted type is the public default: boss. This also preserves
            -- the existing Foil Deck's finisher-selection wrapper.
            local boss = SMODS.get_new_blind()
            if not (G.P_BLINDS[boss] and G.P_BLINDS[boss].boss) then
                error('Holographic Stake: the blind selector did not return a Boss Blind.')
            end
            local rewards = {Tag(tag_key, nil, slot), Tag(tag_key, nil, slot)}
            local orbital = run.orbital_choices and run.orbital_choices[resets.ante]
            if tag_key == 'tag_orbital' and orbital then
                for _, tag in ipairs(rewards) do tag.orbital_hand = orbital[slot] end
            end
            local state = run[state_key]
            if not state or state.ante ~= resets.ante then
                state = {ante = resets.ante, slots = {}}
                run[state_key] = state
            end
            local record = {original = original, boss = boss, tag = tag_key}
            state.slots[slot] = record
            resets.blind_choices[slot] = boss
            -- Rebuild first, before tag animations can open a pack. The boss
            -- must remain selectable, and the old button must not survive.
            local rebuilt, failure = pcall(refresh_choices)
            if not rebuilt then
                state.slots[slot] = nil
                resets.blind_choices[slot] = original
                error(failure, 0)
            end
            for _, tag in ipairs(rewards) do add_tag(tag) end
            resolve_rewards(run, release)
            -- This is a replacement, not a completed skip: native skip
            -- counters/contexts and round/Ante advancement are left alone.
            return true
        end)
        if not ok then release(); error(result, 0) end
        return result
    end
end
