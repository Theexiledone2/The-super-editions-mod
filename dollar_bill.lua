SMODS.Atlas {key='dollar_bill',path='dollar-bill.png',px=1024,py=1536,force_pixel=true,disable_mipmap=true}
local key='j_supereditions_dollar_bill'
local function own(card) return card and card.config and card.config.center and card.config.center.key==key end
local function packed(...)return {n=select('#',...),...}end
local function free(card)
    if own(card) then card.cost=0;card.sell_cost=0;card.sell_cost_label=0 end
end
SMODS.Joker {
    key='dollar_bill',atlas='dollar_bill',pos={x=0,y=0},rarity=1,cost=0,
    unlocked=true,discovered=true,blueprint_compat=false,
    eternal_compat=true,perishable_compat=true,config={},
    loc_txt={name='Dollar Bill',text={
        'Gain {C:money}$1{} when purchased',
        '{C:inactive}(Once per card){}',
        'Costs {C:money}$0{} and sells for {C:money}$0{}',
        'Does nothing afterward',
    }},
    calculate=function(self,card,context)
        if not context.buying_card or context.card~=card or context.blueprint
            or context.retrigger_joker or card.ability.supereditions_dollar_paid
            or not (G and G.GAME and G.STAGES and G.STAGE==G.STAGES.RUN) then return end
        -- Mark before paying so nested purchase/retrigger contexts cannot pay
        -- twice. This marker is saved/copied with the ordinary card ability.
        card.ability.supereditions_dollar_paid=true
        ease_dollars(1,true)
    end,
}
if Card and Card.set_cost then
    local previous=Card.set_cost
    Card.set_cost=function(self,...)
        local result=packed(previous(self,...));free(self);return unpack(result,1,result.n)
    end
end
if Card and Card.load then
    local previous=Card.load
    Card.load=function(self,...)
        local result=packed(previous(self,...));free(self);return unpack(result,1,result.n)
    end
end
