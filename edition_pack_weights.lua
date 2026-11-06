-- Boost matching Jokers only inside this mod's edition-pack offer generation.
-- Rarity, eligibility, duplicates and seeded selection remain engine-owned.
local mod = SMODS.current_mod
mod.optional_features = mod.optional_features or {}
mod.optional_features.object_weights = true
local families = {
    supereditions_foil_contents = {
        j_supereditions_shielding_jimbo = true,
        j_supereditions_foilmaker = true,
        j_supereditions_the_foil_family = true,
    },
    supereditions_polychrome_contents = {
        j_supereditions_pollinator = true,
        j_supereditions_poli_faker = true,
        j_supereditions_forest_protector = true,
    },
    supereditions_holographic_contents = {
        j_supereditions_the_phone = true,
        j_supereditions_scalper = true,
        j_supereditions_one_of_one = true,
    },
    supereditions_negative_contents = {
        j_supereditions_factorial = true,
        j_supereditions_martyr = true,
    },
}
local function packed(...) return {n = select('#', ...), ...} end
local creating, selecting
local create = assert(SMODS.create_card)
SMODS.create_card = function(args, ...)
    local prior_create, prior_select = creating, selecting
    creating, selecting = nil, nil
    if type(args) == 'table' and args.set == 'Joker' and not args.key
        and not args.legendary and not args.attributes
        and G and G.GAME and G.STAGES and G.STAGE == G.STAGES.RUN
        and G.pack_cards and args.area == G.pack_cards then
        creating = families[args.key_append]
    end
    local result = packed(pcall(create, args, ...))
    creating, selecting = prior_create, prior_select
    if not result[1] then error(result[2], 0) end
    return unpack(result, 2, result.n)
end

local function joker_poll(args)
    if type(args) ~= 'table' or args.attributes then return false end
    if args.types then return #args.types == 1 and args.types[1] == 'Joker' end
    return args.type == nil or args.type == 'Joker'
end
local poll = assert(SMODS.poll_object)
SMODS.poll_object = function(args, ...)
    local prior_create, prior_select = creating, selecting
    selecting = joker_poll(args) and creating
        and families[args.append] == creating and creating or nil
    -- Nested polls cannot inherit the enclosing pack's bonus. A nested card
    -- creation establishes its own scope and restores this one afterwards.
    creating = nil
    local result = packed(pcall(poll, args, ...))
    creating, selecting = prior_create, prior_select
    if not result[1] then error(result[2], 0) end
    return unpack(result, 2, result.n)
end

local calculate = mod.calculate
mod.calculate = function(self, context)
    local result = calculate and packed(calculate(self, context)) or {n = 0}
    if selecting and context.modify_weights and type(context.pool) == 'table' then
        for _, entry in pairs(context.pool) do
            if selecting[entry.key] and type(entry.weight) == 'number' and entry.weight > 0 then
                entry.weight = entry.weight * 3
            end
        end
    end
    return unpack(result, 1, result.n)
end
