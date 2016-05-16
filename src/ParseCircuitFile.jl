# overloard parse for the CircuitFile type
# used to parse LTspice circuit files *.asc

#export CircuitFile, getcircuitpath, getmeasurmentnames, getstepnames
#export isneedsupdate

### BEGIN Type CircuitFile and constructors ###

type CircuitFile
  circuitpath     :: ASCIIString
  circuitfilearray:: Array{ASCIIString,1}    # text of circuit file
  parameternames  :: Array{ASCIIString,1}
  parameters      :: Array{Tuple{Float64,Float64,Int},1}  # array of parameters (value, multiplier, index)
  measurementnames:: Array{ASCIIString,1}              # measurment names
  stepnames       :: Array{ASCIIString,1}  
  needsupdate     :: Bool # true if any parameter has been changed
  parsed          :: Bool # true if last parsecard! call was a match
  CircuitFile() = new("",[],[],[],[],[],false,false) # empty CircuitFile
end

### END Type CircuitFile and constructors ###

getcircuitpath(x::CircuitFile) = x.circuitpath
getparameternames(x::CircuitFile) = x.parameternames
getparameters(x::CircuitFile) = [parameter[1] for parameter in x.parameters]
getmeasurementnames(x::CircuitFile) = x.measurementnames
getstepnames(x::CircuitFile) = x.stepnames

circuitpath(x::CircuitFile) = x.circuitpath
circuitpath!(x::CircuitFile, path::ASCIIString) = x.circuitpath = path
circuitfilearray(x::CircuitFile) = x.circuitfilearray
parameternames(x::CircuitFile) = x.parameternames
parameternames!(x::CircuitFile, parameternames::Array{ASCIIString,1}) = x.parameternames = parameternames
parameters(x::CircuitFile) = x.parameters
parameters!(x::CircuitFile, parameters::Array{Tuple{Float64,Float64,Int},1}) = x.parameters = parameters
parametervalues(x::CircuitFile) = [parameter[1] for parameter in x.parameters]
measurementnames(x::CircuitFile) = x.measurementnames
measurementnames!(x::CircuitFile, measurementnames::Array{ASCIIString,1}) = x.measurementnames = measurementnames
stepnames(x::CircuitFile) = x.stepnames
stepnames!(x::CircuitFile, stepnames::Array{ASCIIString,1}) = x.stepnames = stepnames
hassteps(x::CircuitFile) = length(x.stepnames) != 0
hasmeasurements(x::CircuitFile) = length(x.measurementnames) != 0
hasparameters(x::CircuitFile) = length(x.parameters) != 0
setneedsupdate!(x::CircuitFile) = x.needsupdate = true
clearneedsupdate!(x::CircuitFile) = x.needsupdate = false
needsupdate(x::CircuitFile) = x.needsupdate
setparsed!(x::CircuitFile) = x.parsed = true
clearparsed!(x::CircuitFile) = x.parsed = false
parsed(x::CircuitFile) = x.parsed

### BEGIN overloading Base ###

function Base.show(io::IO, x::CircuitFile)
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
 		println(io,"Measurments")
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

# CircuitFile is a Dict of its parameters
Base.haskey(x::CircuitFile,key::ASCIIString) = findfirst(parameternames(x), key) != 0
Base.keys(x::CircuitFile) = [key for key in parameternames(x)]
Base.values(x::CircuitFile) = [parameter[1] for parameter in parameters(x)]
function Base.getindex(x::CircuitFile, key::ASCIIString)
  k = findfirst(parameternames(x), key)
  if k == 0 
    throw(KeyError(key))
  else
    return parameters(x)[k][1]
  end
end

function Base.setindex!(x::CircuitFile, value:: Float64, key::ASCIIString)
  k = findfirst(parameternames(x), key)
  if k == 0 
    throw(KeyError(key))
  else
    x[k] = value
  end
end

function Base.setindex!(x::CircuitFile, value:: Float64, index:: Int)
  (v,m,i) = parameters(x)[index]
  p = parameters(x)
  c = circuitfilearray(x)
  p[index] = (value,m,i)
  c[i] = "$(value/m)"
  setneedsupdate!(x)
end

Base.length(x::CircuitFile) = length(parameters(x))
Base.eltype(::CircuitFile) = Float64

# CircuitFile iterates over its Dict
Base.start(x::CircuitFile) = 0
function Base.next(x::CircuitFile, state)
  state +=1
  return ((parameternames(x)[state]=>parameters(x)[state][1]),state)
end
Base.done(x::CircuitFile, state) = ~(state < length(parameters(x)))

# LTspice allows multiple directives (cards) in a single block
# in the GUI, ctrl-M is used to create a new line.
# this puts a backslash n in the file, NOT a newline character.
#
# eachcard is an iterator that seperates the lines around the backslash n
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

abstract Card
type ResetParsedFlag end
type Parameter<:Card end
type Measure<:Card end
type Step<:Card end
type Other<:Card end
const cardlist = [ResetParsedFlag(), Parameter(), Measure(), Step(), Other()]

parsecard!(cf::CircuitFile, ::ResetParsedFlag, card) = clearparsed!(cf)

const parameterregex = r"[.](?:parameter|param)[ ]+([a-z][a-z0-9_@#$.:\\]*)[= ]+([-+]{0,1}[0-9.]+e{0,1}[-+0-9]*)(k|meg|g|t|m|u|n|p|f){0,1}[ ]*(?:\\n|\r|$)"ix
function parsecard!(cf::CircuitFile, ::Parameter, card::ASCIIString)
    if parsed(cf) # exit if card has already been processed
        return
    end
    m = match(parameterregex, card)
    if m == nothing # exit if not a parameter card
        return 
    end
    name = m.captures[1]
    value = m.captures[2]
    valueoffset = m.offsets[2] # pos of start of value in card
    valuelength = length(value)
    valueend = valuelength + valueoffset-1 # pos of end of value in card
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
function parsecard!(cf::CircuitFile, ::Measure, card::ASCIIString)
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
function parsecard!(cf::CircuitFile, ::Step, card::ASCIIString)
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

function parsecard!(cf::CircuitFile, ::Other, card::ASCIIString)
    if parsed(cf) # exit if card has already been processed
        return
    end
    cfa = circuitfilearray(cf)
    push!(cfa,card) # just push the whole card
    setparsed!(cf)
end

function parsecard!(cf::CircuitFile, card::ASCIIString)
    for cardtype in cardlist
        parsecard!(cf,cardtype,card)
    end
end

"true if line is comment"
iscomment(line::ASCIIString) = ismatch(r"^TEXT .* ;",line)

function Base.parse(::Type{CircuitFile}, circuitpath::ASCIIString)
    io = open(circuitpath,true,false,false,false,false)
    cf = CircuitFile()
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

### END overloading Base ###

### BEGIN CircuitFile specific methods ###

"writes circuit file back to disk if any parameters have changed"
function Base.flush(x::CircuitFile)
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

### END CircuitFile specific methods ###

### Begin other ###

# units as defined in LTspice
units = Dict()
units["K"] = 1.0e3
units["k"] = 1.0e3
units["MEG"] = 1.0e6
units["meg"] = 1.0e6
units["G"] = 1.0e9
units["g"] = 1.0e9
units["T"] = 1.0e12
units["t"] = 1.0e12
units["M"] = 1.0e-3
units["m"] = 1.0e-3
units["U"] = 1.0e-6
units["u"] = 1.0e-6
units["N"] = 1.0e-9
units["n"] = 1.0e-9
units["P"] = 1.0e-12
units["p"] = 1.0e-12
units["F"] = 1.0e-15
units["f"] = 1.0e-15

### END other ###
