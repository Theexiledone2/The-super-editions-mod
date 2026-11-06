local mod=SMODS.current_mod
if not mod then return end
local function pack(...)return {n=select('#',...),...}end
local fields={'hands','discards','hand_size','dollars','joker_slots','consumable_slots','play_limit','discard_limit'}
local labels={hands='Hands per round',discards='Discards per round',hand_size='Hand size',
    dollars='Cash',joker_slots='Joker slots',consumable_slots='Consumable slots',
    play_limit='Play selection',discard_limit='Discard selection'}
local function params()
    local out={};local p=G and G.GAME and G.GAME.starting_params or {}
    for _,key in ipairs(fields) do if type(p[key])=='number' then out[key]=p[key] end end
    local game=G and G.GAME or {};local resets=game.round_resets or {}
    if resets.hands~=nil then out.hands=resets.hands end
    if resets.discards~=nil then out.discards=resets.discards end
    if game.dollars~=nil then out.dollars=game.dollars end
    for key,area in pairs({hand_size=G and G.hand,joker_slots=G and G.jokers,consumable_slots=G and G.consumeables}) do
        if area.config and type(area.config.card_limit)=='number' then out[key]=area.config.card_limit end
    end
    return out
end
if Back and Back.apply_to_run then
    local previous=Back.apply_to_run
    Back.apply_to_run=function(self,...)
        local game=G and G.GAME;local before=params()
        local result=pack(previous(self,...))
        if game and G.GAME==game then
            local changes={};local after=params()
            for _,key in ipairs(fields) do
                if before[key]~=nil and after[key]~=nil and before[key]~=after[key] then
                    changes[#changes+1]={key=key,before=before[key],after=after[key]}
                end
            end
            game.supereditions_deck_stat_changes=changes
        end
        return unpack(result,1,result.n)
    end
end
if Game and Game.start_run then
    local previous=Game.start_run
    Game.start_run=function(self,...)
        local result=pack(previous(self,...))
        if G and G.GAME and not G.GAME.supereditions_starting_stats then
            G.GAME.supereditions_starting_stats=params()
        end
        return unpack(result,1,result.n)
    end
end
local function edition_counts(cards)
    local counts={foil=0,holo=0,polychrome=0,negative=0,none=0,other=0,total=0}
    for _,card in ipairs(cards or {}) do
        if not card.removed then
            counts.total=counts.total+1
            local edition=card.edition
            if not edition then counts.none=counts.none+1
            else
                local known=false
                for _,key in ipairs({'foil','holo','polychrome','negative'}) do
                    if edition[key] then counts[key]=counts[key]+1;known=true end
                end
                if not known then counts.other=counts.other+1 end
            end
        end
    end
    return counts
end
function mod.supereditions_deck_stats()
    local game=G and G.GAME or {};local back=game.selected_back
    local center=back and back.effect and back.effect.center
    return {
        name=center and center.name or back and back.name or 'Current deck',
        starting=game.supereditions_starting_stats,
        changes=game.supereditions_deck_stat_changes,
        current=params(),
        playing=edition_counts(G and G.playing_cards),
        jokers=edition_counts(G and G.jokers and G.jokers.cards),
        remaining=game.current_round or {},
    }
end
local function text_row(text,small)
    return {n=G.UIT.R,config={align='cm',padding=0.015},nodes={
        {n=G.UIT.T,config={text=text,scale=small and 0.29 or 0.34,colour=G.C.UI.TEXT_LIGHT}}}}
end
local function stats_tab()
    local data=mod.supereditions_deck_stats()
    local left={text_row('Stat: run start -> current',true)}
    local right={text_row('Playing cards: '..data.playing.total..'   Jokers: '..data.jokers.total)}
    for _,key in ipairs(fields) do
        local current=data.current[key]
        if current~=nil then
            local initial=data.starting and data.starting[key]
            local line=labels[key]..': '..(initial~=nil and tostring(initial)..' -> ' or '')..tostring(current)
            if key=='hands' and data.remaining.hands_left then line=line..' ('..data.remaining.hands_left..' left)' end
            if key=='discards' and data.remaining.discards_left then line=line..' ('..data.remaining.discards_left..' left)' end
            left[#left+1]=text_row(line,true)
        end
    end
    right[#right+1]=text_row('Editions: playing cards / Jokers',true)
    for _,pair in ipairs({{'foil','Foil'},{'holo','Holographic'},{'polychrome','Polychrome'},{'negative','Negative'}}) do
        right[#right+1]=text_row(pair[2]..': '..data.playing[pair[1]]..' / '..data.jokers[pair[1]],true)
    end
    right[#right+1]=text_row('Recorded starting deck changes',true)
    if not data.changes then right[#right+1]=text_row('Not recorded for this older run.',true)
    elseif #data.changes==0 then right[#right+1]=text_row('No numeric changes; see deck ability.',true)
    else
        for _,change in ipairs(data.changes) do
            right[#right+1]=text_row((labels[change.key] or change.key)..': '..change.before..' -> '..change.after,true)
        end
    end
    return {n=G.UIT.ROOT,config={align='cm',padding=0.08,colour=G.C.CLEAR},nodes={
        text_row(data.name),{n=G.UIT.R,config={align='tm',padding=0.12},nodes={
            {n=G.UIT.C,config={align='tm',padding=0.06},nodes=left},
            {n=G.UIT.C,config={align='tm',padding=0.06},nodes=right},
        }}
    }}
end
-- Scope the extra tab to Run Info; never add it to unrelated tabbed menus.
local depth=0
if G and G.FUNCS and G.FUNCS.run_info and create_tabs then
    local previous_info=G.FUNCS.run_info
    G.FUNCS.run_info=function(...)
        depth=depth+1
        local result=pack(pcall(previous_info,...));depth=depth-1
        if not result[1] then error(result[2],0) end
        return unpack(result,2,result.n)
    end
    local previous_tabs=create_tabs
    create_tabs=function(args,...)
        if depth>0 and mod.config and mod.config.deck_stats and type(args)=='table' and type(args.tabs)=='table' then
            local adjusted={};for k,v in pairs(args) do adjusted[k]=v end
            adjusted.tabs={};for i,v in ipairs(args.tabs) do adjusted.tabs[i]=v end
            adjusted.tabs[#adjusted.tabs+1]={label='Deck stats',tab_definition_function=stats_tab}
            args=adjusted
        end
        return previous_tabs(args,...)
    end
end
