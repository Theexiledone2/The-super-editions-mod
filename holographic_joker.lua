local mod = SMODS.current_mod
local key = 'tag_supereditions_holographic_joker'
local rewarded_key = 'supereditions_holographic_rewarded'
local icon = G and G.P_TAGS and G.P_TAGS.tag_holo or {}
local processing

local function room()
    return G and G.GAME and G.jokers and G.jokers.cards and G.jokers.config
        and type(G.jokers.config.card_limit) == 'number'
        and #G.jokers.cards + (G.GAME.joker_buffer or 0) < G.jokers.config.card_limit
end
local function ready(ignore_space)
    if not (G and G.GAME) or (not ignore_space and not room())
        or not G.STATES or not G.STAGES or G.STAGE ~= G.STAGES.RUN
        or G.OVERLAY_MENU or G.screenwipe or (G.SETTINGS and G.SETTINGS.paused) then return false end
    if G.STATE ~= G.STATES.BLIND_SELECT and G.STATE ~= G.STATES.SHOP
        and G.STATE ~= G.STATES.SELECTING_HAND then return false end
    for _, lock in pairs(G.CONTROLLER and G.CONTROLLER.locks or {}) do
        if lock then return false end
    end
    return true
end

SMODS.Tag {
    key = 'holographic_joker',
    -- Use the native Holographic Tag icon until custom art is designed.
    atlas = icon.atlas or 'tags', pos = icon.pos or {x = 0, y = 0},
    prefix_config = {atlas = false},
    discovered = true, min_ante = 0, weight = 5,
    config = {type = 'immediate'},
    loc_txt = {
        name = 'Holographic Joker Tag',
        text = {
            'Gives a free {C:dark_edition}Holographic{} Joker',
            '{C:attention}5%{} chance for a {C:legendary}Legendary{}',
            '{s:0.8,C:inactive}(Includes Ruggiero; waits for room){}',
            '{s:0.8,C:inactive}(Deck and sticker edition rules apply){}',
        },
    },
    apply = function(self, tag, context)
        if context.type ~= 'immediate' and context.type ~= 'supereditions_holographic_retry' then return end
        tag.ability = tag.ability or {}
        -- A truthy result means this context is handled, not that the tag
        -- was consumed. Returning nil while waiting falls through to the
        -- native immediate-tag branch and strands its controller lock.
        if tag.triggered or processing then return true end
        if tag.ability[rewarded_key] then
            -- A save taken before removal may restore an already-paid tag.
            -- Retire its icon even if the delivered Joker filled the row.
            if not ready(true) then return true end
            tag.triggered = true
            tag:yep('+', G.C.PURPLE, function() return true end)
            return true
        end
        if not ready() then return true end
        local run = G.GAME
        processing = run
        local ok, err = pcall(function()
            local legendary = pseudorandom('supereditions_holographic_joker_legendary') < 0.05
            local card = SMODS.create_card {
                set = 'Joker', area = G.jokers, legendary = legendary,
                edition = 'e_holo', no_edition = true, skip_materialize = true,
                key_append = 'supereditions_holographic_joker_tag',
            }
            -- Recheck if a third-party creation hook filled the last slot.
            if G.GAME ~= run or not room() then card:remove(); return end
            SMODS.add_to_deck(card, {area = G.jokers})
            -- Commit before animation so copied tags cannot use the same slot
            -- and a save during the animation already includes the real Joker.
            tag.ability[rewarded_key], tag.triggered = true, true
            tag:yep('+', G.C.PURPLE, function()
                if G.GAME == run and not card.removed then card:start_materialize() end
                return true
            end)
        end)
        processing = nil
        if not ok then error(err, 0) end
        return true
    end,
}

function mod.supereditions_claim_waiting_holographic_tags()
    if processing or not ready(true) then return end
    local run = G.GAME
    for _, tag in ipairs(run.tags or {}) do
        if tag.key == key and not tag.triggered
            and ((tag.ability and tag.ability[rewarded_key]) or room()) then
            tag:apply_to_run({type = 'supereditions_holographic_retry'})
            if G.GAME ~= run then break end
        end
    end
end

-- Retry after native updates settle removals. Unclaimed tags use ordinary
-- saved Tag state; no permanent slot increase or busy-wait event is needed.
if Game and type(Game.update) == 'function' then
    local previous = Game.update
    local function pack(...) return {n = select('#', ...), ...} end
    Game.update = function(self, ...)
        local result = pack(previous(self, ...))
        mod.supereditions_claim_waiting_holographic_tags()
        return unpack(result, 1, result.n)
    end
end
