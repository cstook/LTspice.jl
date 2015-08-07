# this module provided an interface to treat the parameters and measurments
# of an LTspice simulation as a dictionary like type

module LTspice

import Base: show, haskey, get, keys, values, getindex, setindex!, start, next, done, length

export LTspiceSimulation!, LTspiceSimulation,defaultLTspiceExcutable, run!, getMeasurments
export getParameters, getSimulationFile

"""
Let's see what this does.
"""
type LTspiceSimulation!
  excutable ::ASCIIString                               # include full path and extention
  circuit_file  ::ASCIIString                           # include full path and extention
  log_file ::  ASCIIString                              # include full path and extention
  circuit_file_array ::ASCIIString                      # text of circuit file
  param :: Dict{ASCIIString,(Float64,Float64,Int)}      # dictionay of parameters
  meas :: Dict{ASCIIString,Float64}                     # dictionary of measurments
  measurments_invalid :: Bool                           # true if simulation needs to be run

  """
  Returns an instance of LTspiceSimulation!.  Changes to parameters will update
  the circuit file.
  """
  function LTspiceSimulation!(excutable::ASCIIString,circuit_file::ASCIIString)
    (everythingbeforedot,e) = splitext(simulationFile)
    log_file = "$everythingbeforedot.log"  # log file is .log instead of .asc
    (p,m,cfa) = parseCircuitFile(circuit_file)
    new(excutable,circuit_file,log_file,cfa,p,m,true)
  end
end

"""
Returns an instance of LTspiceSimulation! after copying the circuit file to
a temporary working directory.  Original circuit file is not modified.
"""
function LTspiceSimulation(excutable::ASCIIString,simulationFile::ASCIIString)
  td = mktempdir()
  (d,f) = splitdir(simulationFile)
  workingcircuitpath = joinpath(td,f)
  cp(simulationFile,workingcircuitpath)
  LTspiceSimulation!(excutable,workingcircuitpath)
end

# ****  BEGIN make LTspiceSimulation! an iterator  ****

Base.start(x::LTspiceSimulation!) = (start(x.param),start(x.meas))

function Base.next(x::LTspiceSimulation!, state)
  if ~done(x.param,state[1])
    param,paramState = next(x.param,state[1])
    return (param,(paramState,state[2]))
  elseif ~done(x.meas,state[2])
    meas,measState = next(x.meas,state[2])
    return (meas,(state[1],measState))
  else
    Error("LTspiceSimulation! iterator errror")
  end
end

Base.done(x::LTspiceSimulation!, state) = done(x.param,state[1]) & done(x.meas,state[2])

Base.length(x::LTspiceSimulation!) = length(x.param) + length(x.meas)

# **** end make LTspiceSimulation! an iterator ****

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

function show(io::IO, x::LTspiceSimulation!)
  println(io,x.simulationFile)
  println(io,"")
  println(io,"Parameters")
  for (key,value) in x.param
    println(io,"$(rpad(key,25,' ')) = $value")
  end
  println(io,"")
  println(io,"Measurments")
  for (key,value) in x.meas
    if x.measurments_invalid
      value = nan(Float64)
    end
    println(io,"$(rpad(key,25,' ')) = $value")
  end
end

defaultLTspiceExcutable() = "C:\\Program Files (x86)\\LTC\\LTspiceIV\\scad3.exe"

function getMeasurments(x::LTspiceSimulation!)
  # returns a Dict of measurment value pairs
  x.meas
end

function getParameters(x::LTspiceSimulation!)
  # returns a Dict of parameter value pairs
  x.param
end

function getSimulationFile(x::LTspiceSimulation!)
  # returns string specifing simulation file
  x.simulationFile
end

function run!(x::LTspiceSimulation!)
  # runs simulation and updates meas values
  writecircuitfile(x)
  run(`$(x.excutable) -b -Run $(x.simulationFile)`)
  readlog!(x)
  x.measurments_invalid = false
  return(nothing)
end

function readlog!(x::LTspiceSimulation!)
  # reads simulation file and updates meas values
  LTspiceLog = readall(x.log_file)
  allMeasures = matchall(r"^(\S+):.*=([0-9e\-+.]+)"m,LTspiceLog)
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

function writecircuitfile(x::LTspiceSimulation!)
  io = open(x.circuit_file,false,true,false,false,false)  # open circuit file to be overwritten
  for text in x.circuit_file_array
    print(io,text)
  end
  close(io)
end

function parseCircuitFile(simulationFile::ASCIIString)
  # reads circuit file and returns a tuple of
  # Dict of parameters
  # Dict of measurments, values N/A
  # circuit file array
  #     The circuit file array is an array of strings which when concatenated produce the circuit file
  #     The elements of the array split the file around parameter values to avoid parsing the file
  #     every time a parameter is modified

  LTspiceFile = readall(simulationFile)            # read the circuit file

  # create empty dictionarys to be filled as file is parsed
  parameters = Dict{ASCIIString,(Float64,Float64,Int)}()     # Dict of parameters.  key = parameter, value = (parameter value, multiplier, circuit file array index)
  measurments = Dict{ASCIIString,Float64}()                  # Dict of measurments
  CFA = Array(ASCIIString,1)
  CFA[1] = ""
  # regex used to parse file.  I know this is a bad comment.
  match_tags = r"(TEXT .*?(!|;)|.(param|PARAM)[ ]+([A-Za-z0-9]*)[= ]*([0-9.eE+-]*)(.*?)(?:\\n|$)|.(measure|MEASURE|meas|MEAS)[ ]+(?:ac|AC|dc|DC|op|OP|tran|TRAN|tf|TF|noise|NOISE)[ ]+(\S+)[ ]+)"

  # parse the file
  directive = false   # true for directives, false for comments
  m = match(match_tags,LTspiceFile)
  i = 0  # index for circuit file array
  position = 1   # pointer into LTspiceFile
  old_position = 1
  while m!=nothing
    # determine if we are processign a comment or directive
    if m.captures[2] == "!"
      directive = true
    elseif m.captures[2] == ";"
      directive = false
    end
    if directive
      if m.captures[3]!=nothing  # this is a paramater card
        if haskey(units,m.captures[6]) # if their is an SI unit
          multiplier = units[m.captures[6]] # find the multiplier
        else
          multiplier = 1.0 # if no unit, multiplier is 1.0
        end
        value = try  # try to convert the value.  might just want to let the exception happen...
          parsefloat(m.captures[5])
        catch
          nan(Float64)
        end
        old_position = position
        position = m.offsets[5]
        CFA = vcat(CFA,LTspiceFile[old_position:position])  # text before the value
        i += 1
        CFA = vcat(CFA,LTspiceFile[position:m.offsets[5]+length(m.captures[5])-1])  # text of the value
        i += 1
        parameters[m.captures[4]] = (value * multiplier, multiplier, i)
        position = m.offsets[5]+length(m.captures[5])
      end
      if m.captures[7]!=nothing  # this is a measurment card
        measurments[m.captures[8]] = nan(Float64)  # fill out the Dict with nan's
      end
    end
    m = match(match_tags,LTspiceFile,m.offset+length(m.match))   # find next match
  end
  CFA = vcat(CFA,LTspiceFile[position:])  # the rest of the circuit
  return(parameters, measurments, CFA)
end

function haskey(x::LTspiceSimulation!, key::ASCIIString)
  # true if key is in param or meas
  haskey(x.meas,key) | haskey(x.param,key)
end

function get(x::LTspiceSimulation!, key::ASCIIString, default::Float64)
  # returns value for key in either param or meas
  # returns default if key not found
  if haskey(x,key)
    return(x[key])
  else
    return(default)
  end
end

function keys(x::LTspiceSimulation!)
  # returns an array all keys (param and meas)
  vcat(collect(keys(x.param)),collect(keys(x.meas)))
end

function values(x::LTspiceSimulation!)
  # returns an array of all values (param and meas)
  vcat(collect(values(x.param)),collect(values(x.meas)))
end

function getindex(x::LTspiceSimulation!, key::ASCIIString)
  # returns value for key in either param or meas
  # value = x[key]
  # dosen't handle multiple keys, but neither does standard julia library for Dict
  if haskey(x.meas,key)
    if x.measurments_invalid
      run!(x)
    end
    (v,m,i) = x.meas[key]
    return(v)
  elseif haskey(x.param,key)
    (v,m,i) = x.param[key]
    return(v)
  else
    throw(KeyError(key))
  end
end

function setindex!(x::LTspiceSimulation!, value:: Float64, key::ASCIIString)
  # sets the value of param specified by key
  # x[key] = value
  # meas Dict cannot be set.  It is the result of a simulation
  if haskey(x.param,key)
    x.measurments_invalid = true
    (v,m,i) = x.param[key]
    x.param[key] = (value,m,i)
    x.circuit_file_array[i] = "$(value/m)"
  else
    if haskey(x.meas,key)
      error("measurments cannot be set.  Use run! to update")
    else
      throw(KeyError(key))
    end
  end
end

end  # module
