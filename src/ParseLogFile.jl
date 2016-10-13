abstract LogLine
abstract Header <: LogLine
type IsCircuitPath <: Header end
abstract Footer <: LogLine
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
type MeasurementValue <: LogLine
  iter
  state
  function MeasurementValue(x::LTspiceSimulation)
    iter = eachindex(x.measurementvalues)
    new(iter,start(iter))
  end
end
type IsDotStep <: LogLine end
type DotStep{Nstep} <: LogLine
  stepvalues :: StepValues{Nstep}
  stepvaluesline :: Array{Float64,Nstep}
end
function DotStep{Nparam,Nmeas,Nmdim,Nstep}(x::LTspiceSimulation{Nparam,Nmeas,Nmdim,Nstep})
  bsv = blankstepvalues(Nstep)
  for i in 1:Nstep
    sizehint!(bsv.stepvalues.values[i],length(x.stepvalues.values[i]))
  end
  return DotStep(bsv,Array(Float64,3)
end

const circuitpathregex = r"^Circuit: \*\s*([\w\:\\/. ~]+)"i
function parseline!(::LTspiceSimulation, ::IsCircuitPath, line::AbstractString)
  ismatch(circuitpathregex, line)
end

const nonsteppedmeasurementregex = r"^([a-z][a-z0-9_@#$.:\\]*):.*=([\S]+)"i
function parseline!(x::NonSteppedSimulation, mv::MeasurementValue, line::AbstractString)
  m = match(nonsteppedmeasurementregex, line)
  m == nothing && return false
  done(mv.iter, mv.state) && throw(ParseError("unexpected measurement"))
  (i,mv.state) = next(mv.iter, mv.state)
  try
    x.measurementvalues.values[i] = parse(Float64,m.captures[2])
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
    x.measurementvalues[i] = parse(Float64,m.captures[1])
  catch
    x.measurementvalues[i] = Float64(NaN)
  end
  return true
end

const dotstepregex = r"(\.step)(?:\s+(.*?)=(.*?))(?:\s+(.*?)=(.*?)){0,1}(?:\s+(.*?)=(.*?)){0,1}\s*$"i
function parseline!(::LTspiceSimulation, ::IsDotStep, line::AbstractString)
  ismatch(dotstepregex, line)
end
const dotstepregex3 = r"(\.step)(?:\s+(.*?)=(.*?))(?:\s+(.*?)=(.*?))(?:\s+(.*?)=(.*?))\s*$"i
function parseline!{Nparam,Nmeas,Nmdim,Nstep}(
                  x::LTspiceSimulation{Nparam,Nmeas,Nmdim,3},
                  ds::DotStep{3},
                  line::AbstractString)
  m = match(dotstepregex3, line)
  m == nothing && return false
  # stepnames = [m.captures[i] for i in (2,4,6) if m.captures[i]!=nothing]
  # stepvaluesline = [parse(Float64,m.captures[i]) for i in (3,5,7) if m.caputres[i]!=nothing]
  for i in 1:Nstep
    ds.stepvaluesline[i] = parse(Float64,m.captures[i])
  end


  # to do
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
    line = readline(io)
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
  open(x.logpath,true,false,false,false,false) do io
    measurement = MeasurementValue(x)
    exitcode = processlines!(io, x, [], [measurement,IsDotStep()])
    if exitcode == 2 # this was supposed to be a NonSteppedFile
      throw(ParseError(".log file is not expected type.  expected non-stepped, got stepped"))
    end
    processlines!(io, x, [measurement], [Date()])
    processlines!(io, x, [Duration()])
  end
  return nothing
end

function parselog!{Nparam,Nmeas,Nmdim,Nstep}(x::LTspiceSimulation{Nparam,Nmeas,Nmdim,Nstep})
  open(x.logpath,true,false,false,false,false) do io
    updaterestepvalues(io,x)
    updatemeasurementvaluessize(x)
    measurement = Measurement(eachindex(x.measurements))


    exitcode = processlines!(io, slf, [header],[measurement,step])
    if exitcode == 1 # a non-stepped log file
      throw(ParseError(".log file is not expected type.  expected stepped, got non-stepped"))
    end
  end
  return nothing
end
