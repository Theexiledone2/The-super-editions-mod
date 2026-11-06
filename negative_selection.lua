local function packed(...) return {n = select('#', ...), ...} end
local text_game, text_play, text_discard
local function sync()
    local game = G and G.GAME
    if not (game and game.supereditions_negative_stake_applied
        and game.starting_params and G.hand and G.hand.config) then return end
    local params = game.starting_params
    local limit = math.max(1, params.play_limit, params.discard_limit)
    -- The native API floors highlight capacity at five. On Negative Stake,
    -- selection itself must respect the lower limits, not only the buttons.
    G.hand.config.highlighted_limit = limit
    if #(G.hand.highlighted or {}) > limit and G.hand.unhighlight_all then
        G.hand:unhighlight_all()
    end
    if text_game ~= game or text_play ~= params.play_limit or text_discard ~= params.discard_limit then
        text_game, text_play, text_discard = game, params.play_limit, params.discard_limit
        if SMODS.update_hand_limit_text then SMODS.update_hand_limit_text(true, true) end
    end
end
for _, name in ipairs({'change_play_limit', 'change_discard_limit'}) do
    if SMODS[name] then
        local previous = SMODS[name]
        SMODS[name] = function(...)
            local result = packed(previous(...)); sync(); return unpack(result, 1, result.n)
        end
    end
end
if CardArea and CardArea.add_to_highlighted then
    local previous = CardArea.add_to_highlighted
    CardArea.add_to_highlighted = function(self, ...)
        if G and self == G.hand then sync() end
        return previous(self, ...)
    end
end
if Game and Game.update then
    local previous = Game.update
    Game.update = function(self, ...)
        local result = packed(previous(self, ...)); sync(); return unpack(result, 1, result.n)
    end
end
