# this module provided an interface to treat the parameters and measurements
# of an LTspice simulation as a dictionary like type

module LTspice

import Base: parse, show
import Base: haskey, keys, values
import Base: getindex, setindex!, endof
import Base: start, next, done, length, eltype

export LTspiceSimulation!, LTspiceSimulation, getmeasurements
export getparameters, getcircuitpath, getltspiceexecutablepath
export getlogpath, getmeasurementnames, getstepnames, getsteps

include("ParseCircuitFile.jl")
include("ParseLogFile.jl")

### BEGIN Type LTspiceSimulation and constructors ###

type LTspiceSimulation!
  circuit         :: CircuitFile
  log             :: LogFile
  executablepath  :: ASCIIString
  logneedsupdate  :: Bool

  function LTspiceSimulation!(circuitpath::ASCIIString, executablepath::ASCIIString)
    (everythingbeforedot,e) = splitext(circuitpath)
    logpath = "$everythingbeforedot.log"  # log file is .log instead of .asc
    circuit = parse(CircuitFile,circuitpath)
    if isstep(circuit)
      log = SteppedLogFile(logpath)  # a blank stepped log object
    else 
      log = NonSteppedLogFile(logpath) # a blank non stepped log object
    end
    new(circuit,log,executablepath,true)
  end
end

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

### END Type LTspice and constructors ###

### BEGIN Overloading Base ###

function show(io::IO, x::LTspiceSimulation!)
  println(io,getcircuitpath(x.circuit))
  println(io,"")
  println(io,"Parameters")
  for (key,value) in x.circuit
    println(io,"$(rpad(key,25,' ')) = $value")
  end
  println(io,"")
  println(io,"Measurements")
  for (i,key) in enumerate(getmeasurementnames(x.circuit))
    if getstepnames(x.circuit) == []
      if x.logneedsupdate
        value = convert(Float64,NaN)
      else
        value = getmeasurements(x.log)[i,1,1,1]
      end
      println(io,"$(rpad(key,25,' ')) = $value")
    else 
      println(io,"$(rpad(key,25,' ')) stepped simulation")
    end
  end
  if getstepnames(x.circuit) != []
    println(io,"")
    println(io,"Sweeps")
    if x.logneedsupdate
      for stepname in getstepnames(x.circuit)
        println(io,"$(rpad(stepname,25,' '))")
      end
    else 
      for (i,stepname) in enumerate(getstepnames(x.circuit))
        println(io,"$(rpad(stepname,25,' ')) $(length(getsteps(x.log)[i])) steps")
      end
    end
  end
end

# LTspiceSimulation! is a Dict 
#   of its parameters and measurements for non stepped simulations (measurements read only)
#   of its parameters for stepped simulations
haskey(x::LTspiceSimulation!, key::ASCIIString) = haskey(x.circuit,key) | haskey(x.log,key)

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
    if x.logneedsupdate
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

function get(x::LTspiceSimulation!, key::ASCIIString, default::Float64)
  # returns value for key in either param or meas
  # returns default if key not found
  if haskey(x,key)
    return(x[key])
  else
    return(default)
  end
end

function setindex!(x::LTspiceSimulation!, value:: Float64, key::ASCIIString)
  # sets the value of param specified by key
  # x[key] = value
  # meas Dict cannot be set.  It is the result of a simulation
  if haskey(x.circuit,key)
    x.logneedsupdate = true
    x.circuit[key] = value
  elseif haskey(x.log,key)
    error("measurements cannot be set.")
  else
    throw(KeyError(key))
  end
end

eltype(x::LTspiceSimulation!) = Float64 
length(x::LTspiceSimulation!) = length(x.log) + length(x.circuit)

### END overloading Base ###

### BEGIN LTspiceSimulation! specific methods ###
 
getcircuitpath(x::LTspiceSimulation!) = getcircuitpath(x.circuit)
getlogpath(x::LTspiceSimulation!) = getlogpath(x.log)
getltspiceexecutablepath(x::LTspiceSimulation!) = x.executablepath
getparameters(x::LTspiceSimulation!) = getparameters(x.circuit)
getmeasurementnames(x::LTspiceSimulation!) = getmeasurementnames(x.circuit)
getstepnames(x::LTspiceSimulation!) = getstepnames(x.circuit)

function getmeasurements(x::LTspiceSimulation!)
  if x.logneedsupdate
    run!(x)
  end
  getmeasurements(x.log)
end

function getsteps(x::LTspiceSimulation!)
  if x.logneedsupdate
    run!(x)
  end
  getsteps(x.log)
end

function run!(x::LTspiceSimulation!)
  # runs simulation and updates measurment values
  update(x.circuit)
  if x.executablepath != ""
    run(`$(getltspiceexecutablepath(x)) -b -Run $(getcircuitpath(x))`)
  end
  x.log = parse(LogFile)
  x.logneedsupdate = false
  return(nothing)
end

### END LTspicesSimulation! specific methods

### BEGIN other

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

### END other

end  # module

