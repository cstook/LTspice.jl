export LTspiceSimulation
export circuitpath, logpath, executablepath
export parameternames, parametervalues
export measurementnames, measurementvalues
export stepnames, stepvalues
export run!

mutable struct Status
  ismeasurementsdirty :: Bool # true = need to run simulation
  timestamp :: DateTime; # timestamp from last simulation run
  duration :: Float64; # simulation time in seconds
  Status() = new(true,DateTime(1900),NaN)
end
mutable struct StepValues{Nstep}
  values ::NTuple{Nstep,Array{Float64,1}}
end
blankstepvalues(Nstep::Int) = StepValues{Nstep}(ntuple(d->[],Nstep))

"""
Access parameters and measurements of an LTspice simulation.  Runs simulation
as needed.

Access as a dictionary:
```julia
measurement_value = sim["measurement_name"]
parameter_value = sim["parameter_name"]
sim["parameter_name"] = new_parameter_value
```

Access as a function:
```julia
(m1,m2,m3) = sim(p1,p2,p3)  # simulation with three measurements and three parameters
```

Access as arrays or tuples:
```julia
pnames = parameternames(sim)
mnames = measurementnames(sim)
snames = stepnames(sim)
pvalues = parametervalues(sim)
mvalues = measurementvalues(sim)
svalues = stepvalues(sim)
```
"""
struct LTspiceSimulation{Nparam,Nmeas,Nmdim,Nstep}
  circuitpath :: AbstractString
  logpath :: AbstractString
  executablepath :: AbstractString
  circuitfilearray :: Array{AbstractString,1} # text of circuit file
  parameternames :: NTuple{Nparam,AbstractString}
  parametervalues :: ParameterValuesArray{Float64,1} # values in units A,V,W
  parametermultiplier :: NTuple{Nparam,Float64} # units
  parameterindex :: NTuple{Nparam,Int} # index into circuitfilearray
  parameterdict  :: Dict{AbstractString,Int} # index into name, value, multiplier, index arrays
  measurementnames :: NTuple{Nmeas,AbstractString}
  measurementdict :: Dict{AbstractString,Int} # index into measurmentnames
  measurementvalues :: MeasurementValuesArray{Float64,Nmdim}
  stepnames :: NTuple{Nstep,AbstractString}
  stepvalues :: StepValues{Nstep}
  status :: Status
  circuitfileencoding
  logfileencoding
end
NonSteppedSimulation{Nparam,Nmeas} = LTspiceSimulation{Nparam,Nmeas,1,0}


"""
    parametervalues(sim)

Returns an array of the parameters of `sim` in the order they appear in the
circuit file
"""
parametervalues

"""
    parameternames(sim)

Returns an tuple of the parameters names of `sim` in the order they appear in the
circuit file.
"""
parameternames

"""

    circuitpath(sim)

Returns path to the circuit file.

This is the path to the working circuit file.  If `tempdir=ture` was used
or if running under wine, this will not be the path given to the constructor.
"""
circuitpath

"""
    logpath(sim)

Returns path to the log file.
"""
logpath

"""
    executablepath(sim)

Returns path to the LTspice executable
"""
executablepath

"""
    measurementnames(sim)

Returns an tuple of the measurement names of `sim` in the order they appear in the
circuit file.
"""
measurementnames

"""
    stepnames(sim)

Returns an tuple of step names of `sim`.
"""
stepnames

"""
    measurementvalues(sim)

Retruns measurements of `sim` as an a array of Float64
values.

```julia
value = measurementvalues(sim)[inner_step,
                               middle_step,
                               outer_step,
                               measurement_name] # 3 nested steps
```
"""
measurementvalues

"""
    stepvalues(sim)

Returns the steps of `sim` as a tuple of three arrays of
the step values.
"""
stepvalues

circuitpath(x::LTspiceSimulation) = x.circuitpath
logpath(x::LTspiceSimulation) = x.logpath
executablepath(x::LTspiceSimulation) = x.executablepath
parameternames(x::LTspiceSimulation) = x.parameternames
parametervalues(x::LTspiceSimulation) = x.parametervalues
measurementnames(x::LTspiceSimulation) = x.measurementnames
function measurementvalues(x::LTspiceSimulation)
  run!(x)
  x.measurementvalues
end
stepnames(x::LTspiceSimulation) = x.stepnames
function stepvalues(x::LTspiceSimulation)
  run!(x) # step values can be a function of parameters
  x.stepvalues.values
end

LTspiceSimulation(circuitpath::AbstractString;
                  executablepath::AbstractString = defaultltspiceexecutable(),
                  tempdir::Bool = false,
                  librarysearchpaths = []) =
  LTspiceSimulation(circuitpath, executablepath, tempdir, librarysearchpaths)
function LTspiceSimulation(circuitpath::AbstractString,
                           executablepath::AbstractString,
                           istempdir::Bool,
                           librarysearhpaths)
  originalcircuitpath = circuitpath
  if istempdir
    circuitpath = preparetempdir(circuitpath, executablepath)
  end
  @static if Sys.islinux()
    circuitpath = linkintempdirectoryunderwine(circuitpath)
  end
  circuitparsed = parsecircuitfile(originalcircuitpath,
                                   circuitpath,
                                   executablepath,
                                   librarysearhpaths)
  Nparam = length(circuitparsed.parameternames)
  Nmeas = length(circuitparsed.measurementnames)
  Nstep = length(circuitparsed.stepnames)
  Nmdim = Nstep + 1
  parameterdict = Dict{AbstractString,Int}()
  for i in eachindex(circuitparsed.parameternames)
    parameterdict[circuitparsed.parameternames[i]] = i
  end
  measurementdict = Dict{AbstractString,Int}()
  for i in eachindex(circuitparsed.measurementnames)
    measurementdict[circuitparsed.measurementnames[i]] = i
  end
  return LTspiceSimulation{Nparam,Nmeas,Nmdim,Nstep}(
    circuitpath,
    logpath(circuitpath),
    executablepath,
    circuitparsed.circuitfilearray,
    (circuitparsed.parameternames...,),
    circuitparsed.parametervalues,
    (circuitparsed.parametermultiplier...,),
    (circuitparsed.parameterindex...,),
    parameterdict,
    (circuitparsed.measurementnames...,),
    measurementdict,
    MeasurementValuesArray{Float64,Nmdim}(fill(NaN,(ntuple(d->1,Nstep)...,Nmeas))), # measurementvalues
    (circuitparsed.stepnames...,),
    blankstepvalues(Nstep),
    Status(),
    circuitparsed.circuitfileencoding,
    PossibleEncodings([enc"UTF-16LE",enc"UTF-8",enc"windows-1252"],iscorrectencoding_logfile) # logfileencoding(executablepath) # LTspice changed?
  )
end

function preparetempdir(circuitpath::AbstractString, executablepath::AbstractString)
  td = mktempdir()
  atexit(()->ispath(td)&&rm(td,recursive=true)) # delete this on exit
  (d,f) = splitdir(circuitpath)
  workingcircuitpath = convert(AbstractString, joinpath(td,f))
  cp(circuitpath,workingcircuitpath)
  return workingcircuitpath
end

function Base.show(io::IO, x::LTspiceSimulation)
  println(io,"LTspiceSimulation:")
  showcircuitpath(io,x)
  showparameters(io,x)
  showmeasurements(io,x)
  showsteps(io,x)
  showtimeduration(io,x)
end

function showcircuitpath(io::IO, x::LTspiceSimulation)
  println(io,"circuit path = ",x.circuitpath)
end
showparameters(::IO, x::LTspiceSimulation{0,Nmeas,Nmdim,Nstep}) where {Nmeas,Nmdim,Nstep} = nothing
function showparameters(io::IO, x::LTspiceSimulation)
  println(io)
  println(io,"Parameters")
  for i in eachindex(x.parameternames)
    println(io,rpad(x.parameternames[i],25,' ')," = ",x.parametervalues[i])
  end
end
showmeasurments(::IO, x::LTspiceSimulation{0,0,1,0}) = nothing
showmeasurments(::IO, x::LTspiceSimulation{Nparam,0,1,0}) where Nparam= nothing
showmeasurments(::IO, x::LTspiceSimulation{Nparam,0,Nmdim,Nstep}) where {Nparam,Nmdim,Nstep} = nothing
function showmeasurements(io::IO, x::LTspiceSimulation{Nparam,Nmeas,1,0}) where {Nparam,Nmeas}
  if Nmeas!=0
    println(io)
    println(io,"Measurements")
    for i in eachindex(x.measurementnames)
      print(io,rpad(x.measurementnames[i],25,' '))
      if x.status.ismeasurementsdirty
        println(io)
      elseif isnan(x.measurementvalues[i])
        println(io," = measurement failed")
      else
        println(io," = ",x.measurementvalues[i])
      end
    end
  end
end
function showmeasurements(io::IO, x::LTspiceSimulation)
  println(io)
  println(io,"Measurements")
  totalsteps = 1
  s = size(x.measurementvalues)
  for i in 1:length(s)-1
    totalsteps *= s[i]
  end
  for i in eachindex(x.measurementnames)
    print(io,rpad(x.measurementnames[i],25,' '))
    if x.status.ismeasurementsdirty
      println(io)
    else
      println(io," ",totalsteps," values")
    end
  end
end
showsteps(::IO, x::LTspiceSimulation{Nparam,Nmeas,1,0}) where {Nparam,Nmeas}= nothing
function showsteps(io::IO, x::LTspiceSimulation)
  if length(x.stepnames)>0
    println(io)
    println(io,"Steps")
    for i in eachindex(x.stepnames)
      print(io,rpad(x.stepnames[i],25,' '))
      if x.status.ismeasurementsdirty
        println(io)
      else
        println(io," ",length(x.stepvalues.values[i])," steps")
      end
    end
  end
end
function showtimeduration(io::IO, x::LTspiceSimulation)
  if ~isnan(x.status.duration) # simulation was run at least once
    println(io)
    println(io,"Last Run")
    println(io,"time = ",x.status.timestamp)
    println(io,"duration = ",x.status.duration)
  end
end

Base.haskey(x::LTspiceSimulation, key::AbstractString) =
  haskey(x.parameterdict,key) || haskey(x.measurementdict,key)
Base.keys(x::LTspiceSimulation) =
  vcat(x.parameternames...,x.measurementnames...)
function Base.values(x::LTspiceSimulation)
  run!(x)
  allkeys = keys(x)
  allvalues = similar(allkeys, Float64)
  for i in eachindex(allkeys)
    allvalues[i] =  x[allkeys[i]]
  end
  return allvalues
end
@generated function Base.getindex(
        x::LTspiceSimulation{Nparam,Nmeas,Nmdim,Nstep},
        key::AbstractString) where {Nparam,Nmeas,Nmdim,Nstep}
  r = (
      :(x.measurementvalues[x.measurementdict[key]]),
      :(x.measurementvalues[:,x.measurementdict[key]]),
      :(x.measurementvalues[:,:,x.measurementdict[key]]),
      :(x.measurementvalues[:,:,:,x.measurementdict[key]])
      )
  return quote
    if haskey(x.parameterdict,key)
      return x.parametervalues[x.parameterdict[key]]
    elseif haskey(x.measurementdict,key)
      run!(x)
      return $(r[Nstep+1])
    else
      throw(KeyError(key))
    end
  end
end
function Base.get(x::LTspiceSimulation, key::AbstractString, default)
  if haskey(x,key)
    return(x[key])
  else
    return(default)
  end
end
function Base.setindex!(x::LTspiceSimulation, value::Float64, key::AbstractString)
  if haskey(x.parameterdict,key)
    x.parametervalues[x.parameterdict[key]] = value
  elseif haskey(x.measurementdict,key)
    error("measurements cannot be set.")
  else
    throw(KeyError(key))
  end
end
Base.eltype(x::LTspiceSimulation) = Float64
Base.length(x::LTspiceSimulation) = length(x.parametervalues) + length(x.measurementvalues)

(x::LTspiceSimulation)(args...) = throw(ArgumentError("number of arguments must match number of parameters"))
function (x::LTspiceSimulation{Nparam,Nmeas,Nmdim,Nstep})(args::Vararg{Any,Nparam}) where {Nparam,Nmeas,Nmdim,Nstep}
  for i in eachindex(args)
    x.parametervalues[i] = args[i]
  end
  measurementvalues(x)
end


"""
```julia
flush(sim)
```
Writes `sim`'s circuit file back to disk if any parameters have changed.  The
user does not usually need to call `flush`.  It will be called automatically
 when a measurement is requested and the log file needs to be updated.  It can be used
 to update a circuit file using julia for simulation with the LTspice GUI.
"""
function Base.flush(x::LTspiceSimulation, force=false)
	if x.parametervalues.ismodified || force
    updatecircuitfilearray!(x)
    writecircuitfilearray(x)
  	x.parametervalues.ismodified = false
    x.status.ismeasurementsdirty = true
  end
  return nothing
end
function updatecircuitfilearray!(x::LTspiceSimulation)
  for i in eachindex(x.parameternames)
    x.circuitfilearray[x.parameterindex[i]] =
      string(x.parametervalues[i]/x.parametermultiplier[i])
  end
end
function writecircuitfilearray(x::LTspiceSimulation)
  io = open(x.circuitpath, x.circuitfileencoding, "w")
  for text in x.circuitfilearray
    print(io,text)
  end
  close(io)
  return nothing
end

"""
```julia
run!(sim)
```
Writes circuit changes, calls LTspice to run `sim`, and reloads the log file.  The user
normally does not need to call this.
"""
function run!(x::LTspiceSimulation, force=false)
  flush(x,force)
  if x.status.ismeasurementsdirty || force
    if x.executablepath != ""  # so travis dosen't need to load LTspice
      @static if Sys.islinux()
        drive_c = "/home/$(ENV["USER"])/.wine/drive_c"
        winecircuitpath = joinpath("C:",relpath(x.circuitpath,drive_c))
        run(`$(x.executablepath) -b -Run $winecircuitpath`)
      else
        run(`$(x.executablepath) -b -Run $(x.circuitpath)`)
      end
    end
    parselog!(x)
    x.status.ismeasurementsdirty = false
  end
end
