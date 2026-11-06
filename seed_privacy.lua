local mod = SMODS.current_mod
if not mod then return end
local function copy(t) local out={};for k,v in pairs(t) do out[k]=v end;return out end
local function run() return G and G.GAME end
local function seed()
    local game=run();return game and game.pseudorandom and game.pseudorandom.seed
end
local function visible()
    local game=run()
    if not (game and G.STAGES and G.STAGE==G.STAGES.RUN) then return true end
    if game.supereditions_seed_revealed or (G.STATES and G.STATE==G.STATES.GAME_OVER) then return true end
    local ante=game.round_resets and game.round_resets.ante or 0
    return mod.config and mod.config.seed_visibility==2 and ante>8 or false
end
mod.supereditions_seed_visible = visible
local function masked(text)
    local value=seed()
    if type(value)~='string' or value=='' then return text end
    if text==value then return visible() and text or '????????' end
    return text
end
local function reference(config)
    local game=run()
    if game and config.ref_table==game.pseudorandom and config.ref_value=='seed' then
        local out=copy(config)
        -- UI references can update after Ante 8 without touching the live RNG.
        out.ref_table=setmetatable({}, {__index=function(_,key)
            if key=='seed' then return masked(seed()) end
        end})
        return out
    end
    return config
end
local function node(definition)
    if type(definition)~='table' then return definition end
    local out=copy(definition)
    if type(definition.config)=='table' then
        out.config=copy(reference(definition.config))
        out.config.text=masked(out.config.text)
    end
    if type(definition.nodes)=='table' then
        out.nodes={};for i,child in pairs(definition.nodes) do out.nodes[i]=node(child) end
    end
    return out
end
if type(UIBox)=='table' and UIBox.init then
    local previous=UIBox.init
    UIBox.init=function(self,args,...)
        if seed() and type(args)=='table' and args.definition then
            local adjusted=copy(args);adjusted.definition=node(args.definition);args=adjusted
        end
        return previous(self,args,...)
    end
end
if type(DynaText)=='table' and DynaText.init then
    local previous=DynaText.init
    DynaText.init=function(self,args,...)
        if seed() and type(args)=='table' then
            local adjusted=copy(args)
            if type(args.string)=='table' then
                adjusted.string={}
                for i,entry in pairs(args.string) do
                    if type(entry)=='table' then
                        local item=copy(reference(entry));item.string=masked(item.string)
                        adjusted.string[i]=item
                    else adjusted.string[i]=masked(entry) end
                end
            elseif type(args.string)=='string' then adjusted.string=masked(args.string) end
            args=adjusted
        end
        return previous(self,args,...)
    end
end
if love and love.system and love.system.setClipboardText then
    local previous=love.system.setClipboardText
    love.system.setClipboardText=function(text,...)
        if seed() and text==seed() and not visible() then return end
        return previous(text,...)
    end
end
if Game and Game.update then
    local previous=Game.update
    Game.update=function(self,...)
        if run() and G.STATES and G.STATE==G.STATES.GAME_OVER then
            G.GAME.supereditions_seed_revealed=true
        end
        return previous(self,...)
    end
end
