# this module provided an interface to treat the parameters and measurements
# of an LTspice simulation as a dictionary like type

"Main module for `LTspice.jl` - a Julia interface to LTspice"
module LTspice

export LTspiceSimulation, LTspiceSimulationTempDir, measurements
export parametervalues, circuitpath, ltspiceexecutablepath
export logpath, measurementnames, stepnames, steps
export PerLineIterator, parameternames
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

circuit(x::LTspiceSimulation) = x.circuit
log(x::LTspiceSimulation) = x.log
function measurements(x::LTspiceSimulation)
  runifneedsupdate!(x)
  measurements(log(x))
end
parameters(x::LTspiceSimulation) = parameters(circuit(x))
parametervalues(x::LTspiceSimulation) = parametervalues(circuit(x))
parameternames(x::LTspiceSimulation) = parameternames(circuit(x))
circuitpath(x::LTspiceSimulation) = circuitpath(circuit(x))
ltspiceexecutablepath(x::LTspiceSimulation) = x.executablepath
logpath(x::LTspiceSimulation) = logpath(log(x))
measurementnames(x::LTspiceSimulation) = measurementnames(circuit(x))
stepnames(x::LTspiceSimulation) = stepnames(log(x))
function steps(x::LTspiceSimulation)
  runifneedsupdate!(x)
  steps(log(x))
end
logneedsupdate(x::LTspiceSimulation) = x.logneedsupdate
setlogneedsupdate!(x::LTspiceSimulation) = x.logneedsupdate = true
clearlogneedsupdate!(x::LTspiceSimulation) = x.logneedsupdate = false
hasparameters(x::LTspiceSimulation) = hasparameters(circuit(x))
hasmeasurements(x::LTspiceSimulation) = hasmeasurements(circuit(x))
hassteps(x::LTspiceSimulation) = hassteps(circuit(x))

include("PerLineIterator.jl")  # for delimited output

### BEGIN Overloading Base ###

function Base.show(io::IO, x::LTspiceSimulation)
  println(io,"LTspiceSimulation:")
  println(io,"circuit path = ",circuitpath(x))
  if hasparameters(x)
    println(io,"")
    println(io,"Parameters")
    for (key,value) in circuit(x)
      println(io,"$(rpad(key,25,' ')) = $value")
    end
  end
  if hasmeasurements(x)
    println(io,"")
    println(io,"Measurements")
    for (i,key) in enumerate(measurementnames(x))
      if stepnames(x) == []
        if logneedsupdate(x)
          value = convert(Float64,NaN)
        elseif haskey(log(x),key)
          value = log(x)[key] #getmeasurements(x.log)[i,1,1,1]
        else
          value = "measurement failed"
        end
        println(io,rpad(key,25,' ')" = ",value)
      else 
        println(io,rpad(key,25,' ')," stepped simulation")
      end
    end
  end
  if hassteps(x)
    println(io,"")
    println(io,"Sweeps")
    if x.logneedsupdate
      for stepname in stepnames(x)
        println(io,rpad(stepname,25,' '))
      end
    else 
      for (i,stepname) in enumerate(stepnames(x))
        println(io,rpad(stepname,25,' ')," ",length(steps(x)[i])," steps")
      end
    end
  end
end

# LTspiceSimulation is a Dict 
#   of its parameters and measurements for non stepped simulations (measurements read only)
#   of its parameters for stepped simulations
Base.haskey(x::LTspiceSimulation, key::ASCIIString) = haskey(circuit(x),key) | haskey(log(x),key)

function Base.keys(x::LTspiceSimulation)
  # returns an array all keys (param and meas)
  vcat(collect(keys(circuit(x))),collect(keys(log(x))))
end

  # returns an array of all values (param and meas)
function Base.values(x::LTspiceSimulation)
  runifneedsupdate!(x)
  vcat(collect(values(circuit(x))),collect(values(log(x))))
end

function Base.getindex(x::LTspiceSimulation, key::ASCIIString)
  # returns value for key in either param or meas
  # value = x[key]
  # dosen't handle multiple keys, but neither does standard julia library for Dict
  if findfirst(measurementnames(x),key) > 0
    runifneedsupdate!(x)
    v = log(x)[key]
  elseif haskey(circuit(x),key)
    v = circuit(x)[key]
  else
    throw(KeyError(key))
  end
  return(v)
end

function Base.get(x::LTspiceSimulation, key::ASCIIString, default:: Float64)
  # returns value for key in either param or meas
  # returns default if key not found
  if haskey(x,key)
    return(x[key])
  else
    return(default)
  end
end

function Base.setindex!(x::LTspiceSimulation, value:: Float64, key::ASCIIString)
  # sets the value of param specified by key
  # x[key] = value
  # meas Dict cannot be set.  It is the result of a simulation
  if haskey(circuit(x),key)
    setlogneedsupdate!(x)
    circuit(x)[key] = value
  elseif haskey(log(x),key)
    error("measurements cannot be set.")
  else
    throw(KeyError(key))
  end
end

function Base.setindex!(x::LTspiceSimulation, value:: Float64, index:: Int)
  setlogneedsupdate!(x) 
  circuit(x)[index] = value 
end

# LTspiceSimulationTempDir is an read only array of its measurements
# Intended for use in interactive sessions only.
# For type stablity use getmeasurements()
function Base.getindex(x::LTspiceSimulation,index::Int)
  runifneedsupdate!(x)
  log(x)[index]
end
function Base.getindex(x::LTspiceSimulation, i1::Int, i2::Int, i3::Int, i4::Int)
  runifneedsupdate!(x)
  log(x)[i1,i2,i3,i4] 
end

Base.eltype(x::LTspiceSimulation) = Float64 
Base.length(x::LTspiceSimulation) = length(log(x)) + length(circuit(x))

function Base.call(x::LTspiceSimulation, args...)
  if length(args) != length(circuit(x))
    throw(ArgumentError("number of arguments must match number of parameters"))
  end
  if typeof(log(x)) == Type(SteppedLogFile)
    error("call only for non stepped simulations")
  end
  for (i,arg) in enumerate(args)
    x[i] = arg::Float64 
  end
  return measurements(x)[:,1,1,1]
end

### END overloading Base ###

### BEGIN LTspiceSimulation specific methods ###
#=
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

=#
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
  clearlogneedsupdate!(x)
  return nothing
end

#=
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
  getmeasurements(log(x))
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
=#
"""
```julia
flush(sim)
```
Writes `sim`'s circuit file back to disk if any parameters have changed.  The 
user does not usualy need to call this.  It will be called automatically
 when a measurment is requested and the log file needs to be updated.  It can be used
 to update a circuit file using julia for simulation with the LTspice GUI.  
"""
Base.flush(x::LTspiceSimulation) = flush(circuit(x))

function runifneedsupdate!(x::LTspiceSimulation)
  if logneedsupdate(x)
    run!(x)
  end
  return nothing
end

"""
```julia
run(sim)
```
writes circuit changes and calls LTspice to run `sim`.
"""
function run!(x::LTspiceSimulation)
  flush(x)
  if ltspiceexecutablepath(x) != ""  # so travis dosen't need to load LTspice
    if islinux
      drive_c = "/home/$(ENV["USER"])/.wine/drive_c"
      winecircuitpath = joinpath("C:",relpath(circuitpath(x),drive_c))
      run(`$(ltspiceexecutablepath(x)) -b -Run $winecircuitpath`)
    else
      run(`$(ltspiceexecutablepath(x)) -b -Run $(circuitpath(x))`)
    end
  end
  x.log = parse(x.log)
  clearlogneedsupdate!(x)
  return nothing 
end

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
defaultltspiceexecutable()Base.
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

