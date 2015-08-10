# this module provided an interface to treat the parameters and measurements
# of an LTspice simulation as a dictionary like type

module LTspice

import Base: show, haskey, get, keys, values, getindex, setindex!, start, next, done, length

export ltspicesimulation!, ltspicesimulation, getmeasurements
export getparameters, getcircuitpath, getltspiceexecutablepath

type ltspicesimulation!
  executablepath ::ASCIIString                          # include full path and extention
  circuitpath ::  ASCIIString                           # include full path and extention
  logpath ::  ASCIIString                               # include full path and extention
  circuitfilearray ::Array{ASCIIString,1}               # text of circuit file
  parameters :: Dict{ASCIIString,(Float64,Float64,Int)} # dictionay of parameters (value, multiplier, index)
  measurements :: Dict{ASCIIString,Float64}              # dictionary of measurements
  measurements_invalid :: Bool                           # true if simulation needs to be run

  """
  Returns an instance of ltspicesimulation!.  Changes to parameters will update
  the circuit file.
  """
  function ltspicesimulation!(circuitpath::ASCIIString, executablepath::ASCIIString)
    (everythingbeforedot,e) = splitext(circuitpath)
    logpath = "$everythingbeforedot.log"  # log file is .log instead of .asc
    (p,m,cfa) = parseCircuitFile(circuitpath)
    new(executablepath,circuitpath,logpath,cfa,p,m,true)
  end
end

"""
Returns an instance of ltspicesimulation! after copying the circuit file to
a temporary working directory.  Original circuit file is not modified.
"""
function ltspicesimulation(circuitpath::ASCIIString, executablepath::ASCIIString)
  td = mktempdir()
  (d,f) = splitdir(circuitpath)
  workingcircuitpath = joinpath(td,f)
  cp(circuitpath,workingcircuitpath)
  ltspicesimulation!(workingcircuitpath, executablepath)
end

function ltspicesimulation(circuitpath::ASCIIString)
  # look up default executable if not specified
  ltspicesimulation(circuitpath, defaultltspiceexecutable())
end

function ltspicesimulation!(circuitpath::ASCIIString)
  # look up default executable if not specified
  ltspicesimulation!(circuitpath, defaultltspiceexecutable())
end


# ****  BEGIN make ltspicesimulation! an iterator  ****

Base.start(x::ltspicesimulation!) = (start(x.parameters),start(x.measurements))

function Base.next(x::ltspicesimulation!, state)
  if ~done(x.parameters,state[1])
    param,paramState = next(x.parameters,state[1])
    return (param,(paramState,state[2]))
  elseif ~done(x.measurements,state[2])
    meas,measState = next(x.measurements,state[2])
    return (meas,(state[1],measState))
  else
    Error("ltspicesimulation! iterator errror")
  end
end

Base.done(x::ltspicesimulation!, state) = done(x.parameters,state[1]) & done(x.measurements,state[2])

Base.length(x::ltspicesimulation!) = length(x.parameters) + length(x.measurements)

# **** end make ltspicesimulation! an iterator ****

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

function show(io::IO, x::ltspicesimulation!)
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
      value = nan(Float64)
    end
    println(io,"$(rpad(key,25,' ')) = $value")
  end
end

"""
returns "C:\\Program Files (x86)\\LTC\\LTspiceIV\\scad3.exe"
which is correct for a windows system
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
function getmeasurements(x::ltspicesimulation!)
  # returns a Dict of measurement value pairs
  x.measurements
end

"Returns a Dict of parameters"
function getparameters(x::ltspicesimulation!)
  # returns a Dict of parameter value pairs
  d = Dict{ASCIIString, Float64}()
  for (key,(v,m,i)) in x.parameters
    d[key] =  v
  end
  return d
end

"Returns path of the simulation file"
function getcircuitpath(x::ltspicesimulation!)
  # returns string specifing simulation file
  x.circuitpath
end

"Returns path of the LTspice executable"
function getltspiceexecutablepath(x::ltspicesimulation!)
  x.executablepath
end

"Writes parameters back to circuit file. Runs simulation.  Reads measurements from log file."
function run!(x::ltspicesimulation!)
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
function readlog!(x::ltspicesimulation!)
  # reads simulation log file and updates meas values
  LTspiceLog = readall(x.logpath)
  allMeasures = matchall(r"^(\S+):.*=([0-9e\-+.]+)"m,LTspiceLog)
  for measure in allMeasures
    m =  match(r"^(\S+):.*=([0-9e\-+.]+)"m,measure)
    value = try
      parsefloat(m.captures[2])
    catch
      nan(Float64)
    end
    x.measurements[lowercase(m.captures[1])] = value
  end
  return(nothing)
end

"Writes circuit file, with any modified parameters, back to disk"
function writecircuitfile(x::ltspicesimulation!)
  io = open(x.circuitpath,false,true,false,false,false)  # open circuit file to be overwritten
  for text in x.circuitfilearray
    print(io,text)
  end
  close(io)
end

"""
Parses circuit file and returns Dict of parameters, Dict of measurements, circuit file array.
"""
function parseCircuitFile(circuitpath::ASCIIString)
  # reads circuit file and returns a tuple of
  # Dict of parameters
  # Dict of measurements, values N/A
  # circuit file array
  #     The circuit file array is an array of strings which when concatenated produce the circuit file
  #     The elements of the array split the file around parameter values to avoid parsing the file
  #     every time a parameter is modified

  LTspiceFile = readall(circuitpath)            # read the circuit file

  # create empty dictionarys to be filled as file is parsed
  parameters = Dict{ASCIIString,(Float64,Float64,Int)}()     # Dict of parameters.  key = parameter, value = (parameter value, multiplier, circuit file array index)
  measurements = Dict{ASCIIString,Float64}()                  # Dict of measurements
  CFA = Array(ASCIIString,1)
  CFA[1] = ""
  # regex used to parse file.  I know this is a bad comment.
  match_tags = r"(TEXT .*?(!|;)|.(param|PARAM)[ ]+([A-Za-z0-9]*)[= ]*([0-9.eE+-]*)(.*?)(?:\\n|$)|.(measure|MEASURE|meas|MEAS)[ ]+(?:ac|AC|dc|DC|op|OP|tran|TRAN|tf|TF|noise|NOISE)[ ]+(\S+)[ ]+)"m

  # parse the file
  directive = false   # true for directives, false for comments
  m = match(match_tags,LTspiceFile)
  i = 1  # index for circuit file array
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
        CFA = vcat(CFA,LTspiceFile[old_position:position-1])  # text before the value
        i += 1
        CFA = vcat(CFA,LTspiceFile[position:m.offsets[5]+length(m.captures[5])-1])  # text of the value
        i += 1
        parameters[m.captures[4]] = (value * multiplier, multiplier, i)
        position = m.offsets[5]+length(m.captures[5])
      end
      if m.captures[7]!=nothing  # this is a measurement card
        key = lowercase(m.captures[8])  # measurements are all lower case in log file
        measurements[key] = nan(Float64)  # fill out the Dict with nan's
      end
    end
    m = match(match_tags,LTspiceFile,m.offset+length(m.match))   # find next match
  end
  CFA = vcat(CFA,LTspiceFile[position:end])  # the rest of the circuit
  return(parameters, measurements, CFA)
end

function haskey(x::ltspicesimulation!, key::ASCIIString)
  # true if key is in param or meas
  haskey(x.measurements,key) | haskey(x.parameters,key)
end

function get(x::ltspicesimulation!, key::ASCIIString, default::Float64)
  # returns value for key in either param or meas
  # returns default if key not found
  if haskey(x,key)
    return(x[key])
  else
    return(default)
  end
end

function keys(x::ltspicesimulation!)
  # returns an array all keys (param and meas)
  vcat(collect(keys(x.parameters)),collect(keys(x.measurements)))
end

function values(x::ltspicesimulation!)
  # returns an array of all values (param and meas)
  vcat(collect(values(x.parameters)),collect(values(x.measurements)))
end

function getindex(x::ltspicesimulation!, key::ASCIIString)
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

function setindex!(x::ltspicesimulation!, value:: Float64, key::ASCIIString)
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
      error("measurements cannot be set.  Use run! to update")
    else
      throw(KeyError(key))
    end
  end
end

end  # module
