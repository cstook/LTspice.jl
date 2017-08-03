export parselog!

abstract type LogLine end
abstract type Header <: LogLine end
type IsCircuitPath <: Header end
abstract type Footer <: LogLine end
type Date <: Footer end
type Duration <: Footer end
type MeasurementName <: LogLine
  iter
  state
  function MeasurementName(x::LTspiceSimulation)
    iter = eachindex(x.measurementnames)
    new(iter,start(iter))
  end
end
mutable struct MeasurementValue <: LogLine
  iter
  state
  function MeasurementValue(x::LTspiceSimulation)
    iter = eachindex(x.measurementvalues)
    new(iter,start(iter))
  end
end
mutable struct IsDotStep <: LogLine end
mutable struct DotStep{Nstep} <: LogLine
  stepvalues :: StepValues{Nstep}
  lastline :: Array{Float64,1}
  newline :: Array{Float64,1}
  isdone :: Array{Bool,1}
end
DotStep{Nparam,Nmeas,Nmdim,Nstep}(x::LTspiceSimulation{Nparam,Nmeas,Nmdim,Nstep}) =
  DotStep{Nstep}(blankstepvalues(Nstep),
                 [NaN,NaN,NaN,NaN],
                 [NaN,NaN,NaN,NaN],
                 [false,false,false])

const circuitpathregex = r"^Circuit: \*\s*([\w\:\\/. ~]+)"i
function parseline!(::LTspiceSimulation, ::IsCircuitPath, line::AbstractString)
  ismatch(circuitpathregex, line)
end

const nonsteppedmeasurementregex = r"^.*:.*=([\S]+)"i
function parseline!(x::NonSteppedSimulation, mv::MeasurementValue, line::AbstractString)
  m = match(nonsteppedmeasurementregex, line)
  m == nothing && return false
  done(mv.iter, mv.state) && throw(ParseError("unexpected measurement"))
  (i,mv.state) = next(mv.iter, mv.state)
  try
    x.measurementvalues.values[i] = parse(Float64,m.captures[1])
  catch
    x.measurementvalues.values[i] = Float64(NaN)
  end
  return true
end

const steppedmeasurementregex = r"^\s*[0-9]+\s+(\S+)"i
function parseline!(x::LTspiceSimulation, mv::MeasurementValue, line::AbstractString)
  m = match(steppedmeasurementregex, line)
  m == nothing && return false
  done(mv.iter, mv.state) && throw(ParseError("unexpected measurement"))
  (i,mv.state) = next(mv.iter, mv.state)
  try
    x.measurementvalues.values[i] = parse(Float64,m.captures[1])
  catch
    x.measurementvalues.values[i] = Float64(NaN)
  end
  return true
end

const measurementnameregex = r"^Measurement: ([a-z0-9_@#$.:\\]*)"
function parseline!(x::LTspiceSimulation, mn::MeasurementName, line::AbstractString)
  m = match(measurementnameregex, line)
  m == nothing && return false
  done(mn.iter, mn.state) && throw(ParseError("unexpected measurement name"))
  (i,mn.state) = next(mn.iter, mn.state)
  m.captures[1] != lowercase(x.measurementnames[i]) && throw(ParseError("unexpected measurement name"))
  return true
end

const dotstepregex = r"(\.step)(?:\s+(.*?)=(.*?))(?:\s+(.*?)=(.*?)){0,1}(?:\s+(.*?)=(.*?)){0,1}\s*$"i
function parseline!(::LTspiceSimulation, ::IsDotStep, line::AbstractString)
  ismatch(dotstepregex, line)
end
const dotstepregex123 = (
  r"\.step\s+(?:.*?)=(.*?)\s*$"i,
  r"\.step\s+(?:.*?)=(.*?)\s+(?:.*?)=(.*?)\s*$"i,
  r"\.step\s+(?:.*?)=(.*?)\s+(?:.*?)=(.*?)\s+(?:.*?)=(.*?)\s*$"i
  )
@generated function parseline!{Nparam,Nmeas,Nmdim,Nstep}(
                  x::LTspiceSimulation{Nparam,Nmeas,Nmdim,Nstep},
                  ds::DotStep{Nstep},
                  line::AbstractString)
  return quote
    m = match($(dotstepregex123[Nstep]), line)
    m == nothing && return false
    (ds.newline,ds.lastline) = (ds.lastline,ds.newline)
    for i in 1:$Nstep
      if ~ds.isdone[i]
        ds.newline[i] = parse(Float64,m.captures[i])
      end
    end
    for i in 1:$Nstep
      if ds.newline[i+1] != ds.lastline[i+1] && ~isnan(ds.lastline[i]) && ~isnan(ds.newline[i+1])
        ds.isdone[i] = true
      end
      if ~ds.isdone[i] && ds.newline[i] != ds.lastline[i]
        push!(ds.stepvalues.values[i],ds.newline[i])
      end
    end
    return true
  end
end

const dateregex = r"Date:\s*(.*?)\s*$"
function parseline!(x::LTspiceSimulation, ::Date, line::AbstractString)
  m = match(dateregex,line)
  if m!=nothing
    x.status.timestamp = DateTime(m.captures[1],"e u d HH:MM:SS yyyy")
    return true
  else
    return false
  end
end

const durationregex = r"Total[ ]elapsed[ ]time:\s*([\w.]+)\s+seconds.\s*$"
function parseline!(x::LTspiceSimulation, ::Duration, line::AbstractString)
  m = match(durationregex, line)
  if m!=nothing
    x.status.duration = parse(Float64,m.captures[1])
    return true
  else
    return false
  end
end

function processlines!(io::IO, x::LTspiceSimulation, findlines=[], untillines=[])
  while ~eof(io)
    line = readline(io, chomp=false)
    for f in findlines
      if parseline!(x,f,line)
        break
      end
    end
    for i in eachindex(untillines)
      if parseline!(x,untillines[i],line)
        return i # let caller know why we returned
      end
    end
  end
  return 0
end

function parselog!{Nparam,Nmeas}(x::NonSteppedSimulation{Nparam,Nmeas})
  open(x.logpath,x.logfileencoding) do io
    measurement = MeasurementValue(x)
    exitcode = processlines!(io, x, [], [measurement,IsDotStep()])
    if exitcode == 2 # this was supposed to be a NonSteppedFile
      throw(ParseError(".log file is not expected mutable struct.  expected non-stepped, got stepped"))
    end
    processlines!(io, x, [measurement], [Date()])
    done(measurement.iter, measurement.state) || throw(ParseError("missing measurement(s)"))
    processlines!(io, x, [Duration()])
  end
  return nothing
end

function parselog!{Nparam,Nmeas,Nmdim,Nstep}(x::LTspiceSimulation{Nparam,Nmeas,Nmdim,Nstep})
  open(x.logpath,x.logfileencoding) do io
    dotstep = DotStep(x)
    measurementname = MeasurementName(x)
    processlines!(io, x, [dotstep],[measurementname])
    x.stepvalues.values = dotstep.stepvalues.values
    measurementarraysize = (ntuple(i->length(dotstep.stepvalues.values[i]),Nstep)...,Nmeas)
    if measurementarraysize != size(x.measurementvalues)
      x.measurementvalues.values = Array{Float64}(measurementarraysize)
    end
    measurementvalue = MeasurementValue(x)
    processlines!(io, x, [measurementvalue,measurementname], [Date()])
    done(measurementvalue.iter,measurementvalue.state) || throw(ParseError("missing measurements"))
    processlines!(io, x, [Duration()])
  end
  return nothing
end

"""
    parselog!(sim)

Loads log file of sim without running simulation. The user does not normally need to call parselog!.
"""
parselog!
