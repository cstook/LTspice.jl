
include("MultiLevelIterator.jl")


# BEGIN LogLine
"""
Subtypes of `LogLine` are used to dispatch `parseline!` to process a 
specific type of log file line.  Some of the subtypes also hold temporary 
data for the lines they process.

**Subtypes**

- `Header`                -- abstract type for all header lines
- `Measurement`           -- measurement of a non stepped simulation
- `StepParameters`        -- stepped parameters of a stepped simulation
- `IsStepParameters`      -- same as `StepParameters`, but doesn't save data
- `StepMeasurementName`   -- measurement name of a stepped simulation
- `StepMeasurementValue`  -- measurement value of a stepped simulation
- `Footer`                -- abstract type for all footer lines
"""
abstract LogLine

"""
`Footer` is an abstract type for all footer lines.

**Subtypes**

- `FooterDate`      -- time and date simulation was run
- `FooterDuration`  -- time simulation took to run
"""
abstract Footer <: LogLine

"""
`Header` is an abstract type for all header lines.  Currently, there is only 
one subtype `HeaderCircuitPath`.
"""
abstract Header <: LogLine 
type HeaderCircuitPath <: Header end

"""
`Measurement` holds the measurement names and values in 1d arrays for 
non stepped simulations.
"""
type Measurement <: LogLine
  measurementnames :: Array{ASCIIString,1}
  measurements :: Array{Float64,1}
  Measurement() = new([],[])
end
type IsStepParameters <: LogLine end

"""
`StepParameters` holds the step values in a 1d array.
"""
type StepParameters <: LogLine 
  stepvalues :: Int
  StepParameters() = new(0)
end

"""
`StepMeasurementName` holds the step measurement names in a 1d array.
"""
type StepMeasurementName <: LogLine
  name :: ASCIIString
  StepMeasurementName() = new("")
end

"""
`StepMeasurementValue` holds the step measurement values in a 1d array.
"""
type StepMeasurementValue <: LogLine
  values :: Array{Float64,1}
  StepMeasurementValue() = new([])
end 
type FooterDate <: Footer end 
type FooterDuration <: Footer end
# END LogLine

"""
Subtypes of `LogParsed` store data from the log file.

**Subtypes**

- `NonSteppedLog` -- stores data from non stepped log file
- `SteppedLog`    -- stores data from a stepped log file
"""
abstract LogParsed

"""
Stores data from a non stepped log file.

**Fields**

- `logpath`           -- path to log file
- `circuitpath`       -- path to circuit file in the log file
- `timestamp`         -- time and date of the simulation was run
- `duration`          -- simulation time in seconds
- `measurementnames`  -- 1d array of measurement names
- `measurements`      -- 4d array of measurement values
"""
type NonSteppedLog <: LogParsed
  logpath           :: ASCIIString  # path to log file
  circuitpath       :: ASCIIString  # path to circuit file in the log file
  timestamp         :: DateTime
  duration          :: Float64  # simulation time in seconds
  measurementnames  :: Array{ASCIIString,1}   
  measurements      :: Array{Float64,4}
  NonSteppedLog(logpath::ASCIIString) = new(logpath,"",DateTime(2015),0.0,[],Array(Float64,0,0,0,0))
end
NonSteppedLog() = NonSteppedLog("")
logpath!(nslf::NonSteppedLog,path::AbstractString) = nslf.logpath = path
logpath(nslf::NonSteppedLog) = nslf.logpath
circuitpath!(nslf::NonSteppedLog,path::AbstractString) = nslf.circuitpath = path
circuitpath(nslf::NonSteppedLog) = nslf.circuitpath
timestamp!(nslf::NonSteppedLog,ts::DateTime) = nslf.timestamp = ts 
timestamp(nslf::NonSteppedLog) = nslf.timestamp
duration!(nslf::NonSteppedLog,duration) = nslf.duration = duration 
duration(nslf::NonSteppedLog) = nslf.duration
measurementnames!(nslf::NonSteppedLog,measurementnames) = nslf.measurementnames = measurementnames
measurementnames(nslf::NonSteppedLog) = nslf.measurementnames
measurementvalues!(nslf::NonSteppedLog,measurements) = nslf.measurements = measurements
measurementvalues(nslf::NonSteppedLog) = nslf.measurements
stepnames(nslf::NonSteppedLog) = []

"""
Stores data from a stepped log file.

**Fields**

- `nonsteppedlogfile`  -- instance of `NonSteppedLog`
- `stepnames`          -- 1d array of step names
- `stepvalues`         -- tuple of 3 1d arrays to hold the step values
"""
type SteppedLog <: LogParsed
  nonsteppedlogfile :: NonSteppedLog
  stepnames         :: Array{ASCIIString,1}
  stepvalues             :: Tuple{Array{Float64,1},Array{Float64,1},Array{Float64,1}}
  SteppedLog(nslf::NonSteppedLog) = new(nslf,[],([],[],[])) 
end
SteppedLog() = SteppedLog(NonSteppedLog())
SteppedLog(logpath::ASCIIString) = SteppedLog(NonSteppedLog(logpath))
stepnames!(slf::SteppedLog, s::Array{ASCIIString,1}) = slf.stepnames = s
stepnames(slf::SteppedLog) = slf.stepnames
stepvalues(slf::SteppedLog) = slf.stepvalues
logpath(slf::SteppedLog) = logpath(slf.nonsteppedlogfile)
logpath!(slf::SteppedLog,path::AbstractString) = logpath!(slf.nonsteppedlogfile,path)
circuitpath(slf::SteppedLog) = circuitpath(slf.nonsteppedlogfile)
circuitpath!(slf::SteppedLog,path::AbstractString) = circuitpath!(slf.nonsteppedlogfile,path)
timestamp(slf::SteppedLog) = timestamp(slf.nonsteppedlogfile)
timestamp!(slf::SteppedLog,ts::DateTime) = timestamp!(slf.nonsteppedlogfile,ts)
duration(slf::SteppedLog) = duration(slf.nonsteppedlogfile)
duration!(slf::SteppedLog,duration) = duration!(slf.nonsteppedlogfile,duration)
measurementnames(slf::SteppedLog) = measurementnames(slf.nonsteppedlogfile)
measurementnames!(slf::SteppedLog,measurementnames) = measurementnames!(slf.nonsteppedlogfile,measurementnames)
measurementvalues(slf::SteppedLog) = measurementvalues(slf.nonsteppedlogfile)
measurementvalues!(slf::SteppedLog,measurements) = measurementvalues!(slf.nonsteppedlogfile,measurements)

function Base.show(io::IO, x::NonSteppedLog)
  println(io,logpath(x))  
  println(io,circuitpath(x))
  println(io,timestamp(x))
  println(io,duration(x)," seconds")
  if length(measurementnames(x))>0
    println(io,"")
    println(io,"Measurements")
    for name in measurementnames(x)
      println(io,"  ",name)
    end
  end
end

function Base.show(io::IO, x::SteppedLog)
   show(io,x.nonsteppedlogfile) 
   if length(stepnames(x))>0
    println(io,"")
    println(io,"Step")
    for name in stepnames(x)
      println(io,"  ",name)
    end
  end
end

# NonSteppedLog is a read only Dict of its measurements
Base.haskey(x::NonSteppedLog,key::ASCIIString) = findfirst(measurementnames(x),key) > 0
Base.haskey(x::SteppedLog,   key::ASCIIString) = false
Base.keys(x::NonSteppedLog)   = measurementnames(x)
Base.keys(x::SteppedLog)      = []
Base.values(x::NonSteppedLog) = measurementvalues(x)[:,1,1,1]
Base.values(x::SteppedLog)    = []
Base.length(x::NonSteppedLog) = length(measurementnames(x))
Base.eltype(x::NonSteppedLog) = Float64
function Base.getindex(x::NonSteppedLog, key::ASCIIString)
  i = findfirst(measurementnames(x),key)
  if i == 0
    throw(KeyError(key))
  end
  return measurementvalues(x)[i,1,1,1]
end

# LogParsed can access its measurements as a read only array
Base.getindex(x::NonSteppedLog, index::Integer) = measurementvalues(x)[index,1,1,1]
Base.getindex(x::LogParsed, i1::Integer, i2::Integer, i3::Integer, i4::Integer) = 
  measurementvalues(x)[i1,i2,i3,i4]

Base.length(x::SteppedLog) = length(measurementvalues(x))

# NonSteppedLog iterates over its Dict
Base.start(x::NonSteppedLog) = 1
function Base.next(x::NonSteppedLog,state)
  return (measurementnames(x)[state]=>measurementvalues(x)[state,1,1,1],state+1)
end
Base.done(x::NonSteppedLog, state) = state > length(measurementnames(x))

function parseline!(lf::LogParsed, ::HeaderCircuitPath, line::ASCIIString)
  m = match(r"^Circuit: \*\s*([\w\:\\/. ~]+)"i,line)
  if m!=nothing
    circuitpath!(lf,m.captures[1])
    return true
  else
    return false
  end
end

function parseline!(lf::LogParsed, measurement::Measurement, line::ASCIIString)
  #m = match(r"^([a-z][a-z0-9_@#$.:\\]*):.*=([0-9.eE+-]+)"i,line)
  m = match(r"^([a-z][a-z0-9_@#$.:\\]*):.*=([\S]+)"i,line)
  value = Float64(NaN)
  if m!=nothing
    name = m.captures[1]
    try
      value = parse(Float64,m.captures[2])
    catch 
      value = Float64(NaN)
    end
    push!(measurement.measurementnames,name)
    push!(measurement.measurements,value)
    return true
  else
    return false
  end
end

const stepregex = r"(\.step)(?:\s+(.*?)=(.*?))(?:\s+(.*?)=(.*?)){0,1}(?:\s+(.*?)=(.*?)){0,1}\s*$"i
function parseline!(::NonSteppedLog, ::IsStepParameters, line::ASCIIString)
  ismatch(stepregex, line)
end

function parseline!(slf::SteppedLog, sp::StepParameters, line::ASCIIString)
  m = match(stepregex, line)
  s_names = stepnames(slf)
  s_values = stepvalues(slf)
  if m!=nothing
    sp.stepvalues += 1
    if length(s_names)==0 # if we dont have the step names yet
      for i in (2,4,6)
        if m.captures[i] != nothing  # we have a step name
          push!(s_names,m.captures[i]) # save the name
        end
      end 
    end
    for (i,k) in ((3,1),(5,2),(7,3))
      if m.captures[i] != nothing # we have a value
        value = parse(Float64,m.captures[i])
        if ~issubset(value,s_values[k]) # if we haven't seen this value yet
          push!(s_values[k],value) # add it to the list
        end 
      end
    end
    return true
  else
    return false
  end
end

function parseline!(slf::SteppedLog, smn::StepMeasurementName, line::ASCIIString)
  m_names = measurementnames(slf)
  m = match(r"^Measurement: ([a-z0-9_@#$.:\\]*)",line)
  if m!=nothing
    name = m.captures[1]
    smn.name = name
    push!(m_names,name)
    return true
  else
    return false
  end
end

function parseline!(::SteppedLog, smv::StepMeasurementValue, line::ASCIIString)
  #m = match(r"^\s*[0-9]+\s+([0-9.eE+-]+)"i,line)
  m = match(r"^\s*[0-9]+\s+(\S+)"i,line)
  value = Float64(NaN)
  if m!=nothing
    try
      value = parse(Float64,m.captures[1])
    catch
      value = Float64(NaN)
    end
    push!(smv.values,value)
    return true
  else
    return false
  end
end

function parseline!(lf::LogParsed, ::FooterDate, line::ASCIIString)
  m = match(r"Date:\s*(.*?)\s*$",line)
  if m!=nothing
    timestamp = DateTime(m.captures[1],"e u d HH:MM:SS yyyy")
    timestamp!(lf,timestamp)
    return true
  else
    return false
  end
end

function parseline!(lf::LogParsed, ::FooterDuration, line::ASCIIString)
  m = match(r"Total[ ]elapsed[ ]time:\s*([\w.]+)\s+seconds.\s*$",line)
  if m!=nothing
    duration = parse(Float64,m.captures[1])
    duration!(lf,duration)
    return true
  else
    return false
  end
end

"""
    parseline!(log::LogParsed, logline::LogLine, line::ASCIIString)

Test to see if `line` is type `logline`, if so, process line and return `true`,
otherwise return `false`.  Data will be returned in either `log` or `logline`
 depending on the type of `logline`.
"""
parseline!

"""
    processlines!(io::IO, log::LogParsed, findlines, untillines=[])

Process lines of `io` for `findlines` until a `untillines` is found.
`findlines` and `untillines` are both arrays of `LogLine`.  Data is returned 
in `log`, `findlines`, and `untillines` depending on what lines were found.
`processlines!` returns the index into `untillines` of the `LogLine` which 
caused it to stop.
"""
function processlines!(io::IO, lf::LogParsed, findlines, untillines=[])
  while ~eof(io)
    line = readline(io)
    for f in findlines
      if parseline!(lf,f,line)
        break
      end
    end
    for i in eachindex(untillines)
      if parseline!(lf,untillines[i],line)
        return i # let caller know why we returned
      end
    end
  end
  return 0
end

function Base.parse(::Type{SteppedLog}, logpath::ASCIIString)
  header = HeaderCircuitPath()
  measurement = Measurement()
  stepparameters = StepParameters()
  footerdate = FooterDate()
  footerduration = FooterDuration()
  lf = NonSteppedLog()
  logpath!(lf,logpath)
  slf = SteppedLog(lf)
  io = open(logpath,true,false,false,false,false)
  exitcode = processlines!(io, slf, [header],[measurement,stepparameters])
  if exitcode == 1 # a non-stepped log file
    close(io)
    throw(ParseError(".log file is not expected type.  expected SteppedLog, got NonSteppedLog"))
  else # a stepped log file
    stepmeasurementname = StepMeasurementName()
    stepmeasurementvalue = StepMeasurementValue()
    footerdate = FooterDate()
    # parse the step parameters
    exitcode = processlines!(io,slf,[stepparameters],[stepmeasurementname, footerdate])
    while exitcode<2 # keep processing until we get a footerdate
      exitcode = processlines!(io,slf,[stepmeasurementvalue],[stepmeasurementname, footerdate])
    end
    # reshape measurement values
    lengthnames = length(measurementnames(slf))
    if lengthnames >0
      zeroisone(x) = x==0?1:x
      lengthsweep1 = zeroisone(length(stepvalues(slf)[1]))
      lengthsweep2 = zeroisone(length(stepvalues(slf)[2]))
      lengthsweep3 = zeroisone(length(stepvalues(slf)[3]))
      measurementdimentions = (lengthnames, lengthsweep1, lengthsweep2, lengthsweep3)
      measurementvalues!(slf, Array(Float64, measurementdimentions...))
      m_values = measurementvalues(slf)
      i = 1
      for nameindex in 1:lengthnames
        for sweep3index in 1:lengthsweep3
          for sweep2index in 1:lengthsweep2
            for sweep1index in 1:lengthsweep1
              m_values[nameindex,sweep1index,sweep2index,sweep3index] = stepmeasurementvalue.values[i]
              i+=1
            end
          end
        end
      end
    else # no measurements is a special case
      measurementvalues!(slf, Array(Float64,0,0,0,0))
    end
    processlines!(io,slf,[footerduration])
    close(io)
    return slf
  end
end

function Base.parse(::Type{NonSteppedLog}, logpath::ASCIIString)
  header = HeaderCircuitPath()
  measurement = Measurement()
  isstepparameters = IsStepParameters()
  footerdate = FooterDate()
  footerduration = FooterDuration()
  lf = NonSteppedLog()
  logpath!(lf,logpath)
  io = open(logpath,true,false,false,false,false)
  exitcode = processlines!(io, lf, [header],[measurement,isstepparameters])
  if exitcode == 2 # this was supposed to be a NonSteppedFile
    close(io)
    throw(ParseError(".log file is not expected type.  expected NonSteppedLog, got SteppedLog"))
  end
  exitcode = processlines!(io, lf, [measurement],[footerdate])
  measurementnames!(lf, measurement.measurementnames)
  measurementvalues!(lf, reshape(measurement.measurements,length(measurement.measurements),1,1,1))
  processlines!(io,lf,[footerduration])
  close(io)
  return lf
end

Base.parse{T<:LogParsed}(x::T) = parse(T, logpath(x))  

"""
    parse{T<:LogParsed}(x::T)
    parse(::Type{LogParsed}, logpath::ASCIIString)

Parse a LTspice log file and return the appropriate `LogParsed` object.
"""
Base.parse(::LogParsed), Base.parse(::Type{LogParsed},::ASCIIString)