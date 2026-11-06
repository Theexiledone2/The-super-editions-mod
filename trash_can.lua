local mod=SMODS.current_mod
SMODS.Atlas {key='trash_can',path='trash-can.png',px=1024,py=1536,force_pixel=true,disable_mipmap=true}
SMODS.Joker {
    key='trash_can',rarity='supereditions_epic',cost=12,unlocked=true,discovered=true,
    atlas='trash_can',pos={x=0,y=0},blueprint_compat=false,eternal_compat=true,perishable_compat=true,config={},
    loc_txt={name='Trash Can',text={
        'Drop a {C:attention}hand card{} here to destroy it',
        '{C:attention}Right-click{} to restore the newest',
        'Remembers the last {C:attention}3{} cards',
        '{C:inactive}(#1# stored; Eternal cards protected){}',
        '{s:0.8,C:inactive}(Use while choosing cards to play){}',
    }},
    loc_vars=function(self,info_queue,card)return {vars={mod.supereditions_trash_count(card)}}end,
}
