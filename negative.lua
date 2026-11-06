local mod = SMODS.current_mod
local flag = 'supereditions_negative_deck'
local creating_joker = false
local hand_key = 'supereditions_polychrome_flush_house'
local function run() return G and G.GAME and G.STAGES and G.STAGE == G.STAGES.RUN end
local function active()
    local back = run() and G.GAME.selected_back
    return back and back.effect and back.effect.config and back.effect.config[flag] == true
end
local function packed(...) return {n=select('#',...),...} end
local function has_ruggiero()
    for _, card in ipairs(G and G.jokers and G.jokers.cards or {}) do
        local edition = card.edition
        if card.config and card.config.center and card.config.center.key == 'j_supereditions_ruggiero'
            and edition and (edition.polychrome or edition.key == 'e_polychrome')
            and not card.removed and not card.getting_sliced then return true end
    end
    return false
end

mod.optional_features = mod.optional_features or {}
mod.optional_features.object_weights = true
SMODS.Atlas {key = 'negative_deck', path = 'negative-deck.png',
    px = 1084, py = 1451, force_pixel = true, disable_mipmap = true}
SMODS.Back {
    key = 'negative', unlocked = false, discovered = true,
    atlas = 'negative_deck', pos = {x=0,y=0},
    config = {[flag]=true},
    loc_txt = {
        name = 'Negative Deck',
        text = {
            '{C:green}20%{} chance to make the final',
            'played hand of each Blind {C:dark_edition}Negative{}',
            'Joker {C:dark_edition}Negative{} weight and',
            '{C:dark_edition}Negative Pack{} weight are {C:attention}10X{}',
            'Blinds require {C:attention}3X{} the score',
        },
        unlock = {
            'Play a {C:dark_edition}Polychrome Flush House{}',
            'while owning {C:dark_edition}Polychrome{} {C:legendary}Ruggiero{}',
        },
    },
    check_for_unlock = function(self, args)
        return args and args.type == 'supereditions_negative_deck_unlock'
            and args.hand == hand_key and run() and has_ruggiero() or false
    end,
    -- Starting cards use the ordinary deck; no guaranteed editions.
    apply = function() end,
}

-- Unlock on any deck, including when a Boss debuffs the played hand. The
-- framework still owns profile persistence and seeded/challenge unlock rules.
local calculate = mod.calculate
mod.calculate = function(self, context)
    local result = calculate and packed(calculate(self,context)) or {n=0}
    if run() and (context.before or context.debuffed_hand) and not context.blueprint
        and not context.retrigger_joker and context.scoring_name == hand_key
        and has_ruggiero() and check_for_unlock then
        check_for_unlock({type='supereditions_negative_deck_unlock',hand=hand_key})
    end
    if active() and context.modify_weights and type(context.pool)=='table' then
        local seen={}
        for _,entry in pairs(context.pool) do
            local pack = entry.key == 'p_supereditions_negative_normal'
                or entry.key == 'p_supereditions_negative_jumbo'
                or entry.key == 'p_supereditions_negative_mega'
            if not seen[entry] and (pack or (creating_joker and entry.key == 'e_negative'))
                and type(entry.weight)=='number' then
                seen[entry]=true
                entry.weight=entry.weight*10
            end
        end
    end
    if active() and context.end_of_round and not (context.individual or context.repetition
        or context.repetition_only or context.blueprint or context.retrigger_joker
        or context.retrigger_joker_check or context.post_trigger) then
        local cards = context.full_hand or (SMODS.last_hand and SMODS.last_hand.full_hand) or {}
        local round = G.GAME.round or 0
        if #cards > 0 and G.GAME.supereditions_negative_final_round ~= round then
            G.GAME.supereditions_negative_final_round = round
            if pseudorandom('supereditions_negative_final_hand') < 0.2 then
                local seen = {}
                for _, card in ipairs(cards) do
                    if type(card) == 'table' and not seen[card] and not card.removed
                        and not card.destroyed and SMODS.is_playing_card(card) then
                        seen[card] = true
                        card:set_edition('e_negative', true, true)
                    end
                end
            end
        end
    end
    return unpack(result,1,result.n)
end

-- Native and framework card creation both reach this public entry point.
-- Scope the Negative weight to Joker creation. Overall edition chance is unchanged.
if create_card then
    local previous = create_card
    create_card = function(set,...)
        local args=packed(...)
        local forced=G and G.P_CENTERS and G.P_CENTERS[args[6]]
        local earlier=creating_joker;creating_joker=(forced and forced.set or set)=='Joker'
        local result=packed(pcall(previous,set,unpack(args,1,args.n)));creating_joker=earlier
        if not result[1] then error(result[2],0) end
        return unpack(result,2,result.n)
    end
end
-- Stock scaling enters the global API; custom scaling can enter SMODS.
-- A nested call must not multiply twice. Preserve the complete return tuple.
local depth=0
local function wrap(previous)
    return function(...)
        local apply=active() and depth==0
        depth=depth+1
        local result=packed(pcall(previous,...));depth=depth-1
        if not result[1] then error(result[2],0) end
        if apply then
            local N=mod.supereditions_numbers
            result[2]=N and N.active() and N.mul(result[2],3) or result[2]*3
        end
        return unpack(result,2,result.n)
    end
end
if get_blind_amount then get_blind_amount=wrap(get_blind_amount) end
if SMODS.get_blind_amount then SMODS.get_blind_amount=wrap(SMODS.get_blind_amount) end
