-- Original scientific-notation arithmetic for the extended-score setting.
-- Explicit operations avoid Lua 5.1's mixed table/number comparison errors.
-- Values are immutable by convention; no global number/math behavior changes.
-- Like native numbers, the significand has double precision, not exact digits.
local B = {}
local function special(kind, sign) return {kind=kind, m=sign or 0, e=0} end
local function normalized(m,e)
    if m~=m or e~=e then return special('nan') end
    if m==0 or e==-math.huge then return {kind='finite',m=0,e=0} end
    if math.abs(m)==math.huge or e==math.huge then return special('infinity',m<0 and -1 or 1) end
    local shift=math.floor(math.log10(math.abs(m)))
    -- Extremely small native values can make 10^shift underflow to zero.
    if shift < -300 then m=m*1e300;e=e-300;shift=math.floor(math.log10(math.abs(m))) end
    if shift > 300 then m=m/1e300;e=e+300;shift=math.floor(math.log10(math.abs(m))) end
    m=m/10^shift;e=e+shift
    if math.abs(m)>=10 then m=m/10;e=e+1 end
    if math.abs(m)<1 then m=m*10;e=e-1 end
    if e>1000 or (e==1000 and math.abs(m)>=2) then return special('infinity',m<0 and -1 or 1) end
    return {kind='finite',m=m,e=e}
end
function B.is(value)
    return type(value)=='table' and (value.kind=='finite' or value.kind=='infinity' or value.kind=='nan')
        and type(value.m)=='number' and type(value.e)=='number'
end
function B.from(value)
    if B.is(value) then return value end
    if type(value)=='number' then return normalized(value,0) end
    if type(value)=='string' then
        if value=='Infinity' or value=='inf' then return special('infinity',1) end
        if value=='-Infinity' or value=='-inf' then return special('infinity',-1) end
        if value=='NaN' or value=='nan' then return special('nan') end
        local m,e=value:match('^%s*([%+%-]?%d*%.?%d+)[eE]([%+%-]?%d+)%s*$')
        if m then return normalized(tonumber(m),tonumber(e)) end
        local n=tonumber(value); if n then return normalized(n,0) end
    end
    error('Invalid extended score value',2)
end
function B.is_nan(x) return B.from(x).kind=='nan' end
function B.is_infinite(x) return B.from(x).kind=='infinity' end
function B.neg(x)
    x=B.from(x);return x.kind=='finite' and normalized(-x.m,x.e) or special(x.kind,-x.m)
end
function B.abs(x) x=B.from(x);return x.m<0 and B.neg(x) or x end
function B.compare(a,b)
    a,b=B.from(a),B.from(b)
    if a.kind=='nan' or b.kind=='nan' then return nil end
    if a.kind=='infinity' then
        if b.kind=='infinity' and a.m==b.m then return 0 end
        return a.m
    end
    if b.kind=='infinity' then return -b.m end
    if a.m==0 and b.m==0 then return 0 end
    if a.m>=0 and b.m<0 then return 1 end
    if a.m<0 and b.m>=0 then return -1 end
    if a.m==0 then return -1 end
    if b.m==0 then return 1 end
    local sign=a.m<0 and -1 or 1
    if a.e~=b.e then return (a.e>b.e and 1 or -1)*sign end
    if a.m==b.m then return 0 end
    return a.m>b.m and 1 or -1
end
function B.eq(a,b) return B.compare(a,b)==0 end
function B.lt(a,b) return B.compare(a,b)==-1 end
function B.le(a,b) local c=B.compare(a,b);return c~=nil and c<=0 end
function B.add(a,b)
    a,b=B.from(a),B.from(b)
    if a.kind=='nan' or b.kind=='nan' then return special('nan') end
    if a.kind=='infinity' then
        if b.kind=='infinity' and a.m~=b.m then return special('nan') end
        return a
    end
    if b.kind=='infinity' then return b end
    if a.m==0 then return b end
    if b.m==0 then return a end
    if a.e<b.e then a,b=b,a end
    if a.e-b.e>18 then return a end
    return normalized(a.m+b.m*10^(b.e-a.e),a.e)
end
function B.sub(a,b) return B.add(a,B.neg(b)) end
function B.mul(a,b)
    a,b=B.from(a),B.from(b)
    if a.kind=='nan' or b.kind=='nan' then return special('nan') end
    if a.kind=='infinity' or b.kind=='infinity' then
        if a.m==0 or b.m==0 then return special('nan') end
        return special('infinity',a.m*b.m<0 and -1 or 1)
    end
    return normalized(a.m*b.m,a.e+b.e)
end
function B.div(a,b)
    a,b=B.from(a),B.from(b)
    if a.kind=='nan' or b.kind=='nan' then return special('nan') end
    if (a.kind=='infinity' and b.kind=='infinity') or (a.m==0 and b.m==0) then return special('nan') end
    if b.m==0 then return special('infinity',a.m<0 and -1 or 1) end
    if a.kind=='infinity' then return special('infinity',a.m*b.m<0 and -1 or 1) end
    if b.kind=='infinity' then return B.from(0) end
    return normalized(a.m/b.m,a.e-b.e)
end
function B.to_number(x)
    x=B.from(x)
    if x.kind=='nan' then return 0/0 end
    if x.kind=='infinity' then return x.m*math.huge end
    if x.e>308 then return x.m*math.huge end
    if x.e<-300 then return (x.m*10^(x.e+300))*1e-300 end
    return x.m*10^x.e
end
function B.log10(x)
    x=B.from(x)
    if x.kind=='nan' or x.m<0 then return 0/0 end
    if x.m==0 then return -math.huge end
    if x.kind=='infinity' then return math.huge end
    return math.log10(x.m)+x.e
end
function B.pow(a,b)
    a,b=B.from(a),B.from(b)
    if b.kind=='finite' and b.m==0 then return B.from(1) end
    if a.kind=='nan' or b.kind=='nan' then return special('nan') end
    if B.eq(a,1) then return B.from(1) end
    local exponent=B.to_number(b)
    local negative=a.m<0
    if negative and (math.abs(exponent)==math.huge or exponent~=math.floor(exponent)) then return special('nan') end
    local sign=negative and exponent%2~=0 and -1 or 1
    if a.m==0 then return exponent<0 and special('infinity',1) or B.from(0) end
    if a.kind=='infinity' then return exponent<0 and B.from(0) or special('infinity',sign) end
    local logarithm=B.log10(B.abs(a))*exponent
    if logarithm~=logarithm then return special('nan') end
    if logarithm>=1000+math.log10(2) then return special('infinity',sign) end
    if logarithm==-math.huge then return B.from(0) end
    local e=math.floor(logarithm)
    return normalized(sign*10^(logarithm-e),e)
end
function B.floor(x)
    x=B.from(x)
    if x.kind~='finite' or x.m==0 or x.e>=16 then return x end
    if x.e<0 then return B.from(x.m<0 and -1 or 0) end
    return B.from(math.floor(B.to_number(x)))
end
function B.format(x,precision)
    x=B.from(x)
    if x.kind=='nan' then return 'NaN' end
    if x.kind=='infinity' then return x.m<0 and '-Infinity' or 'Infinity' end
    if x.m==0 then return '0' end
    precision=precision or 4
    if x.e>=-3 and x.e<6 then return string.format('%.'..precision..'g',B.to_number(x)) end
    local m=tonumber(string.format('%.'..precision..'g',x.m));local e=x.e
    if math.abs(m)>=10 then m=m/10;e=e+1 end
    return tostring(m)..'e'..tostring(e)
end
function B.save(x)
    x=B.from(x)
    return {supereditions_number=1,kind=x.kind,m=x.m,e=x.e}
end
function B.load(data)
    assert(type(data)=='table' and data.supereditions_number==1,'Invalid extended score save')
    if data.kind=='nan' then return special('nan') end
    if data.kind=='infinity' then
        assert(data.m==1 or data.m==-1,'Invalid Infinity sign')
        return special('infinity',data.m)
    end
    assert(data.kind=='finite' and type(data.m)=='number' and type(data.e)=='number'
        and data.m==data.m and data.e==data.e and math.abs(data.m)<math.huge
        and math.abs(data.e)<math.huge and data.e==math.floor(data.e),'Invalid extended score digits')
    return normalized(data.m,data.e)
end
return B
