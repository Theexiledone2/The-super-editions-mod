-- The super editions mod: Foil Packs and three edition-themed Jokers.
assert(SMODS and SMODS.Booster and SMODS.Joker and SMODS.Atlas and SMODS.Stake and SMODS.Back and SMODS.Tag and SMODS.load_file,
    'The super editions mod requires Steamodded 26.829.0 or newer.')

-- Install the number boundary before deck/Joker wrappers are registered.
assert(SMODS.load_file('support/extended_scores.lua'))()
assert(SMODS.load_file('support/overlay_scale.lua'))()

-- Preserve the PNG at its original resolution. The atlas contains
-- one complete sprite; the game's usual booster dimensions control display.
SMODS.Atlas {
    key = 'foil_pack',
    path = 'foil-pack.png',
    px = 1084,
    py = 1451,
    force_pixel = true,
    disable_mipmap = true,
}

assert(SMODS.load_file('support/edition_pack_pools.lua'))()
assert(SMODS.load_file('packs/foil.lua'))()
assert(SMODS.load_file('jokers/shielding_jimbo.lua'))()
assert(SMODS.load_file('jokers/foilmaker.lua'))()
assert(SMODS.load_file('jokers/the_foil_family.lua'))()
assert(SMODS.load_file('stakes/foil.lua'))()

assert(SMODS.load_file('decks/foil.lua'))()

assert(SMODS.load_file('tags/foil_pack.lua'))()

assert(SMODS.load_file('support/shield_summon_pin.lua'))()
SMODS.Atlas {
    key = 'shield_summon_tag',
    path = 'shield-summon-tag.png',
    px = 1254,
    py = 1254,
    force_pixel = true,
    disable_mipmap = true,
}

assert(SMODS.load_file('tags/shield_summon.lua'))()

assert(SMODS.PokerHand and SMODS.Consumable, 'Steamodded poker hands and consumables are required.')
SMODS.Atlas {
    key = 'meteor',
    path = 'meteor.png',
    px = 1085,
    py = 1450,
    force_pixel = true,
    disable_mipmap = true,
}
SMODS.Atlas {
    key = 'argent',
    path = 'argent.png',
    px = 1084,
    py = 1451,
    force_pixel = true,
    disable_mipmap = true,
}
assert(SMODS.load_file('hands/flush_four.lua'))()
assert(SMODS.load_file('consumables/foil_planets.lua'))()

assert(SMODS.Sticker, 'Steamodded sticker support is required.')
assert(SMODS.load_file('support/temporary_foil.lua'))()
SMODS.Atlas {
    key = 'renting_troubles',
    path = 'renting-troubles.png',
    px = 1084,
    py = 1451,
    force_pixel = true,
    disable_mipmap = true,
}
assert(SMODS.load_file('consumables/foil_tarot.lua'))()

SMODS.Atlas {
    key = 'rust',
    path = 'rust.png',
    px = 1085,
    py = 1450,
    force_pixel = true,
    disable_mipmap = true,
}
assert(SMODS.load_file('consumables/rust.lua'))()

-- Ruggiero's artwork/rendering is prepared before his ability is designed.
assert(SMODS.load_file('support/ruggiero_visuals.lua'))()

assert(SMODS.load_file('jokers/ruggiero.lua'))()

assert(SMODS.load_file('packs/polychrome.lua'))()

assert(SMODS.load_file('packs/polychrome_jumbo.lua'))()

assert(SMODS.load_file('packs/polychrome_mega.lua'))()

assert(SMODS.load_file('jokers/pollinator.lua'))()

assert(SMODS.load_file('jokers/poli_faker.lua'))()
assert(SMODS.load_file('jokers/forest_protector.lua'))()

assert(SMODS.load_file('tags/polychrome_pack.lua'))()
assert(SMODS.load_file('tags/polychromic.lua'))()
assert(SMODS.load_file('support/gum_editions.lua'))()
assert(SMODS.load_file('support/polychrome_sticker.lua'))()
assert(SMODS.load_file('stakes/polychrome.lua'))()

assert(SMODS.load_file('decks/polychrome.lua'))()

assert(SMODS.load_file('support/ruggiero_polychrome.lua'))()

assert(SMODS.load_file('support/polychrome_consumables.lua'))()
assert(SMODS.load_file('support/consumable_atlases.lua'))()
assert(SMODS.load_file('consumables/polychrome.lua'))()

assert(SMODS.load_file('tags/triple.lua'))()
assert(SMODS.load_file('support/chatplays.lua'))()

assert(SMODS.load_file('packs/holographic.lua'))()

assert(SMODS.load_file('support/edition_pack_weights.lua'))()

assert(SMODS.load_file('jokers/the_phone.lua'))()

assert(SMODS.load_file('support/scalper.lua'))()
assert(SMODS.load_file('jokers/scalper.lua'))()

assert(SMODS.load_file('jokers/one_of_one.lua'))()

assert(SMODS.load_file('support/holographic_stake.lua'))()
assert(SMODS.load_file('stakes/holographic.lua'))()

assert(SMODS.load_file('packs/holographic_mega.lua'))()
assert(SMODS.load_file('support/holographic_tag_weights.lua'))()
assert(SMODS.load_file('tags/holographic_pack.lua'))()
assert(SMODS.load_file('tags/holographic_joker.lua'))()

assert(SMODS.load_file('decks/holographic.lua'))()

assert(SMODS.load_file('packs/holographic_jumbo.lua'))()

assert(SMODS.load_file('consumables/tarnished.lua'))()

assert(SMODS.load_file('consumables/the_shark.lua'))()

assert(SMODS.load_file('hands/polychrome_flush_house.lua'))()
assert(SMODS.load_file('consumables/blue_jupiter.lua'))()

assert(SMODS.load_file('packs/negative.lua'))()

assert(SMODS.load_file('support/ruggiero_negative.lua'))()

assert(SMODS.load_file('support/extended_hands.lua'))()
assert(SMODS.load_file('hands/investor.lua'))()
assert(SMODS.load_file('jokers/investor.lua'))()

assert(SMODS.load_file('rarities/epic.lua'))()
assert(SMODS.load_file('jokers/factorial.lua'))()

assert(SMODS.load_file('support/gum.lua'))()
assert(SMODS.load_file('jokers/gum.lua'))()

assert(SMODS.load_file('jokers/infinity.lua'))()
assert(SMODS.load_file('support/infinity_counter.lua'))()

assert(SMODS.load_file('support/martyr.lua'))()
assert(SMODS.load_file('jokers/martyr.lua'))()

assert(SMODS.load_file('jokers/the_treasure.lua'))()

assert(SMODS.load_file('jokers/mayor.lua'))()

assert(SMODS.load_file('support/negative_sticker.lua'))()
assert(SMODS.load_file('support/negative_selection.lua'))()
assert(SMODS.load_file('stakes/negative.lua'))()

assert(SMODS.load_file('support/flipside.lua'))()
assert(SMODS.load_file('jokers/flipside.lua'))()

assert(SMODS.load_file('support/negative_tag_atlases.lua'))()
assert(SMODS.load_file('tags/negative_pack.lua'))()
assert(SMODS.load_file('tags/ruggiero.lua'))()
assert(SMODS.load_file('support/ruggiero_packs.lua'))()

assert(SMODS.load_file('support/settings.lua'))()
assert(SMODS.load_file('support/speedy_scoring.lua'))()
assert(SMODS.load_file('support/seed_privacy.lua'))()
assert(SMODS.load_file('support/deck_stats.lua'))()

assert(SMODS.load_file('decks/negative.lua'))()
assert(SMODS.load_file('consumables/paralellize.lua'))()
assert(SMODS.load_file('consumables/parallel_universe_money.lua'))()
assert(SMODS.load_file('consumables/solar_system.lua'))()
assert(SMODS.load_file('jokers/dollar_bill.lua'))()

assert(SMODS.load_file('support/sparta.lua'))()
assert(SMODS.load_file('jokers/sparta.lua'))()

assert(SMODS.load_file('support/philosophy.lua'))()
assert(SMODS.load_file('jokers/philosophy.lua'))()

assert(SMODS.load_file('support/stop_sign.lua'))()
assert(SMODS.load_file('jokers/stop_sign.lua'))()

assert(SMODS.load_file('support/trash_can.lua'))()
assert(SMODS.load_file('jokers/trash_can.lua'))()
assert(SMODS.load_file('support/arcade_machine.lua'))()
assert(SMODS.load_file('jokers/arcade_machine.lua'))()

assert(SMODS.load_file('packs/negative_jumbo.lua'))()

assert(SMODS.load_file('support/flipside_negative.lua'))()
assert(SMODS.load_file('packs/negative_mega.lua'))()

assert(SMODS.load_file('challenges/inflation.lua'))()

assert(SMODS.load_file('jokers/jack_of_red_trades.lua'))()
assert(SMODS.load_file('jokers/stamp_of_approval.lua'))()

assert(SMODS.load_file('consumables/roulette.lua'))()

assert(SMODS.load_file('support/polychrome_start.lua'))()

assert(SMODS.load_file('decks/weeping.lua'))()

assert(SMODS.load_file('decks/warrior.lua'))()
