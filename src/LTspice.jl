# this module provided an interface to treat the parameters and measurements
# of an LTspice simulation as a dictionary like type

module LTspice

import Base: show, haskey, get, keys, values, getindex, setindex!, start, next, done, length, eltype

export LTspiceSimulation!, LTspiceSimulation, getmeasurements
export getparameters, getcircuitpath, getltspiceexecutablepath

include("ParseCircuitFile.jl")
include("ParseLogFile.jl")

type LTspiceSimulation!
  circuit         :: CircuitFile
  log             :: LogFile
  executablepath  :: ASCIIString   
  function LTspiceSimulation!(circuitpath::ASCIIString, executablepath::ASCIIString)
    (everythingbeforedot,e) = splitext(circuitpath)
    logpath = "$everythingbeforedot.log"  # log file is .log instead of .asc
    circuit = parse(CircuitFile,circuitpath)
    log = LogFile(logpath)
    new(circuit,log,executablepath)
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

function show(io::IO, x::LTspiceSimulation!)
  println(io,getcircuitpath(x.circuit))
  println(io,"")
  println(io,"Parameters")
  for (key,value) in x.circuit
    println(io,"$(rpad(key,25,' ')) = $value")
  end
  println(io,"")
  println(io,"measurements")
  for (i,key) in enumerate(getmeasurementnames(x.circuit))
    if isneedsupdate(x.circuit) #| length(getmeasurements(x.log))==0
      value = convert(Float64,NaN)
    elseif ~isstep(x.log)
      value = getmeasurements(x.log)[i,1,1,1]
    else 
      value = "stepped simulation"
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

getmeasurements(x::LTspiceSimulation!) = getmeasurments(x.log)
getparameters(x::LTspiceSimulation!) = getparameters(x.circuit)
getcircuitpath(x::LTspiceSimulation!) = getcircuitpath(x.circuit)
getltspiceexecutablepath(x::LTspiceSimulation!) = x.executablepath
getlogpath(x::LTspiceSimulation!) = getlogpath(x.log)

function run!(x::LTspiceSimulation!)
  # runs simulation and updates measurment values
  update(x.circuit)
  if x.executablepath != ""
    run(`$(getltspiceexecutablepath(x)) -b -Run $(getcircuitpath(x))`)
  end
  x.log = parse(LogFile, getlogpath(x))
  return(nothing)
end

haskey(x::LTspiceSimulation!, key::ASCIIString) = haskey(x.circuit,key) | haskey(x.log,key)

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
  vcat(collect(keys(x.circuit)),collect(keys(x.log)))
end

function values(x::LTspiceSimulation!)
  # returns an array of all values (param and meas)
  vcat(collect(values(x.circuit)),collect(values(x.log))) # this is wrong
end

function getindex(x::LTspiceSimulation!, key::ASCIIString)
  # returns value for key in either param or meas
  # value = x[key]
  # dosen't handle multiple keys, but neither does standard julia library for Dict
  if findfirst(getmeasurementnames(x.circuit),key) != 0
    if isneedsupdate(x.circuit)
      run!(x)
    end
    v = x.log[key]
  elseif haskey(x.circuit,key)
    v = x.circuit[key]
  else
    throw(KeyError(key))
  end
  return(v)
end

function setindex!(x::LTspiceSimulation!, value:: Float64, key::ASCIIString)
  # sets the value of param specified by key
  # x[key] = value
  # meas Dict cannot be set.  It is the result of a simulation
  if haskey(x.circuit,key)
    x.circuit[key] = value
  elseif haskey(x.log,key)
    error("measurements cannot be set.")
  else
    throw(KeyError(key))
  end
end

eltype(x::LTspiceSimulation!) = Float64 
length(x::LTspiceSimulation!) = length(x.log) + length(x.circuit)

end  # module
