abstract LogLine
abstract Header <: LogLine
type IsCircuitPath <: Header end
abstract Footer <: LogLine
type FooterDate <: Footer end
type FooterDuration <: Footer end
type MeasurementName <: LogLine
  iter
  state
  function MeasurementName(x::LTspiceSimulation)
    iter = eachindex(x.measurmentnames)
    new(iter,start(iter))
  end
end
type MeasurementValue <: LogLine
  iter
  state
  function MeasurementValue(x::LTspiceSimulation)
    iter = eachindex(x.measurmentvalues)
    new(iter,start(iter))
  end
end
type IsDotStep <: LogLine end
type DotStep <: LogLine
  index :: Array{Int,1}
end
DotStep{Nparam,Nmeas,Nmdim,Nstep}(x::LTspiceSimulation{Nparam,Nmeas,Nmdim,Nstep})=
  DotStep{Nstep}(ones(Int,Nstep))

const circuitpathregex = r"^Circuit: \*\s*([\w\:\\/. ~]+)"i
function parseline!(::LTspiceSimulation, ::IsCircuitPath, line::AbstractString)
  ismatch(circuitpathregex, line)
end

const nonsteppedmeasurment = r"^([a-z][a-z0-9_@#$.:\\]*):.*=([\S]+)"i
function parseline!(x::NonSteppedSimulation, mv::MeasurementValue, line::AbstractString)
  done(mv.iter, mv.state) && throw(ParseError("unexpected measurment"))
  m = match(nonsteppedmeasurment, line)
  m == nothing && return false
  (i,mv.state) = next(mv.iter, mv.state)
  try
    x.measurementvalues[i] = parse(Float64,m.captures[2])
  catch
    x.measurementvalues[i] = Float64(NaN)
  end
  return true
end

const steppedmeasurment = r"^\s*[0-9]+\s+(\S+)"i
function parseline!(x::LTspiceSimulation, mv::MeasurementValue, line::AbstractString)
  done(mv.iter, mv.state) && throw(ParseError("unexpected measurment"))
  m = match(steppedmeasurment, line)
  m == nothing && return false
  (i,mv.state) = next(mv.iter, mv.state)
  try
    x.measurementvalues[i] = parse(Float64,m.captures[1])
  catch
    x.measurementvalues[i] = Float64(NaN)
  end
  return true
end

const dotstep = r"(\.step)(?:\s+(.*?)=(.*?))(?:\s+(.*?)=(.*?)){0,1}(?:\s+(.*?)=(.*?)){0,1}\s*$"i
function parseline!(::LTspiceSimulation, ::IsDotStep, line::AbstractString)
  ismatch(dotstep, line)
end
function parseline!(x::LTspiceSimulation, ds::DotStep, line::AbstractString)
end

function parselog!{Nparam,Nmeas}(x::NonSteppedSimulation{Nparam,Nmeas})
  open(x.logpath,true,false,false,false,false) do io
    measurment = Measurment(x)
    exitcode = processlines!(io, x, [Header()], [measurement,IsStepParameters()])
    if exitcode == 2 # this was supposed to be a NonSteppedFile
      throw(ParseError(".log file is not expected type.  expected non-stepped, got stepped"))
    end
    processlines!(io, x, [measurement], [FooterDate()])
    processlines!(io, x, [FooterDuration()])
  end
  return nothing
end

function parselog!{Nparam,Nmeas,Nmdim,Nstep}(x::LTspiceSimulation{Nparam,Nmeas,Nmdim,Nstep})
  open(x.logpath,true,false,false,false,false) do io
    updaterestepvalues(io,x)
    updatemeasurmentvaluessize(x)
    measurment = Measurement(eachindex(x.measurments))


    exitcode = processlines!(io, slf, [header],[measurement,step])
    if exitcode == 1 # a non-stepped log file
      throw(ParseError(".log file is not expected type.  expected stepped, got non-stepped"))
    end
  end
  return nothing
end
