# this module provided an interface to treat the parameters and measurments
# of an LTspice simulation as a dictionary like type

module LTspice

import Base: show, haskey, get, keys, values, getindex, setindex!, start, next, done, length

export LTspiceSimulation, defaultLTspiceExcutable, run!, getMeasurments
export getParameters, getSimulationFile


type LTspiceSimulation
  excutable ::ASCIIString               # include path
  simulationFile  ::ASCIIString         # include full path and extention
  logFile ::  ASCIIString               # include full path and extention
  LTspiceFile ::ASCIIString             # text of circuit file
  LTspiceLog ::ASCIIString              # text of log file
  param :: Dict{ASCIIString,Float64}    # dictionay of parameters
  meas :: Dict{ASCIIString,Float64}     # dictionary of measurments

  function LTspiceSimulation(excutable::ASCIIString,simulationFile::ASCIIString)
    LTspiceFile = readall(simulationFile)
    logFile = "$(match(r"(.*?)\.",simulationFile).captures[1]).log"
    LTspiceLog = ""
    param = getParam(LTspiceFile)
    meas = getMeasKeys(LTspiceFile)
    new(excutable,simulationFile,logFile,LTspiceFile,LTspiceLog,param,meas)
  end
end

# ****  BEGIN make LTspiceSimulation an iterator  ****

Base.start(x::LTspiceSimulation) = (start(x.param),start(x.meas))

function Base.next(x::LTspiceSimulation, state)
  if ~done(x.param,state[1])
    param,paramState = next(x.param,state[1])
    return (param,(paramState,state[2]))
  elseif ~done(x.meas,state[2])
    meas,measState = next(x.meas,state[2])
    return (meas,(state[1],measState))
  else
    Error("LTspiceSimulation iterator errror")
  end
end

Base.done(x::LTspiceSimulation, state) = done(x.param,state[1]) & done(x.meas,state[2])

Base.length(x::LTspiceSimulation) = length(x.param) + length(x.meas)

# **** end make LTspiceSimulation an iterator ****

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

function show(io::IO, x::LTspiceSimulation)
  println(io,x.simulationFile)
  println(io,"")
  println(io,"Parameters")
  for (key,value) in x.param
    println(io,"$(rpad(key,25,' ')) = $value")
  end
  println(io,"")
  println(io,"Measurments")
  for (key,value) in x.meas
    println(io,"$(rpad(key,25,' ')) = $value")
  end
end

defaultLTspiceExcutable() = "C:\\Program Files (x86)\\LTC\\LTspiceIV\\scad3.exe"

function getMeasurments(x::LTspiceSimulation)
  # returns a Dict of measurment value pairs
  x.meas
end

function getParameters(x::LTspiceSimulation)
  # returns a Dict of parameter value pairs
  x.param
end

function getSimulationFile(x::LTspiceSimulation)
  # returns string specifing simulation file
  x.simulationFile
end

function run!(x::LTspiceSimulation)
  # runs simulation and updates meas values
  run(`$(x.excutable) -b -Run $(x.simulationFile)`)
  readlog!(x)
  return(nothing)
end

function readlog!(x::LTspiceSimulation)
  # reads simulation file and updates meas values
  x.LTspiceLog = readall(x.logFile)
  allMeasures = matchall(r"^(\S+):.*=([0-9e\-+.]+)"m,x.LTspiceLog)
  for measure in allMeasures
    m =  match(r"^(\S+):.*=([0-9e\-+.]+)"m,measure)
    value = try
      parsefloat(m.captures[2])
    catch
      nan(Float64)
    end
    x.meas[lowercase(m.captures[1])] = value
  end
  return(nothing)
end

function readfile!(x::LTspiceSimulation)
  x.LTspiceFile = readall(x.simulationFile)
  return(nothing)
end

function getMeasKeys(LTspiceFile::ASCIIString)
  # reads circuit file (LTspiceFile) and returns dict with
  # keys for meas directives, values all nan:Float64
  measDict = Dict{ASCIIString,Float64}()
  measOrComments = matchall(r"(;|!|\\n)\.(?:measure|MEASURE|meas|MEAS)[ ]+(?:ac|AC|dc|DC|op|OP|tran|TRAN|tf|TF|noise|NOISE)[ ]+(\S+)[ ]+"mi,LTspiceFile)
  spiceDirective = false
  for canidateMeas in measOrComments
    m = match(r"(;|!|\\n)\.(?:measure|MEASURE|meas|MEAS)[ ]+(?:ac|AC|dc|DC|op|OP|tran|TRAN|tf|TF|noise|NOISE)[ ]+(\S+)[ ]+"i,canidateMeas)
    if m.captures[1] == "!"
      spiceDirective = true
    end
    if m.captures[1] == ";"
      spiceDirective = false
    end
    if spiceDirective
      measDict[lowercase(m.captures[2])]=nan(Float64)
    end
  end
  return(measDict)
end

function getParam(LTspiceFile::ASCIIString)
  # reads circuit file (LTspiceFile) and returns dict of
  # simulation parameters, keys and values
  # note: will only find parameters without units
  paramDict = Dict{ASCIIString,Float64}()
  paramOrCommentBlocks = matchall(r"(!|\\n)\.(?:param|PARAM).*+$"mi,LTspiceFile)
  for block in paramOrCommentBlocks
    paramCardsInBlock = matchall(r"\.param.*?(\\n|$)"mi,block)
    for paramCard in paramCardsInBlock
      x = match(r".(?:param|PARAM)[ ]+([A-Za-z0-9]*)[= ]*([0-9.eE+-]*)(.*?)(?:\\n|$)",paramCard)
      if x != nothing
        value = try
          parsefloat(x.captures[2])
        catch
          nan(Float64)
        end
        if !isnan(value)
          si = match(r"(K|k|MEG|meg|G|g|T|t|M|m|U|u|N|n|P|p|F|f).*?",x.captures[3])
          if si!=nothing
            si_multiplier = units[si.captures[1]]
          else
            si_multiplier = 1.0
          end
          paramDict[x.captures[1]]=value * si_multiplier
        end
      end
    end
  end
  return(paramDict)
end


function haskey(x::LTspiceSimulation, key::ASCIIString)
  # true if key is in param or meas
  haskey(x.meas,key) | haskey(x.param,key)
end

function get(x::LTspiceSimulation, key::ASCIIString, default::Float64)
  # returns value for key in either param or meas
  # returns default if key not found
  if haskey(x,key)
    return(x[key])
  else
    return(default)
  end
end

function keys(x::LTspiceSimulation)
  # returns an array all keys (param and meas)
  vcat(collect(keys(x.param)),collect(keys(x.meas)))
end

function values(x::LTspiceSimulation)
  # returns an array of all values (param and meas)
  vcat(collect(values(x.param)),collect(values(x.meas)))
end

function getindex(x::LTspiceSimulation, key::ASCIIString)
  # returns value for key in either param or meas
  # value = x[key]
  # dosen't handle multiple keys, but neither does standard julia library for Dict
  if haskey(x.meas,key)
    return(x.meas[key])
  elseif haskey(x.param,key)
    return(x.param[key])
  else
    throw(KeyError(key))
  end
end

function setindex!(x::LTspiceSimulation, value:: Float64, key::ASCIIString)
  # sets the value of param specified by key
  # x[key] = value
  # meas Dict cannot be set.  It is the result of a simulation
  if haskey(x.param,key)
    x.param[key] = value
    newFile = modifyLTspiceFile(x.LTspiceFile,value,key)
    x.LTspiceFile = newFile
    outIO = open("$(x.simulationFile)","w")
    print(outIO,newFile)
    close(outIO)
  else
    if haskey(x.meas,key)
      error("measurments cannot be set.  Use run! to update")
    else
      throw(KeyError(key))
    end
  end
end

function modifyLTspiceFile(LTspiceFile::ASCIIString,newValue::Float64,parameterToModify::ASCIIString)
  re = Regex("^TEXT.*[!][.](?:param|PARAM)[ ]+.*$(parameterToModify)[ =]+([0-9e\\-+.]+)","mi")
  a = match(re,LTspiceFile)
  if typeof(a) == Nothing
    error("$(parameterToModify) not found")
    return(LTspiceFile)
  else
    front = LTspiceFile[1:a.offsets[1]-1]
    back  = LTspiceFile[a.offsets[1]+length(a.captures[1]):end]
    newLTspiceFile = "$front$newValue$back"
    return(newLTspiceFile)
  end
end


end  # module
