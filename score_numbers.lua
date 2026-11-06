-- LuaJIT cdata supports mixed numeric comparisons; Lua 5.1 tables do not.
-- Keep ordinary results as native numbers, and extend only large scores.
local B=assert(SMODS.load_file('support/large_number.lua'))()
local N={kernel=B}
local ok,ffi=pcall(require,'ffi')
if not ok then N.available=false;N.reason='Extended scores require LuaJIT FFI.';return N end
if rawget(_G,'to_big') then
    N.available=false;N.reason='Another large-number system is already installed.';return N
end
ffi.cdef('typedef struct { double mantissa; double exponent; } supereditions_score_v1;')
local ctor
function N.is(value) return type(value)=='cdata' and ffi.istype(ctor,value) end
local function decode(value)
    if N.is(value) then return {kind='finite',m=value.mantissa,e=value.exponent} end
    return B.from(value)
end
local function encode(value)
    if value.kind~='finite' then return B.to_number(value) end
    if value.e<100 and value.e>-300 then return B.to_number(value) end
    if value.m==0 then return 0 end
    return ctor(value.m,value.e)
end
function N.from(value) if N.is(value) then return value end;return encode(decode(value)) end
function N.valid(value) return type(value)=='number' or N.is(value) end
function N.nan(value) return N.valid(value) and type(value)=='number' and value~=value end
function N.add(a,b)
    if type(a)=='number' and type(b)=='number' then
        local sum=a+b
        if sum==sum and math.abs(sum)<1e100 then return sum end
    end
    return encode(B.add(decode(a),decode(b)))
end
function N.sub(a,b)
    if type(a)=='number' and type(b)=='number' then
        local difference=a-b
        if difference==difference and math.abs(difference)<1e100 then return difference end
    end
    return encode(B.sub(decode(a),decode(b)))
end
function N.mul(a,b)
    if type(a)=='number' and type(b)=='number' then
        local product=a*b
        if product==product and math.abs(product)<1e100 and (product~=0 or a==0 or b==0) then return product end
    end
    return encode(B.mul(decode(a),decode(b)))
end
function N.div(a,b)
    if type(a)=='number' and type(b)=='number' then
        local quotient=a/b
        if quotient==quotient and math.abs(quotient)<1e100 and (quotient~=0 or a==0) then return quotient end
    end
    return encode(B.div(decode(a),decode(b)))
end
function N.pow(a,b)
    if type(a)=='number' and type(b)=='number' then
        local power=a^b
        if power==power and math.abs(power)<1e100 and (power~=0 or a==0) then return power end
    end
    return encode(B.pow(decode(a),decode(b)))
end
function N.floor(a) return encode(B.floor(decode(a))) end
function N.abs(a) return encode(B.abs(decode(a))) end
function N.log10(a) return B.log10(decode(a)) end
function N.mod(a,b)
    if b==0 then return 0/0 end
    if b==math.huge or b==-math.huge then return a end
    return N.sub(a,N.mul(N.floor(N.div(a,b)),b))
end
function N.format(a) return B.format(decode(a)) end
function N.to_number(a) return B.to_number(decode(a)) end
ctor=ffi.metatype('supereditions_score_v1',{
    __add=N.add,__sub=N.sub,__mul=N.mul,__div=N.div,__pow=N.pow,__mod=N.mod,
    __unm=function(a)return encode(B.neg(decode(a)))end,
    __eq=function(a,b)return N.valid(a) and N.valid(b) and B.eq(decode(a),decode(b))end,
    __lt=function(a,b)return B.lt(decode(a),decode(b))end,
    __le=function(a,b)return B.le(decode(a),decode(b))end,
    __tostring=N.format,
    __concat=function(a,b)return tostring(a)..tostring(b)end,
})
N.available=true

-- Save as ordinary data for the game's restricted STR_UNPACK environment.
-- No FFI constructor, globals, executable code, or non-finite JSON is needed.
function N.encode_tree(value,seen)
    if type(value)=='number' and (value~=value or math.abs(value)==math.huge) then
        return {supereditions_score_v1=true,special=value~=value and 'nan' or 'infinity',sign=value<0 and -1 or 1}
    end
    if N.is(value) then
        return {supereditions_score_v1=true,m=value.mantissa,e=value.exponent}
    end
    if type(value)~='table' then return value end
    seen=seen or {};if seen[value] then return seen[value] end
    local out={};seen[value]=out
    for k,v in pairs(value) do out[k]=N.encode_tree(v,seen) end
    return out
end
function N.decode_tree(value,seen)
    if type(value)~='table' then return value end
    if value.supereditions_score_v1==true then
        if value.special=='nan' then return 0/0 end
        if value.special=='infinity' then
            assert(value.sign==1 or value.sign==-1,'Invalid Infinity save sign')
            return value.sign*math.huge
        end
        return encode(B.load({supereditions_number=1,kind='finite',m=value.m,e=value.e}))
    end
    seen=seen or {};if seen[value] then return seen[value] end
    seen[value]=value
    for k,v in pairs(value) do value[k]=N.decode_tree(v,seen) end
    return value
end
return N
