return {
    descriptions = {
        Joker = {
            j_supereditions_ruggiero = {
                name = 'Ruggiero',
                text = {
                    'Gains {X:mult,C:white}X#1#{} Mult for every',
                    '{C:attention}#2#{} points scored across',
                    '{C:attention}completed hands{}',
                    'Applies to subsequent hands',
                    'Resets when leaving a {C:attention}shop{}',
                    '{C:attention}Blueprint{} compatible with fewer',
                    'than {C:attention}20 hands{} remaining this round',
                    '{C:inactive}(Currently {X:mult,C:white}X#3#{C:inactive} Mult){}',
                },
            },
            j_supereditions_ruggiero_foil = {
                name = 'Ruggiero',
                text = {
                    '{X:chips,C:white}X#1#{} Chips after each',
                    '{C:dark_edition}Foil{} activation beyond',
                    'the first in each hand',
                    'Includes this Joker and',
                    '{C:attention}repeated{} Foil activations',
                },
            },
            j_supereditions_ruggiero_polychrome = {
                name = 'Ruggiero',
                text = {
                    'If {C:attention}Polychrome Flush House{} is played',
                    'and all {C:attention}5{} cards score:',
                    '{X:mult,C:white}^5{} Mult with fewer than {C:attention}5 Jokers{},',
                    'otherwise {C:attention}Squares{} Mult ({X:mult,C:white}^2{})',
                    'Activates {C:attention}first{} after card scoring,',
                    'before other Joker scoring effects',
                },
            },
            j_supereditions_ruggiero_negative = {
                name = 'Ruggiero',
                text = {
                    'When acquired, owned {C:attention}Jokers{}',
                    'take up {C:attention}0{} slots',
                    'If acquired alone, affects the',
                    'next {C:attention}5{} acquired Jokers instead',
                    'Keeps their existing editions',
                    'Only while this Joker is owned',
                    'and {C:dark_edition}Negative{}',
                    '{C:inactive}(Future grants: #1#){}',
                },
            },
            j_supereditions_ruggiero_other = {
                name = 'Ruggiero',
                text = {
                    "Only this edition's",
                    'standard bonus is active',
                },
            },
            j_supereditions_ruggiero_holo = {
                name = 'Ruggiero',
                text = {
                    'Each played {C:dark_edition}Holographic{} card',
                    'gives {X:mult,C:white}X#1#{} Mult when scored',
                    'Includes {C:attention}repeated{} card scoring',
                },
            },
            j_supereditions_the_foil_family = {
                name = 'The foil family',
                text = {
                    '{X:chips,C:white}X#1#{} Chips if exactly',
                    '{C:attention}#2#{} cards are played,',
                    'all {C:attention}#2#{} score and',
                    'all have {C:dark_edition}Foil{}',
                },
            },
            j_supereditions_foilmaker = {
                name = 'Foilmaker',
                text = {
                    'Gains {C:chips}+#1#{} Chips permanently',
                    'each time a played card scores',
                    '{C:dark_edition}Foil{} doubles the base gain',
                    '{C:inactive}(Currently {C:chips}+#2#{C:inactive} Chips){}',
                    'After scoring, multiply this',
                    "hand's final score by {X:chips,C:white}X#3#{}",
                    'once per {C:attention}#4#{} points',
                    'Counted {C:attention}before{} this boost',
                },
            },
            j_supereditions_shielding_jimbo = {
                name = 'Shielding jimbo',
                text = {
                    'Stores {C:chips}+#1#{} Chips for each',
                    'card drawn to hand',
                    'If your {C:attention}final hand{} would lose,',
                    'add all stored Chips directly',
                    'to the {C:chips}round score{}, then reset',
                    '{C:inactive}(Stored: {C:chips}#2#{C:inactive} Chips){}',
                    '{C:dark_edition}Foil{} replaces this ability',
                },
            },
            j_supereditions_shielding_jimbo_foil = {
                name = 'Shielding jimbo',
                text = {
                    'Gains {X:chips,C:white}X#1#{} Chips for each',
                    'card discarded this round',
                    'Applies on the {C:attention}final hand{}',
                    'Resets to {X:chips,C:white}X1{} at round end',
                    '{C:inactive}(Currently {X:chips,C:white}X#2#{C:inactive} Chips){}',
                    '{C:inactive}Replaces the reserve ability{}',
                },
            },
        },
        Other = {
            supereditions_shield_foil = {
                name = 'Foil ability',
                text = {
                    'With {C:dark_edition}Foil{}, each discarded',
                    'card adds {X:chips,C:white}X#1#{} Chips to',
                    'the {C:attention}final hand{} multiplier',
                    'Starts at {X:chips,C:white}X1{}; resets each round',
                    'Replaces the reserve ability',
                },
            },
        },
    },
    misc = {
        v_text = {
            ch_c_supereditions_inflation_ante = {'Start at {C:attention}Ante 39{}'},
            ch_c_supereditions_inflation_deck = {
                'Start with {C:attention}156 Lucky cards{}',
                '{C:spades}78 Spades{} and {C:hearts}78 Hearts{}',
            },
            ch_c_supereditions_inflation_win = {'Defeat the {C:attention}Ante 39 Boss Blind{} to win'},
            ch_c_supereditions_inflation_cash = {'Money always stays at {C:money}$0{}'},
        },
        v_dictionary = {
            a_supereditions_factory_gain = '+#1# Chips',
            a_supereditions_factory_boost = 'X#1# (#2# times)',
            a_supereditions_shield_store = '+#1# Stored',
            a_supereditions_shield_foil = 'X#1# Chips',
        },
        dictionary = {
            k_supereditions_ruggiero_square = '^2 Mult',
            k_supereditions_ruggiero_fifth = '^5 Mult',
            k_supereditions_shield_saved = 'Saved by Shielding jimbo',
        },
    },
}
