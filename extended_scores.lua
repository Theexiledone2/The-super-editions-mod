local mod=SMODS.current_mod
if not mod then return end
local N=assert(SMODS.load_file('support/score_numbers.lua'))()
mod.supereditions_numbers=N
local pending
local function pack(...)return {n=select('#',...),...}end
function N.active()
    if not N.available then return false end
    if pending~=nil then return pending end
    return G and G.GAME and G.GAME.supereditions_extended_scores==true or false
end
if not N.available then
    if Game and Game.start_run then
        local previous=Game.start_run
        Game.start_run=function(self,args,...)
            local saved=type(args)=='table' and type(args.savetext)=='table' and args.savetext.GAME
            if saved and saved.supereditions_extended_scores then
                error('This saved run requires Super Editions extended scores: '..tostring(N.reason),0)
            end
            return previous(self,args,...)
        end
    end
    return
end

-- These wrappers change behavior only for this module's cdata, never ordinary
-- native numbers or another mod's value type. Keep small-value arithmetic native.
for key,handler in pairs({floor=N.floor,abs=N.abs,sqrt=function(x)return N.pow(x,0.5)end,
    ceil=function(x)return -N.floor(-x)end,log10=N.log10}) do
    local previous=math[key]
    if previous then math[key]=function(x,...)if N.is(x) then return handler(x,...) end;return previous(x,...)end end
end
for _,key in ipairs({'min','max'}) do
    local previous=math[key]
    math[key]=function(...)
        local args=pack(...);local extended=false
        for i=1,args.n do if N.is(args[i]) then extended=true;break end end
        if not extended then return previous(...) end
        local best=args[1]
        for i=2,args.n do
            if key=='min' and args[i]<best or key=='max' and args[i]>best then best=args[i] end
        end
        return best
    end
end
do
    local previous=math.log
    math.log=function(x,base)
        if N.is(x) or N.is(base) then
            return N.log10(x)/(base and N.log10(base) or math.log10(math.exp(1)))
        end
        if base~=nil then return previous(x,base) end
        return previous(x)
    end
end
if math.pow then
    local previous=math.pow
    math.pow=function(x,y)if N.is(x) or N.is(y) then return N.pow(x,y) end;return previous(x,y)end
end
if number_format then
    local previous=number_format
    number_format=function(value,...)
        if N.is(value) then return N.format(value) end
        if N.active() and type(value)=='number' and (value~=value or math.abs(value)==math.huge) then
            return value~=value and 'NaN' or value<0 and '-Infinity' or 'Infinity'
        end
        return previous(value,...)
    end
end

for _,name in ipairs({'STR_PACK','serialize'}) do
    local previous=rawget(_G,name)
    if previous then
        local depth=0
        _G[name]=function(value,...)
            if depth==0 then value=N.encode_tree(value) end
            depth=depth+1
            local result=pack(pcall(previous,value,...));depth=depth-1
            if not result[1] then error(result[2],0) end
            return unpack(result,2,result.n)
        end
    end
end
-- The game queues G.ARGS.save_run before this wrapper returns. Replacing
-- G.culled_table alone leaves that queue pointing at the unencoded snapshot.
-- Update both references without changing live game objects or their scores.
if save_run then
    local previous=save_run
    save_run=function(...)
        local result=pack(previous(...))
        if G then
            local seen={}
            if type(G.culled_table)=='table' then
                G.culled_table=N.encode_tree(G.culled_table,seen)
            end
            if G.ARGS and type(G.ARGS.save_run)=='table' then
                G.ARGS.save_run=N.encode_tree(G.ARGS.save_run,seen)
            end
        end
        return unpack(result,1,result.n)
    end
end
if STR_UNPACK then
    local previous=STR_UNPACK
    STR_UNPACK=function(...)
        local result=pack(previous(...));result[1]=N.decode_tree(result[1])
        return unpack(result,1,result.n)
    end
end
-- Balatro reads settings.jkr AND calls Game:load_profile before Steamodded
-- loads this module. The STR_UNPACK hook only covers later reads, so restore
-- both already-loaded roots. Preserve the settings/profile tables and all
-- their existing records; only our encoded number markers are replaced.
if G then
    if type(G.SETTINGS)=='table' then N.decode_tree(G.SETTINGS) end
    if type(G.PROFILES)=='table' then N.decode_tree(G.PROFILES) end
end
if Game and Game.start_run then
    local previous=Game.start_run
    Game.start_run=function(self,args,...)
        local saved=type(args)=='table' and type(args.savetext)=='table' and args.savetext.GAME
        local requested
        if saved then requested=saved.supereditions_extended_scores==true end
        if requested==nil then requested=not mod.config or mod.config.extended_scores~=false end
        if requested and type(rawget(_G,'to_big'))=='function' then
            error('Extended scores cannot start alongside another large-number system. Disable Extended scores for a new run.',0)
        end
        local earlier=pending;pending=requested
        if args and args.savetext then N.decode_tree(args.savetext) end
        local result=pack(pcall(previous,self,args,...));pending=earlier
        if not result[1] then error(result[2],0) end
        if G and G.GAME then G.GAME.supereditions_extended_scores=requested end
        return unpack(result,2,result.n)
    end
end

-- Hook the framework boundary before edition decks wrap it. Their existing
-- ante remapping and modifiers continue to compose around this implementation.
local function extend_blind_amount(previous)
    return function(ante,...)
        local amount=previous(ante,...)
        if not N.active() or type(ante)~='number' or ante~=math.floor(ante) then return amount end
        if N.valid(amount) and not N.nan(amount) and amount<math.huge then return N.from(amount) end
        if ante<=8 then return amount end
        -- Continue the framework's documented endless curve in scientific
        -- arithmetic. Obtain its first two terms through its own public API.
        local seventh,eighth=previous(7,...),previous(8,...)
        if not N.valid(seventh) or not N.valid(eighth) or seventh<=0 or eighth<=0 then return amount end
        local distance=ante-8
        local growth=N.add(N.div(eighth,seventh),N.pow(0.75*distance,1+0.2*distance))
        local extended=N.mul(eighth,N.pow(growth,distance))
        if extended==math.huge then return extended end
        local unit=N.pow(10,math.floor(N.log10(extended))-1)
        return N.sub(extended,N.mod(extended,unit))
    end
end
if rawget(SMODS,'get_blind_amount') then SMODS.get_blind_amount=extend_blind_amount(SMODS.get_blind_amount) end
if get_blind_amount then get_blind_amount=extend_blind_amount(get_blind_amount) end
local parameter_class=rawget(SMODS,'Scoring_Parameter')
if type(parameter_class)=='table' and parameter_class.modify then
    local previous=parameter_class.modify
    parameter_class.modify=function(self,amount,...)
        if N.active() then
            if N.valid(self.current) then self.current=N.from(self.current) end
            if N.valid(amount) then amount=N.from(amount) end
        end
        return previous(self,amount,...)
    end
end
if type(parameter_class)=='table' and parameter_class.level_up_hand then
    local previous=parameter_class.level_up_hand
    parameter_class.level_up_hand=function(self,amount,hand,...)
        if N.active() and N.valid(hand[self.key]) then hand[self.key]=N.from(hand[self.key]) end
        return previous(self,amount,hand,...)
    end
end
if rawget(SMODS,'get_scoring_parameter') then
    local previous=SMODS.get_scoring_parameter
    SMODS.get_scoring_parameter=function(...)
        local value=previous(...)
        return N.active() and N.valid(value) and N.from(value) or value
    end
end
if rawget(SMODS,'calculate_individual_effect') then
    local previous=SMODS.calculate_individual_effect
    SMODS.calculate_individual_effect=function(effect,card,key,amount,...)
        if N.active() then
            if N.valid(amount) then amount=N.from(amount) end
            local map=SMODS.Scoring_Parameter_Calculation
            local parameter=map and map[key] and SMODS.Scoring_Parameters[map[key]]
            if parameter and N.valid(parameter.current) then parameter.current=N.from(parameter.current) end
        end
        return previous(effect,card,key,amount,...)
    end
end
if rawget(SMODS,'calculate_round_score') then
    local previous=SMODS.calculate_round_score
    SMODS.calculate_round_score=function(flames,...)
        local value=previous(flames,...)
        if not N.active() then return value end
        local game=G and G.GAME
        if not flames and game and game.blind and
            (N.nan(value) or N.nan(game.chips) or N.nan(game.blind.chips)) then
            -- Recover only when an actual hand is scoring, never while drawing
            -- flames, inspecting a collection entry, or previewing a hand.
            if G.STATES and G.STATE==G.STATES.HAND_PLAYED then
                if N.nan(game.chips) then game.chips=0 end
                if N.nan(game.blind.chips) then game.blind.chips=1;game.blind.chip_text=number_format(1) end
                game.supereditions_invalid_score_recovered=true
                local needed=N.sub(game.blind.chips,game.chips or 0)
                if N.nan(needed) then needed=1 end
                return math.max(1,needed)
            end
        end
        return N.valid(value) and N.from(value) or value
    end
end
