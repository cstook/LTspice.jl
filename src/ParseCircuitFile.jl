# overload parse for the CircuitParsed type
# used to parse LTspice circuit files *.asc
"""
Stores data from the circuit file.

**Fields**

- `circuitpath`       -- Path to the circuit file
- `circuitfilearray`  -- Array of all the text of the circuit file, split
                         around values which need to be edited.
- `parameternames`    -- Array of parameter names
- `parameters`        -- Array of tuples (value, multiplier, index into `circuitfilearray`)       
- `measurementnames`  -- Array of measurement names
- `stepnames`         -- Array of step names
- `needsupdate`       -- `true` if parameter value has beed changed.
                         `false` after `circuitfilearray` is written.
- `parsed`            -- `true` if last `parsecard!` call was a match
"""
type CircuitParsed
  circuitpath     :: ASCIIString
  circuitfilearray:: Array{ASCIIString,1}    # text of circuit file
  parameternames  :: Array{ASCIIString,1}
  parameters      :: Array{Tuple{Float64,Float64,Int},1}  # array of parameters (value, multiplier, index)
  measurementnames:: Array{ASCIIString,1}              # measurement names
  stepnames       :: Array{ASCIIString,1}  
  needsupdate     :: Bool # true if any parameter has been changed
  parsed          :: Bool # true if last parsecard! call was a match
  CircuitParsed() = new("",[],[],[],[],[],false,false) # empty CircuitParsed
end

circuitpath(x::CircuitParsed) = x.circuitpath
circuitpath!(x::CircuitParsed, path::ASCIIString) = x.circuitpath = path
circuitfilearray(x::CircuitParsed) = x.circuitfilearray
parameternames(x::CircuitParsed) = x.parameternames
parameternames!(x::CircuitParsed, parameternames::Array{ASCIIString,1}) = x.parameternames = parameternames
parameters(x::CircuitParsed) = x.parameters
parameters!(x::CircuitParsed, parameters::Array{Tuple{Float64,Float64,Int},1}) = x.parameters = parameters
parametervalues(x::CircuitParsed) = [parameter[1] for parameter in x.parameters]
measurementnames(x::CircuitParsed) = x.measurementnames
measurementnames!(x::CircuitParsed, measurementnames::Array{ASCIIString,1}) = x.measurementnames = measurementnames
stepnames(x::CircuitParsed) = x.stepnames
stepnames!(x::CircuitParsed, stepnames::Array{ASCIIString,1}) = x.stepnames = stepnames
hassteps(x::CircuitParsed) = length(x.stepnames) != 0
hasmeasurements(x::CircuitParsed) = length(x.measurementnames) != 0
hasparameters(x::CircuitParsed) = length(x.parameters) != 0
setneedsupdate!(x::CircuitParsed) = x.needsupdate = true
clearneedsupdate!(x::CircuitParsed) = x.needsupdate = false
needsupdate(x::CircuitParsed) = x.needsupdate
setparsed!(x::CircuitParsed) = x.parsed = true
clearparsed!(x::CircuitParsed) = x.parsed = false
parsed(x::CircuitParsed) = x.parsed

### BEGIN overloading Base ###

function Base.show(io::IO, x::CircuitParsed)
	println(io,circuitpath(x))
  if length(parameters(x))>0
  	println(io,"")
  	println(io,"Parameters")
  	for (key,(value,m,i)) in zip(parameternames(x),parameters(x))
    	println(io,"  $(rpad(key,25,' ')) = $value")
  	end
  end
 	if length(measurementnames(x))>0 
 		println(io,"")
 		println(io,"Measurements")
 	  for name in measurementnames(x)
 		 println(io,"  $name")
 	  end
  end
 	if length(stepnames(x))>0
 		println(io,"")
 		println(io,"Sweeps")
 	  for name in stepnames(x)
 		 println(io,"  $name")
 	  end
  end
end

# CircuitParsed is a Dict of its parameters
Base.haskey(x::CircuitParsed,key::ASCIIString) = findfirst(parameternames(x), key) != 0
Base.keys(x::CircuitParsed) = [key for key in parameternames(x)]
Base.values(x::CircuitParsed) = [parameter[1] for parameter in parameters(x)]
function Base.getindex(x::CircuitParsed, key::ASCIIString)
  k = findfirst(parameternames(x), key)
  if k == 0 
    throw(KeyError(key))
  else
    return parameters(x)[k][1]
  end
end

function Base.setindex!(x::CircuitParsed, value:: Float64, key::ASCIIString)
  k = findfirst(parameternames(x), key)
  if k == 0 
    throw(KeyError(key))
  else
    x[k] = value
  end
end

function Base.setindex!(x::CircuitParsed, value:: Float64, index:: Int)
  (v,m,i) = parameters(x)[index]
  p = parameters(x)
  c = circuitfilearray(x)
  p[index] = (value,m,i)
  c[i] = "$(value/m)"
  setneedsupdate!(x)
end

Base.length(x::CircuitParsed) = length(parameters(x))
Base.eltype(::CircuitParsed) = Float64

# CircuitParsed iterates over its Dict
Base.start(x::CircuitParsed) = 0
function Base.next(x::CircuitParsed, state)
  state +=1
  return ((parameternames(x)[state]=>parameters(x)[state][1]),state)
end
Base.done(x::CircuitParsed, state) = ~(state < length(parameters(x)))

# LTspice allows multiple directives (cards) in a single block
# in the GUI, ctrl-M is used to create a new line.
# this puts a backslash n in the file, NOT a newline character.
#
# eachcard is an iterator that separates the lines around the backslash n
immutable eachcard 
    line :: ASCIIString
end
Base.start(::eachcard) = 1
function Base.next(ec::eachcard, state)
    p = searchindex(ec.line,"\\n",state)
    if p!=0
        card = ec.line[state:p+1]
        state = p+2
    else
        card = ec.line[state:end]
        state = length(ec.line)
    end
    return (card, state)
end
Base.done(ec::eachcard, state) = state>=length(ec.line)
"""
Subtypes of `Card` are used to dispach `parsecard!` to process a specific type of card

**Subtypes**
- `ResetParsedFlag`
- `Parameter`
- `Measure`
- `Step`
- `Other`
"""
abstract Card
type ResetParsedFlag end
type Parameter<:Card end
type Measure<:Card end
type Step<:Card end
type Other<:Card end
const cardlist = [ResetParsedFlag(), Parameter(), Measure(), Step(), Other()]

parsecard!(cf::CircuitParsed, ::ResetParsedFlag, card) = clearparsed!(cf)

const parameterregex = r"[.](?:parameter|param)[ ]+([a-z][a-z0-9_@#$.:\\]*)[= ]+([-+]{0,1}[0-9.]+e{0,1}[-+0-9]*)(k|meg|g|t|m|u|n|p|f){0,1}[ ]*(?:\\n|\r|$)"ix
function parsecard!(cf::CircuitParsed, ::Parameter, card::ASCIIString)
    if parsed(cf) # exit if card has already been processed
        return
    end
    m = match(parameterregex, card)
    if m == nothing # exit if not a parameter card
        return 
    end
    name = m.captures[1]
    value = m.captures[2]
    valueoffset = m.offsets[2] # position of start of value in card
    valuelength = length(value)
    valueend = valuelength + valueoffset-1 # position of end of value in card
    unit = m.captures[3]
    cfa = circuitfilearray(cf)
    p_names = parameternames(cf)
    P_vmi = parameters(cf)
    push!(cfa,card[1:valueoffset-1]) # before the value
    push!(cfa,card[valueoffset:valueend]) # the value
    if haskey(units,unit)
        multiplier = units[unit]
    else
        multiplier = 1.0
    end
    valuenounit = parse(Float64,value)
    push!(p_names, lowercase(name))
    push!(P_vmi, (valuenounit * multiplier, multiplier, length(cfa)))
    push!(cfa,card[valueend+1:end]) # after the value
    setparsed!(cf)
end

const measureregex = r"[.](?:measure|meas)[ ]+(?:ac |dc |op |tran |tf |noise ){0,1}[ ]*([a-z][a-z0-9_@#$.:\\]*)[ ]+"ix
function parsecard!(cf::CircuitParsed, ::Measure, card::ASCIIString)
    if parsed(cf) # exit if card has already been processed
        return
    end
    m = match(measureregex, card)
    if m == nothing # exit if not a measure card
        return 
    end
    name = m.captures[1]
    m_names = measurementnames(cf)
    cfa = circuitfilearray(cf)
    push!(m_names,lowercase(name))
    push!(cfa,card)
    setparsed!(cf)
end

const step1regex = r"[.](?:step)[ ]+(?:oct |param ){0,1}[ ]*([a-z][a-z0-9_@#$.:\\]*)[ ]+(?:list ){0,1}[ ]*[0-9.e+-]+[a-z]*[ ]+"ix
const step2regex = r"[.](?:step)[ ]+(?:\w+)[ ]+(\w+[(]\w+[)])[ ]+"ix
function parsecard!(cf::CircuitParsed, ::Step, card::ASCIIString)
    if parsed(cf) # exit if card has already been processed
        return
    end
    m = match(step1regex, card)
    if m == nothing
        m = match(step2regex, card)
        if m == nothing
            return # exit if not a step card
        end
    end
    name = m.captures[1]
    s_names = stepnames(cf)
    cfa = circuitfilearray(cf)
    push!(s_names, lowercase(name))
    push!(cfa,card)
    setparsed!(cf)
end

function parsecard!(cf::CircuitParsed, ::Other, card::ASCIIString)
    if parsed(cf) # exit if card has already been processed
        return
    end
    cfa = circuitfilearray(cf)
    push!(cfa,card) # just push the whole card
    setparsed!(cf)
end

function parsecard!(cf::CircuitParsed, card::ASCIIString)
    for cardtype in cardlist
        parsecard!(cf,cardtype,card)
    end
end

"""
    parsecard!(cf::CircuitParsed, ::Card, card::ASCIIString)
    parsecard!(cf::CircuitParsed, card::ASCIIString)

Test to see if a `card` is a type of `Card` and if so update `cp`.  The
second form tries all subtypes of `Card` in global `cardlist`, which is
just a list of all `Card` subtypes.
"""
parsecard!

"""
    iscomment(line::ASCIIString)

`true` if line is comment
"""
iscomment(line::ASCIIString) = ismatch(r"^TEXT .* ;",line)

function Base.parse(::Type{CircuitParsed}, circuitpath::ASCIIString)
    io = open(circuitpath,true,false,false,false,false)
    cf = CircuitParsed()
    circuitpath!(cf, circuitpath)
    cfa = circuitfilearray(cf)
    for line in eachline(io)
        if iscomment(line)
            push!(cfa, line)
        else
            for card in eachcard(line) # might be multi-line directive(s) created with Ctrl-M
                parsecard!(cf, card)
            end
        end
    end
    close(io)
    return cf
end

function Base.flush(x::CircuitParsed)
	if needsupdate(x)
		io = open(circuitpath(x),false,true,false,true,false)  # open circuit file to be overwritten
		for text in circuitfilearray(x)
      print(io,text)
		end
		close(io)
  	clearneedsupdate!(x)
  end
  return nothing
end

# units as defined in LTspice
const units = Dict("K" => 1.0e3,
                   "k" => 1.0e3,
                   "MEG" => 1.0e6,
                   "meg" => 1.0e6,
                   "G" => 1.0e9,
                   "g" => 1.0e9,
                   "T" => 1.0e12,
                   "t" => 1.0e12,
                   "M" => 1.0e-3,
                   "m" => 1.0e-3,
                   "U" => 1.0e-6,
                   "u" => 1.0e-6,
                   "N" => 1.0e-9,
                   "n" => 1.0e-9,
                   "P" => 1.0e-12,
                   "p" => 1.0e-12,
                   "F" => 1.0e-15,
                   "f" => 1.0e-15)