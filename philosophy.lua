local mod = SMODS.current_mod
SMODS.Atlas {
    key='philosophy', path='philosophy.png', px=1024, py=1536,
    force_pixel=true, disable_mipmap=true,
}
SMODS.Joker {
    key='philosophy', rarity=3, cost=10, unlocked=true, discovered=true,
    atlas='philosophy', pos={x=0,y=0}, blueprint_compat=false,
    eternal_compat=true, perishable_compat=true, config={},
    loc_txt={name='Philosophy',text={
        'Questions your actions',
        'Temporarily disables {C:attention}1{}',
        'random active {C:attention}stake penalty{}',
        '{C:inactive}(#1#){}',
        '{s:0.8}Existing stickers and Blinds stay unchanged{}',
    }},
    in_pool=function() return mod.supereditions_philosophy_in_pool() end,
    loc_vars=function(self,info_queue,card)
        return {vars={mod.supereditions_philosophy_name(card)}}
    end,
    add_to_deck=function(self,card) mod.supereditions_philosophy_add(card) end,
    remove_from_deck=function(self,card) mod.supereditions_philosophy_remove(card) end,
    update=function() mod.supereditions_philosophy_sync() end,
    calculate=function(self,card,context)
        if context.blueprint or context.retrigger_joker or card.debuff then return end
        local action
        if context.before then action='play that hand'
        elseif context.pre_discard then action='discard those cards'
        elseif context.buying_card then action='buy that card'
        elseif context.selling_card then action='sell that card'
        elseif context.reroll_shop then action='reroll the shop'
        elseif context.ending_shop then action='leave the shop'
        elseif context.skip_blind then action='skip that Blind'
        elseif context.using_consumeable then action='use that card'
        elseif context.open_booster then action='open that pack'
        elseif context.skipping_booster then action='leave that pack' end
        if action then return {message='why did you '..action,colour=G.C.PURPLE,no_retrigger=true} end
    end,
}
