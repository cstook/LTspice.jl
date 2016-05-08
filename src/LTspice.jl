# this module provided an interface to treat the parameters and measurements
# of an LTspice simulation as a dictionary like type

"Main module for `LTspice.jl` - a Julia interface to LTspice"
module LTspice

import Base: parse, show
import Base: haskey, keys, values
import Base: getindex, setindex!, get, endof
import Base: start, next, done, length, eltype
import Base: call, flush, run

export LTspiceSimulation, LTspiceSimulationTempDir, getmeasurements
export getparameters, getcircuitpath, getltspiceexecutablepath
export getlogpath, getmeasurementnames, getstepnames, getsteps
export PerLineIterator, getparameternames
export loadlog!

const islinux = @linux? true:false
const iswindows = @windows? true:false
const isosx = @osx? true:false

include("mcfiap.jl")
include("ParseCircuitFile.jl")
include("ParseLogFile.jl")
include("removetempdirectories.jl")

### BEGIN Type LTspiceSimulationTempDir and constructors ###
type LTspiceSimulation
  circuit         :: CircuitFile
  log             :: LogFile
  executablepath  :: ASCIIString
  logneedsupdate  :: Bool

  function LTspiceSimulation(circuitpath::ASCIIString,
                              executablepath::ASCIIString)
    islinux = @linux? true:false
    if islinux
      (d,f) = splitdir(abspath(circuitpath))
      linkdir = "/home/$(ENV["USER"])/.wine/drive_c/Program Files (x86)/LTC/LTspice.jl_links"
      if ~isdir(linkdir)
        mkpath(linkdir)
      end
      push!(dirlist,linkdir)  # delete this on exit
      templinkdir = mktempdir(linkdir)
      cd(templinkdir) do
        symlink(d,"linktocircuit")
      end
      circuitpath = convert(ASCIIString,joinpath(templinkdir,"linktocircuit",f))
    end
    circuit = parse(CircuitFile,circuitpath)
    (everythingbeforedot,dontcare) = splitext(circuitpath)
    logpath = "$everythingbeforedot.log"  # log file is .log instead of .asc
    log = blanklog(circuit,logpath) # creates a blank log object
    new(circuit,log,executablepath,true)
  end
end

function LTspiceSimulationTempDir(circuitpath::ASCIIString, executablepath::ASCIIString)
  td = mktempdir()
  push!(dirlist,td) # add temp directory to list to be removed on exit
  (d,f) = splitdir(circuitpath)
  workingcircuitpath = convert(ASCIIString, joinpath(td,f))
  cp(circuitpath,workingcircuitpath)
  makecircuitfileincludeabsolutepath(circuitpath,workingcircuitpath,executablepath)
  LTspiceSimulation(workingcircuitpath,
                     executablepath)
end

function LTspiceSimulationTempDir(circuitpath::ASCIIString)
  # look up default executable if not specified
  LTspiceSimulationTempDir(circuitpath, defaultltspiceexecutable())
end

function LTspiceSimulation(circuitpath::ASCIIString)
  # look up default executable if not specified
  LTspiceSimulation(circuitpath, defaultltspiceexecutable())
end

"""

```julia
LTspiceSimulation(circuitpath)
LTspiceSimulation(circuitpath, executablepath)
```

Creates an `LTspiceSimulation` object.    `circuitpath` and `execuatblepath` 
are the path to the circuit file (.asc) and the LTspice executable.  Operations 
on `LTspiceSimulation` will modify the circuit file.

If `executablepath` is not specified, an attempt will be made to find it in the default
location for your operating system.
"""
LTspiceSimulation

"""

```julia
LTspiceSimulationTempDir(circuitpath)
LTspiceSimulationTempDir(circuitpath, executablepath)
```

Same as `LTspiceSimulation` except creates an object which works on a copy of 
the circuit in a temporary directory. LTspice will need to be able to find all
 sub-circuits and libraries from the temporary directory or the simulation will not run.  
   Anything included with .include or .lib directives will be changed to work 
 correctly in temp directory.
"""
LTspiceSimulationTempDir

### END Type LTspice and constructors ###

include("PerLineIterator.jl")  # for delimited output

### BEGIN Overloading Base ###

function show(io::IO, x::LTspiceSimulation)
  println(io,"LTspiceSimulation:")
  println(io,"circuit path = $(getcircuitpath(x.circuit))")
  if hasparameters(x.circuit)
    println(io,"")
    println(io,"Parameters")
    for (key,value) in x.circuit
      println(io,"$(rpad(key,25,' ')) = $value")
    end
  end
  if hasmeasurements(x.circuit)
    println(io,"")
    println(io,"Measurements")
    for (i,key) in enumerate(getmeasurementnames(x.circuit))
      if getstepnames(x.circuit) == []
        if x.logneedsupdate
          value = convert(Float64,NaN)
        elseif haskey(x.log,key)
          value = x.log[key] #getmeasurements(x.log)[i,1,1,1]
        else
          value = "measurement failed"
        end
        println(io,"$(rpad(key,25,' ')) = $value")
      else 
        println(io,"$(rpad(key,25,' ')) stepped simulation")
      end
    end
  end
  if hassteps(x.circuit)
    println(io,"")
    println(io,"Sweeps")
    if x.logneedsupdate
      for stepname in getstepnames(x)
        println(io,"$(rpad(stepname,25,' '))")
      end
    else 
      for (i,stepname) in enumerate(getstepnames(x))
        println(io,"$(rpad(stepname,25,' ')) $(length(getsteps(x.log)[i])) steps")
      end
    end
  end
end

# LTspiceSimulation is a Dict 
#   of its parameters and measurements for non stepped simulations (measurements read only)
#   of its parameters for stepped simulations
haskey(x::LTspiceSimulation, key::ASCIIString) = haskey(x.circuit,key) | haskey(x.log,key)

function keys(x::LTspiceSimulation)
  # returns an array all keys (param and meas)
  vcat(collect(keys(x.circuit)),collect(keys(x.log)))
end

  # returns an array of all values (param and meas)
function values(x::LTspiceSimulation)
  run(x)
  vcat(collect(values(x.circuit)),collect(values(x.log)))
end

function getindex(x::LTspiceSimulation, key::ASCIIString)
  # returns value for key in either param or meas
  # value = x[key]
  # dosen't handle multiple keys, but neither does standard julia library for Dict
  if findfirst(getmeasurementnames(x),key) > 0
    run(x)
    v = x.log[key]
  elseif haskey(x.circuit,key)
    v = x.circuit[key]
  else
    throw(KeyError(key))
  end
  return(v)
end

function get(x::LTspiceSimulation, key::ASCIIString, default:: Float64)
  # returns value for key in either param or meas
  # returns default if key not found
  if haskey(x,key)
    return(x[key])
  else
    return(default)
  end
end

function setindex!(x::LTspiceSimulation, value:: Float64, key::ASCIIString)
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

function setindex!(x::LTspiceSimulation, value:: Float64, index:: Int)
  x.logneedsupdate = true 
  x.circuit[index] = value 
end

# LTspiceSimulationTempDir is an read only array of its measurements
# Intended for use in interactive sessions only.
# For type stablity use getmeasurements()
function getindex(x::LTspiceSimulation,index::Int)
  run(x)
  x.log[index]
end
function getindex(x::LTspiceSimulation, i1::Int, i2::Int, i3::Int, i4::Int)
  run(x)
  x.log[i1,i2,i3,i4] 
end

eltype(x::LTspiceSimulation) = Float64 
length(x::LTspiceSimulation) = length(x.log) + length(x.circuit)

function call(x::LTspiceSimulation, args...)
  if length(args) != length(x.circuit)
    throw(ArgumentError("number of arguments must match number of parameters"))
  end
  if typeof(x.log) == Type(SteppedLogFile)
    error("call only for non stepped simulations")
  end
  for (i,arg) in enumerate(args)
    x[i] = arg::Float64 
  end
  return getmeasurements(x)[:,1,1,1]
end

### END overloading Base ###

### BEGIN LTspiceSimulation specific methods ###
"""
```julia
getcircuitpath(sim)
```
Returns path to the circuit file.

This is the path to the working circuit file.  If LTspiceSimulationTempDir was used 
or if running under wine, this will not be the path given to the constructor.
""" 
getcircuitpath(x::LTspiceSimulation) = getcircuitpath(x.circuit)

"""
```julia
getlogpath(sim)
```
Returns path to the log file.
"""
getlogpath(x::LTspiceSimulation) = getlogpath(x.log)

"""
```julia
getltspiceexecutablepath(sim)
```
Returns path to the LTspice executable
"""
getltspiceexecutablepath(x::LTspiceSimulation) = x.executablepath

"""
```julia
getparameternames(sim)
```
Returns an array of the parameters names of `sim` in the order they appear in the
circuit file.
"""
getparameternames(x::LTspiceSimulation) = getparameternames(x.circuit)

"""
```julia
getparameters(sim)
```
Returns an array of the parameters of `sim` in the order they appear in the
circuit file
"""
getparameters(x::LTspiceSimulation) = getparameters(x.circuit)

"""
```julia
getmeasurmentnames(sim)
```
Returns an array of the measurement names of `sim` in the order they appear in the
circuit file.
"""
getmeasurementnames(x::LTspiceSimulation) = getmeasurementnames(x.circuit)

"""
```julia
getstepnames(sim)
```
Returns an array of step names of `sim`.
"""
getstepnames(x::LTspiceSimulation) = getstepnames(x.circuit)

"""
```julia
loadlog!(sim)
```
Loads log file of `sim` without running simulation.
"""
function loadlog!(x::LTspiceSimulation)
# loads log file without running simulation
# sets logneedsupdate to false
  x.log = parse(x.log)
  x.logneedsupdate = false
  return nothing
end
"""
```julia
getmeasurments(sim)
```
Retruns measurments of `sim` as an a 4-d array of Float64
values.

```julia
value = getmeasurements(sim)[measurement_name, inner_step, middle_step,
                        outer_step]
``` 
"""
function getmeasurements(x::LTspiceSimulation)
  run(x)
  getmeasurements(x.log)
end
"""
```julia
getsteps(sim)
```
Returns the steps of `sim` as a tuple of three arrays of 
the step values.
"""
function getsteps(x::LTspiceSimulation)
  run(x)
  getsteps(x.log)
end

"""
```julia
run(sim)
```
Checks if log file is up to date, if not runs `sim`.
"""
function run(x::LTspiceSimulation)
  # runs simulation and updates measurement values
  if x.logneedsupdate
    flush(x.circuit)
    if (x.executablepath != "")  # so travis dosen't need to load LTspice
      islinux = @linux? true:false
      if islinux
        drive_c = "/home/$(ENV["USER"])/.wine/drive_c"
        winecircuitpath = joinpath("C:",relpath(getcircuitpath(x),drive_c))
        run(`$(getltspiceexecutablepath(x)) -b -Run $winecircuitpath`)
      else
        run(`$(getltspiceexecutablepath(x)) -b -Run $(getcircuitpath(x))`)
      end
    end
    x.log = parse(x.log)
    x.logneedsupdate = false
    return(nothing)
  end
end

"""
```julia
flush(sim)
```
Writes `sim`'s circuit file back to disk if any parameters have changed.  The 
user does not usualy need to call this.  It will be called automatically
 when a measurment is requested and the log file needs to be updated.  It can be used
 to update a circuit file using julia for simulation with the LTspice GUI.  
"""
flush(x::LTspiceSimulation) = flush(x.circuit)

### END LTspicesSimulation! specific methods

### BEGIN other

"creates a blank log object of appropiate type for circuitfile"
function blanklog(circuit::CircuitFile, logpath::ASCIIString)
  if hassteps(circuit)
    log = SteppedLogFile(logpath)  # a blank stepped log object
  else 
    log = NonSteppedLogFile(logpath) # a blank non stepped log object
  end
  return log
end

"""
```julia
defaultltspiceexecutable()
```
returns the default LTspice executable path for the operating system
"""
function defaultltspiceexecutable()
  os = @windows? 1 : (@osx? 2 : 3)
  if os == 1 # windows
    possibleltspiceexecutablelocations = [
    "C:\\Program Files (x86)\\LTC\\LTspiceIV\\scad3.exe",
    "C:\\Program Files\\LTC\\LTspiceIV\\scad3.exe"
    ]
  elseif os == 2 # osx
    possibleltspiceexecutablelocations = [
    "/Applications/LTspice.app/Contents/MacOS/LTspice"]
  else # linux
    possibleltspiceexecutablelocations = [
    "/home/$(ENV["USER"])/.wine/drive_c/Program Files (x86)/LTC/LTspiceIV/scad3.exe"]
  end
  for canidatepath in possibleltspiceexecutablelocations
    if ispath(canidatepath)
      return canidatepath
    end
  end
  error("Could not find LTspice executable")
end

### END other ###

end  # module

