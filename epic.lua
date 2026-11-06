-- The installed framework supplies Rarity. Older registration-only fixtures
-- omit unrelated object classes, so they may still load the rest of the mod.
if SMODS.Rarity then
    SMODS.Rarity {
        key = 'epic', loc_txt = {name = 'Epic'},
        badge_colour = {0.36, 0.30, 0.78, 1},
        default_weight = 0.01, pools = {Joker = true},
        disable_if_empty = true,
    }
end
