local mod = SMODS.current_mod
local state_key, orange = 'supereditions_warrior', 'supereditions_orange'
local function pack(...) return {n = select('#', ...), ...} end
local function active()
    local back = G and G.GAME and G.GAME.selected_back
    return G and G.STAGES and G.STAGE == G.STAGES.RUN and back and back.effect
        and back.effect.config and back.effect.config.supereditions_warrior_deck == true
end
local function state()
    if not active() then return end
    G.GAME[state_key] = G.GAME[state_key] or {mode = 'warrior', last_round = -1}
    return G.GAME[state_key]
end
local function present(cards, card)
    for i, c in ipairs(cards or {}) do if c == card then return i end end
end
local function live(card)
    return type(card) == 'table' and not card.removed and not card.destroyed
        and not card.getting_sliced and card.playing_card ~= nil
end
local function refresh_back()
    local saved = state()
    if saved then G.GAME.selected_back.atlas = 'supereditions_'..saved.mode..'_deck' end
end
for _, a in ipairs({{'warrior_deck','warrior-deck.png',1085,1450},
    {'flowing_deck','flowing-deck.png',1084,1451}, {'orange_seal','orange-seal.png',1084,1451}}) do
    SMODS.Atlas {key = a[1], path = a[2], px = a[3], py = a[4],
        force_pixel = true, disable_mipmap = true}
end

SMODS.Seal {
    key = 'orange', atlas = 'orange_seal', pos = {x = 0, y = 0},
    badge_colour = {1, 0.45, 0.05, 1}, discovered = true,
    loc_txt = {label = 'Orange Seal', name = 'Orange Seal', text = {
        'When this card scores, give',
        'each {C:attention}unsealed adjacent{} played card',
        'a random {C:red}Red{}, {C:blue}Blue{}, {C:money}Gold{},',
        'or {C:purple}Purple{} Seal',
    }},
    -- Earned through Warrior Deck; do not change ordinary seal rolls.
    in_pool = function() return false end,
    calculate = function(self, card, context)
        if not (live(card) and not card.debuff and card.seal == orange
            and context.main_scoring and context.cardarea == G.play
            and not context.repetition and not context.repetition_only
            and not context.end_of_round and G.play) then return end
        local index = present(G.play.cards, card)
        if not index then return end
        local changed = false
        for _, at in ipairs({index - 1, index + 1}) do
            local target = G.play.cards[at]
            if live(target) and not target.seal then
                local seal = pseudorandom_element({'Red','Blue','Gold','Purple'},
                    pseudoseed('supereditions_orange_neighbor'))
                target:set_seal(seal, true, true)
                changed = changed or target.seal == seal
            end
        end
        if changed then return {message = 'Sealed!', colour = G.C.ORANGE, card = card} end
    end,
}

SMODS.Back {
    key = 'warrior', unlocked = true, discovered = true,
    atlas = 'warrior_deck', pos = {x = 0, y = 0},
    config = {supereditions_warrior_deck = true},
    loc_txt = {name = 'Warrior Deck', text = {
        'Alternate modes after each {C:attention}round{}',
        '{C:attention}Warrior:{} the card crossing {C:chips}100,000{}',
        'Chips X Mult gains an {C:attention}Orange Seal{}',
        '{C:attention}Flowing:{} unsealed cards drawn in',
        'the shop or shop packs gain {C:attention}Orange Seals{}',
        '{s:0.8,C:inactive}(Current mode: #1#){}',
    }},
    loc_vars = function()
        local saved = state()
        return {vars = {saved and saved.mode == 'flowing' and 'Flowing' or 'Warrior'}}
    end,
    calculate = function(self, back, context)
        local saved = state()
        if not saved then return end
        if context.round_eval and not context.game_over and not context.blueprint
            and not context.retrigger_joker and not context.retrigger_joker_check
            and not context.individual and not context.repetition and not context.post_trigger then
            local run = G.GAME
            if type(run.round) == 'number' and run.round > 0 and saved.last_round ~= run.round
                and run.blind and run.chips ~= nil and run.blind.chips ~= nil
                and run.chips >= run.blind.chips then
                saved.mode = saved.mode == 'warrior' and 'flowing' or 'warrior'
                saved.last_round = run.round
                refresh_back()
            end
        end
        if saved.mode == 'flowing' and type(context.other_drawn) == 'table'
            and G.STATES and (G.STATE == G.STATES.SHOP
                or G.GAME.PACK_INTERRUPT == G.STATES.SHOP) then
            for _, card in ipairs(context.other_drawn) do
                if live(card) and not card.seal and G.hand and present(G.hand.cards, card) then
                    card:set_seal(orange, true, true)
                end
            end
        end
    end,
}

local function projected_score()
    local N = mod.supereditions_numbers
    if N and N.active() then
        if not N.valid(hand_chips) or not N.valid(mult) then return end
        local result = N.mul(hand_chips, mult)
        if not N.nan(result) then return result end
    elseif type(hand_chips) == 'number' and type(mult) == 'number' then
        local result = hand_chips * mult
        if result == result then return result end
    end
end

-- Scope awards to the actual played-card scoring pass. Each card's native
-- score_card call finishes all its repetitions before the comparison.
local scoring
local main_scoring, score_card = rawget(SMODS, 'calculate_main_scoring'), rawget(SMODS, 'score_card')
if type(main_scoring) == 'function' and type(score_card) == 'function' then
    SMODS.calculate_main_scoring = function(context, scoring_hand, ...)
        local parent = scoring
        local saved = state()
        scoring = saved and saved.mode == 'warrior' and context.cardarea == G.play
            and scoring_hand and {run = G.GAME, awarded = false} or nil
        local result = pack(pcall(main_scoring, context, scoring_hand, ...))
        scoring = parent
        if not result[1] then error(result[2], 0) end
        return unpack(result, 2, result.n)
    end
    SMODS.score_card = function(card, context, ...)
        local frame = scoring
        local eligible = frame and not frame.awarded and G.GAME == frame.run
            and context.cardarea == G.play and live(card) and not card.debuff
            and not context.end_of_round and present(G.play.cards, card)
        local before = eligible and projected_score()
        local result = pack(score_card(card, context, ...))
        if eligible and scoring == frame and G.GAME == frame.run and active() then
            local after = projected_score()
            if before and after and before < 100000 and after >= 100000 then
                frame.awarded = true
                if live(card) then card:set_seal(orange, true, true) end
            end
        end
        return unpack(result, 1, result.n)
    end
end

-- Swap only runtime back sprites, never shared center definitions. Draw-time
-- refresh also repairs the atlas after Continue reconstructs existing cards.
if Card and type(Card.draw) == 'function' then
    local previous = Card.draw
    Card.draw = function(self, ...)
        local saved = state()
        local back = saved and G.GAME[self.back or 'selected_back']
        if back == (saved and G.GAME.selected_back) and saved and self.children
            and self.children.back and (self.playing_card or self.back == 'selected_back') then
            refresh_back()
            local atlas = G.ASSET_ATLAS and G.ASSET_ATLAS[G.GAME.selected_back.atlas]
            local sprite = self.children.back
            if atlas and sprite.atlas ~= atlas then
                sprite.atlas = atlas
                sprite:set_sprite_pos({x = 0, y = 0})
            end
        end
        return previous(self, ...)
    end
end
if Game and type(Game.update) == 'function' then
    local previous = Game.update
    Game.update = function(self, ...)
        local result = pack(previous(self, ...))
        refresh_back()
        return unpack(result, 1, result.n)
    end
end
