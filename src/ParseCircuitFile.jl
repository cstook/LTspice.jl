type CircuitParsed
  circuitfilearray :: Array{AbstractString,1}
  parameternames :: Array{AbstractString,1}
  parametervalues :: ParameterValuesArray{Float64,1}
  parametermultiplier :: Array{Float64,1}
  parameterindex :: Array{Int,1}
  measurementnames :: Array{AbstractString,1}
  stepnames :: Array{AbstractString,1}
  circuitfileencoding
  CircuitParsed() = new([],[],[],[],[],[],[],nothing)
end

# LTspice allows multiple directives (cards) in a single block
# in the GUI, ctrl-M is used to create a new line.
# this puts a backslash n in the file, NOT a newline character.
#
# eachcard is an iterator that separates the lines around the backslash n
immutable eachcard
    line :: AbstractString
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
type Parameter<:Card end
type Measure<:Card end
type Step<:Card end
type Other<:Card end
const cardlist = [Parameter(), Measure(), Step(), Other()]

const parameterregex = r"[.](?:parameter|param)[ ]+([a-z][a-z0-9_@#$.:\\]*)[= ]+([-+]{0,1}[0-9.]+e{0,1}[-+0-9]*)(k|meg|g|t|m|u|n|p|f){0,1}[ ]*(?:\\n|\r|$)"ix
function parsecard!(cp::CircuitParsed, ::Parameter, card::AbstractString)
    m = match(parameterregex, card)
    if m == nothing # exit if not a parameter card
        return false
    end
    name = m.captures[1] #lowercase(m.captures[1])
    value = m.captures[2]
    valueoffset = m.offsets[2] # position of start of value in card
    valuelength = length(value)
    valueend = valuelength + valueoffset-1 # position of end of value in card
    unit = m.captures[3]
    push!(cp.circuitfilearray,card[1:valueoffset-1]) # before the value
    push!(cp.circuitfilearray,card[valueoffset:valueend]) # the value
    if haskey(units,unit)
        multiplier = units[unit]
    else
        multiplier = 1.0
    end
    valuenounit = parse(Float64,value)
    push!(cp.parameternames, name)
    index_parameternames = length(cp.parameternames)
    push!(cp.parametervalues.values, valuenounit * multiplier)
    push!(cp.parametermultiplier, multiplier)
    index_circuitfilearray = length(cp.circuitfilearray)
    push!(cp.parameterindex, index_circuitfilearray)
    push!(cp.circuitfilearray,card[valueend+1:end]) # after the value
    return true
end
const measureregex = r"[.](?:measure|meas)[ ]+(?:ac |dc |op |tran |tf |noise ){0,1}[ ]*([a-z][a-z0-9_@#$.:\\]*)[ ]+"ix
function parsecard!(cp::CircuitParsed, ::Measure, card::AbstractString)
    m = match(measureregex, card)
    if m == nothing # exit if not a measure card
        return false
    end
    name = m.captures[1]
    push!(cp.measurementnames, name)
    push!(cp.circuitfilearray, card)
    return true
end
const step1regex = r"[.](?:step)[ ]+(?:oct |param ){0,1}[ ]*([a-z][a-z0-9_@#$.:\\]*)[ ]+(?:list ){0,1}[ ]*[0-9.e+-]+[a-z]*[ ]+"ix
const step2regex = r"[.](?:step)[ ]+(?:\w+)[ ]+(\w+[(]\w+[)])[ ]+"ix
function parsecard!(cp::CircuitParsed, ::Step, card::AbstractString)
    m = match(step1regex, card)
    if m == nothing
        m = match(step2regex, card)
        if m == nothing
            return false # exit if not a step card
        end
    end
    name = m.captures[1] #lowercase(m.captures[1])
    push!(cp.stepnames, name)
    push!(cp.circuitfilearray, card)
    return true
end
function parsecard!(cp::CircuitParsed, ::Other, card::AbstractString)
    push!(cp.circuitfilearray, card)
    return true
end
function parsecard!(cf::CircuitParsed, card::AbstractString)
    for cardtype in cardlist
        if parsecard!(cf,cardtype,card)
          break
        end
    end
end

iscomment(line::AbstractString) = ismatch(r"^TEXT .* ;",line)
function parsecircuitfile(circuitpath::AbstractString)
  cp = CircuitParsed()
  cp.circuitfileencoding = circuitfileencoding(circuitpath)
  open(circuitpath,cp.circuitfileencoding) do io
    for line in eachline(io)
      if iscomment(line)
        push!(cp.circuitfilearray, line)
      else
        for card in eachcard(line) # might be multi-line directive(s) created with Ctrl-M
          parsecard!(cp, card)
        end
      end
    end
  end
  cp.parametervalues.ismodified = false
  return cp
end

function circuitfileencoding(path::AbstractString)
  firstwordshouldbe = "Version"
  encodings = [enc"UTF-8",enc"UTF-16LE"]
  correct_i = 0
  for i in eachindex(encodings)
    open(path,encodings[i]) do io
      if ismatch(r"^Version",readline(io))
        correct_i = i
      end
    end
    correct_i !=0 && break
  end
  correct_i == 0 && error("invalid LTspice circuit file")
  return encodings[correct_i]
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
                   "μ" => 1.0e-6,
                   "N" => 1.0e-9,
                   "n" => 1.0e-9,
                   "P" => 1.0e-12,
                   "p" => 1.0e-12,
                   "F" => 1.0e-15,
                   "f" => 1.0e-15)
