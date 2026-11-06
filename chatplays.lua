local mod = SMODS.current_mod

-- Optional public policy queried by Chat Plays 3.6.6. It neither loads Chat
-- Plays nor changes its settings, and works regardless of which mod loads first.
function mod.chatplays_can_receive_negative(card)
    if not card then return false end
    local center = card.config and card.config.center or {}
    local ability = card.ability or {}
    local set = center.set or ability.set
    local joker = set == 'Joker'
    if joker and ability.supereditions_polychrome then return false end
    local back = G and G.GAME and G.GAME.selected_back
    local active = back and back.effect and back.effect.config
        and back.effect.config.supereditions_polychrome_deck == true
        and G.STAGES and G.STAGE == G.STAGES.RUN
    if not active then return true end
    if center.consumeable or ability.consumeable
        or (SMODS.ConsumableTypes and SMODS.ConsumableTypes[set]) then return true end
    return not (joker or SMODS.is_playing_card(card))
end

function mod.chatplays_can_use_card(card)
    local center = card and card.config and card.config.center
    if not center or type(center.key) ~= 'string'
        or not center.key:match('^c_supereditions_') then return true end
    if type(center.can_use) == 'function' then return center:can_use(card) end
    return true
end
