local mod = SMODS.current_mod
if not mod then return end
mod.config = mod.config or {}
local config = mod.config
if type(config.speedy_scoring) ~= 'boolean' then config.speedy_scoring = true end
if config.speedy_scoring_rate ~= 1 and config.speedy_scoring_rate ~= 2 then
    config.speedy_scoring_rate = 1
end
if config.seed_visibility ~= 1 and config.seed_visibility ~= 2 then config.seed_visibility = 1 end
if type(config.deck_stats) ~= 'boolean' then config.deck_stats = true end
if type(config.extended_scores) ~= 'boolean' then config.extended_scores = true end

-- Use Steamodded's own configuration storage; never store user settings in saves.
if G and G.FUNCS then
    G.FUNCS.supereditions_speed_rate = function(args)
        if args and (args.to_key == 1 or args.to_key == 2) then
            config.speedy_scoring_rate = args.to_key
            if SMODS.save_mod_config then SMODS.save_mod_config(mod) end
        end
    end
    G.FUNCS.supereditions_seed_visibility = function(args)
        if args and (args.to_key == 1 or args.to_key == 2) then
            config.seed_visibility = args.to_key
            if SMODS.save_mod_config then SMODS.save_mod_config(mod) end
        end
    end
end

mod.config_tab = function()
    return {n = G.UIT.ROOT, config = {align = 'cm', padding = 0.15,
        colour = G.C.CLEAR}, nodes = {
        create_toggle({label = 'Speedy Scoring', ref_table = config,
            ref_value = 'speedy_scoring',
            info = {'Accelerate scoring animations each hand.',
                'Every scoring effect still resolves.'}}),
        create_option_cycle({label = 'Scoring acceleration', w = 5,
            options = {'Half (+5% per effect)', 'Full (+10% per effect)'},
            current_option = config.speedy_scoring_rate,
            opt_callback = 'supereditions_speed_rate'}),
        create_option_cycle({label = 'Reveal run seed', w = 5,
            options = {'Only after losing', 'After Ante 8 or losing'},
            current_option = config.seed_visibility,
            opt_callback = 'supereditions_seed_visibility'}),
        create_toggle({label = 'Deck stats in Run Info', ref_table = config,
            ref_value = 'deck_stats', info = {'Show current limits, deck composition,',
                'and recorded starting deck changes.'}}),
        create_toggle({label = 'Extended scores (new runs)', ref_table = config,
            ref_value = 'extended_scores', info = {'Count up to about 2e1000, then Infinity.',
                'Requires LuaJIT; the choice is saved with each run.'}}),
    }}
end
