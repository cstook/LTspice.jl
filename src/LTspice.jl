# this module provided an interface to treat the parameters and measurements
# of an LTspice simulation as a dictionary like type

module LTspice

import Base: show, haskey, get, keys, values, getindex, setindex!, start, next, done, length, eltype

export LTspiceSimulation!, LTspiceSimulation, getmeasurements
export getparameters, getcircuitpath, getltspiceexecutablepath

include("ParseCircuitFile.jl")

type LTspiceSimulation!
  executablepath :: ASCIIString                          # include full path and extention
  circuitpath ::  ASCIIString                           # include full path and extention
  logpath :: ASCIIString                               # include full path and extention
  circuitfilearray ::Array{ASCIIString,1}               # text of circuit file
  parameters :: Dict{ASCIIString,Tuple{Float64,Float64,Int}} # dictionay of parameters (value, multiplier, index)
  measurements :: Dict{ASCIIString,Float64}              # dictionary of measurements
  measurements_invalid :: Bool                           # true if simulation needs to be run

  """
  Returns an instance of LTspiceSimulation!.  Changes to parameters will update
  the circuit file.
  """
  
  function LTspiceSimulation!(circuitpath::ASCIIString, executablepath::ASCIIString)
    (everythingbeforedot,e) = splitext(circuitpath)
    logpath = "$everythingbeforedot.log"  # log file is .log instead of .asc
    (p,m,circuitfilearray) = parsecircuitfileOLD(circuitpath)
    new(executablepath,circuitpath,logpath,circuitfilearray,p,m,true)
  end
end

"""
Returns an instance of LTspiceSimulation! after copying the circuit file to
a temporary working directory.  Original circuit file is not modified.
"""
function LTspiceSimulation(circuitpath::ASCIIString, executablepath::ASCIIString)
  td = mktempdir()
  (d,f) = splitdir(circuitpath)
  workingcircuitpath = convert(ASCIIString, joinpath(td,f))
  cp(circuitpath,workingcircuitpath)
  LTspiceSimulation!(workingcircuitpath, executablepath)
end

function LTspiceSimulation(circuitpath::ASCIIString)
  # look up default executable if not specified
  LTspiceSimulation(circuitpath, defaultltspiceexecutable())
end

function LTspiceSimulation!(circuitpath::ASCIIString)
  # look up default executable if not specified
  LTspiceSimulation!(circuitpath, defaultltspiceexecutable())
end


# ****  BEGIN make LTspiceSimulation! an iterator  ****

Base.start(x::LTspiceSimulation!) = (start(x.parameters),start(x.measurements))

function Base.next(x::LTspiceSimulation!, state)
  if ~done(x.parameters,state[1])
    param,paramState = next(x.parameters,state[1])
    return (param,(paramState,state[2]))
  elseif ~done(x.measurements,state[2])
    meas,measState = next(x.measurements,state[2])
    return (meas,(state[1],measState))
  else
    Error("LTspiceSimulation! iterator errror")
  end
end

Base.done(x::LTspiceSimulation!, state) = done(x.parameters,state[1]) & done(x.measurements,state[2])

Base.length(x::LTspiceSimulation!) = length(x.parameters) + length(x.measurements)

Base.eltype(::Type{LTspiceSimulation!}) = Float64

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
  println(io,x.circuitpath)
  println(io,"")
  println(io,"Parameters")
  for (key,(value,m,i)) in x.parameters
    println(io,"$(rpad(key,25,' ')) = $value")
  end
  println(io,"")
  println(io,"measurements")
  for (key,value) in x.measurements
    if x.measurements_invalid
      value = convert(Float64,NaN)
    end
    println(io,"$(rpad(key,25,' ')) = $value")
  end
end

"""
returns path to LTspice executable
"""
function defaultltspiceexecutable()
  possibleltspiceexecutablelocations = [
  "C:\\Program Files (x86)\\LTC\\LTspiceIV\\scad3.exe"
  ]
  for canidatepath in possibleltspiceexecutablelocations
    if ispath(canidatepath)
      return canidatepath
    end
  end
  error("Could not find scad.exe")
end

"""
Returns a Dict of measurements.
"""
function getmeasurements(x::LTspiceSimulation!)
  # returns a Dict of measurement value pairs
  x.measurements
end

"Returns a Dict of parameters"
function getparameters(x::LTspiceSimulation!)
  # returns a Dict of parameter value pairs
  d = Dict{ASCIIString, Float64}()
  for (key,(v,m,i)) in x.parameters
    d[key] =  v
  end
  return d
end

"Returns path of the simulation file"
function getcircuitpath(x::LTspiceSimulation!)
  # returns string specifing simulation file
  x.circuitpath
end

"Returns path of the LTspice executable"
function getltspiceexecutablepath(x::LTspiceSimulation!)
  x.executablepath
end

"Writes parameters back to circuit file. Runs simulation.  Reads measurements from log file."
function run!(x::LTspiceSimulation!)
  # runs simulation and updates meas values
  writecircuitfile(x)
  if x.executablepath != ""
    run(`$(x.executablepath) -b -Run $(x.circuitpath)`)
  end
  readlog!(x)
  x.measurements_invalid = false
  return(nothing)
end

"Parses the log file to update measurements"
function readlog!(x::LTspiceSimulation!)
  # reads simulation log file and updates meas values
  LTspiceLog = readall(x.logpath)
  allMeasures = matchall(r"^(\S+):.*=([0-9e\-+.]+)"m,LTspiceLog)
  for measure in allMeasures
    m =  match(r"^(\S+):.*=([0-9e\-+.]+)"m,measure)
    value = try
      parse(Float64,m.captures[2])
    catch
      (Float64)
    end
    x.measurements[lowercase(m.captures[1])] = value
  end
  return(nothing)
end

"Writes circuit file, with any modified parameters, back to disk"
function writecircuitfile(x::LTspiceSimulation!)
  io = open(x.circuitpath,false,true,false,false,false)  # open circuit file to be overwritten
  for text in x.circuitfilearray
    print(io,text)
  end
  close(io)
end

"""
Parses circuit file and returns Dict of parameters, Dict of measurements, circuit file array.
"""
function parsecircuitfileOLD(circuitpath::ASCIIString)
  # reads circuit file and returns a tuple of
  # Dict of parameters
  # Dict of measurements, values N/A
  # circuit file array
  #     The circuit file array is an array of strings which when concatenated produce the circuit file
  #     The elements of the array split the file around parameter values to avoid parsing the file
  #     every time a parameter is modified

  ltspicefile = readall(circuitpath)            # read the circuit file

  # create empty dictionarys to be filled as file is parsed
  parameters = Dict{ASCIIString,Tuple{Float64,Float64,Int}}()     # Dict of parameters.  key = parameter, value = (parameter value, multiplier, circuit file array index)
  measurements = Dict{ASCIIString,Float64}()                  # Dict of measurements
  circuitfilearray = Array(ASCIIString,1)
  circuitfilearray[1] = ""
  # regex used to parse file.  I know this is a bad comment.
  match_tags = r"""(
                ^TEXT .*?(!|;)|
                [.](param)[ ]+([A-Za-z0-9]*)[= ]*([0-9.eE+-]*)([a-z]*)|
                [.](measure|meas)[ ]+(?:ac|dc|op|tran|tf|noise)[ ]+(\w)[ ]+|
                [.](step)[ ]+(oct |param ){0,1}[ ]*(\w)[ ]+(list ){0,1}[ ]*(([0-9.e+-]*([a-z])*[ ]*)*)
                )"""imx

  # parse the file
  directive = false   # true for directives, false for comments
  m = match(match_tags,ltspicefile)
  i = 1  # index for circuit file array
  position = 1   # pointer into ltspicefile
  old_position = 1
  while m!=nothing
    commentordirective = m.captures[2]    # ";" starts a comment, "!" starts a directive
    isparamater = m.captures[3]!=nothing  # true for parameter card
    parametername = m.captures[4]
    parametervalue = m.captures[5]
    parameterunit = m.captures[6]
    ismeasure = m.captures[7]!=nothing   # true for measurement card
    measurementname = m.captures[8]
    isstep = m.captures[9]!=nothing
    oct_or_param_or_nothing = m.captures[10]
    steppedname = m.captures[11]
    islist = m.captures[12]!=nothing
    stepparameterlist = m.captures[13] # all the values and units.  Needs additional parsing.

    # determine if we are processign a comment or directive
    if commentordirective == "!"
      directive = true
    elseif commentordirective == ";"
      directive = false
    end
    if directive
      if isparamater  # this is a paramater card
        if haskey(units,parameterunit) # if their is an SI unit
          multiplier = units[parameterunit] # find the multiplier
        else
          multiplier = 1.0 # if no unit, multiplier is 1.0
        end
        valuenounit = try  # try to convert the value.  might just want to let the exception happen...
          parse(Float64,parametervalue)
        catch
          convert(Float64,NaN)
        end
        old_position = position
        position = m.offsets[5]   # offset of the begining if the value in the circuit file
        circuitfilearray = vcat(circuitfilearray,ltspicefile[old_position:position-1])  # text before the value
        i += 1
        circuitfilearray = vcat(circuitfilearray,ltspicefile[position:position+length(parametervalue)-1])  # text of the value
        i += 1
        parameters[parametername] = (valuenounit * multiplier, multiplier, i)
        position = position+length(parametervalue)
      end
      if ismeasure  # this is a measurement card
        key = lowercase(measurementname)  # measurements are all lower case in log file
        measurements[key] = convert(Float64,NaN)  # fill out the Dict with 's
      end
      if isstep # this is a step card
        error(".step directive not supported")
      end
    end
    m = match(match_tags,ltspicefile,m.offset+length(m.match))   # find next match
  end
  circuitfilearray = vcat(circuitfilearray,ltspicefile[position:end])  # the rest of the circuit
  return(parameters, measurements, circuitfilearray)
end

function haskey(x::LTspiceSimulation!, key::ASCIIString)
  # true if key is in param or meas
  haskey(x.measurements,key) | haskey(x.parameters,key)
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
  vcat(collect(keys(x.parameters)),collect(keys(x.measurements)))
end

function values(x::LTspiceSimulation!)
  # returns an array of all values (param and meas)
  vcat(collect(values(x.parameters)),collect(values(x.measurements))) # this is wrong
end

function getindex(x::LTspiceSimulation!, key::ASCIIString)
  # returns value for key in either param or meas
  # value = x[key]
  # dosen't handle multiple keys, but neither does standard julia library for Dict
  if haskey(x.measurements,key)
    if x.measurements_invalid
      run!(x)
    end
    v = x.measurements[key]
  elseif haskey(x.parameters,key)
    (v,m,i) = x.parameters[key]
  else
    throw(KeyError(key))
  end
  return(v)
end

function setindex!(x::LTspiceSimulation!, value:: Float64, key::ASCIIString)
  # sets the value of param specified by key
  # x[key] = value
  # meas Dict cannot be set.  It is the result of a simulation
  if haskey(x.parameters,key)
    x.measurements_invalid = true
    (v,m,i) = x.parameters[key]
    x.parameters[key] = (value,m,i)
    x.circuitfilearray[i] = "$(value/m)"
  else
    if haskey(x.measurements,key)
      error("measurements cannot be set.")
    else
      throw(KeyError(key))
    end
  end
end

end  # module
