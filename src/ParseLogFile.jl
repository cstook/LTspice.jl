
include("MultiLevelIterator.jl")


# BEGIN LogLine
abstract LogLine
abstract Footer <: LogLine
abstract Header <: LogLine
type HeaderCircuitPath <: Header end
type Measurement <: LogLine
  measurementnames :: Array{ASCIIString,1}
  measurements :: Array{Float64,1}
  Measurement() = new([],[])
end 
type StepParameters <: LogLine 
  steps :: Int
  StepParameters() = new(0)
end 
type StepMeasurementName <: LogLine
  name :: ASCIIString
  StepMeasurementName() = new("")
end 
type StepMeasurementValue <: LogLine
  values :: Array{Float64,1}
  StepMeasurementValue() = new([])
end 
type FooterDate <: Footer end 
type FooterDuration <: Footer end
# END LogLine

# BEGIN LogFile
abstract LogFile

type NonSteppedLogFile <: LogFile
  logpath           :: ASCIIString  # path to log file
  circuitpath       :: ASCIIString  # path to circuit file in the log file
  timestamp         :: DateTime
  duration          :: Float64  # simulation time in seconds
  measurementnames  :: Array{ASCIIString,1}   
  measurements      :: Array{Float64,4}
  NonSteppedLogFile(logpath::ASCIIString) = new(logpath,"",DateTime(2015),0.0,[],Array(Float64,0,0,0,0))
end
NonSteppedLogFile() = NonSteppedLogFile("")

function logpath!(nslf::NonSteppedLogFile,path::AbstractString)
  nslf.logpath = path
  return nothing
end
logpath(nslf::NonSteppedLogFile) = nslf.logpath

function circuitpath!(nslf::NonSteppedLogFile,path::AbstractString)
  nslf.circuitpath = path
  return nothing
end
circuitpath(nslf::NonSteppedLogFile) = nslf.circuitpath

function timestamp!(nslf::NonSteppedLogFile,ts::DateTime)
  nslf.timestamp = ts 
  return nothing
end
timestamp(nslf::NonSteppedLogFile) = nslf.timestamp

function duration!(nslf::NonSteppedLogFile,duration)
  nslf.duration = duration 
  return nothing
end
duration(nslf::NonSteppedLogFile) = nslf.duration

function measurementnames!(nslf::NonSteppedLogFile,measurementnames)
  nsfl.measurementnames = measurementnames
  return nothing
end
measurementnames(nslf::NonSteppedLogFile) = nslf.measurementnames

function measurements!(nslf::NonSteppedLogFile,measurements)
  nslf.measurements = measurements
  return nothing
end
measurements(nslf::NonSteppedLogFile) = nslf.measurements

type SteppedLogFile <: LogFile
  nonsteppedlogfile :: NonSteppedLogFile
  stepnames         :: Array{ASCIIString,1}
  steps             :: Tuple{Array{Float64,1},Array{Float64,1},Array{Float64,1}}
  SteppedLogFile(nslf::NonSteppedLogFile) = new(nslf,[],([],[],[])) 
end
SteppedLogFile() = SteppedLogFile(NonSteppedLogFile())
SteppedLogFile(logpath::ASCIIString) = SteppedLogFile(NonSteppedLogFile(logpath))

function stepnames!(slf::SteppedLogFile, stepnames::Array{ASCIIString,1})
  slf.stepnames = stepnames
  return nothing
end
stepnames(slf::SteppedLogFile) = slf.stepnames

steps(slf::SteppedLogFile) = slf.steps
logpath(slf::SteppedLogFile) = logpath(slf.nonsteppedlogfile)
logpath!(slf::SteppedLogFile,path::AbstractString) = logpath!(slf.nonsteppedlogfile,path)
circuitpath(slf::SteppedLogFile) = circuitpath(slf.nonsteppedlogfile)
circuitpath!(slf::SteppedLogFile,path::AbstractString) = circuitpath!(slf.nonsteppedlogfile,path)
timestamp(slf::SteppedLogFile) = timestamp(slf.nonsteppedlogfile)
timestamp!(slf::NonSteppedLogFile,ts::DateTime) = timestamp!(slf.nonsteppedlogfile,ts)
duration(slf::SteppedLogFile) = duration(slf.nonsteppedlogfile)
duration!(slf::SteppedLogFile,duration) = duration!(slf.nonsteppedlogfile,duration)
measurementnames(slf::SteppedLogFile) = measurementnames(slf.nonsteppedlogfile)
measurementnames!(slf::NonSteppedLogFile,measurementnames) = measurementnames!(slf.nonsteppedlogfile,measurementnames)
measurements(slf::SteppedLogFile) = measurements(slf.nonsteppedlogfile)
measurements!(slf::SteppedLogFile,measurements) = measurements!(slf.nansteppedlogfile,measurements)

# END LogFile

### BEGIN overloading Base ###

function Base.show(io::IO, x::NonSteppedLogFile)
  println(io,logpath(x))  
  println(io,circuitpath(x))
  println(io,timestamp(x))
  println(io,"$(duration(x)) seconds")
  if length(measurementnames(x))>0
    println(io,"")
    println(io,"Measurements")
    for name in measurementnames(x)
      println(io,"  $name")
    end
  end
end

function Base.show(io::IO, x::SteppedLogFile)
   show(io,x.nonsteppedlogfile) 
   if length(stepnames(x))>0
    println(io,"")
    println(io,"Step")
    for name in stepnames(x)
      println(io,"  $name")
    end
  end
end

# NonSteppedLogFile is a read only Dict of its measurements
Base.haskey(x::NonSteppedLogFile,key::ASCIIString) = findfirst(measurementnames(x),key) > 0
Base.haskey(x::SteppedLogFile,   key::ASCIIString) = false
Base.keys(x::NonSteppedLogFile)   = measurementnames(x)
Base.keys(x::SteppedLogFile)      = []
Base.values(x::NonSteppedLogFile) = measurements(x)[:,1,1,1]
Base.values(x::SteppedLogFile)    = []
Base.length(x::NonSteppedLogFile) = length(measurementnames(x))
Base.eltype(x::NonSteppedLogFile) = Float64
function Base.getindex(x::NonSteppedLogFile, key::ASCIIString)
  i = findfirst(measurementnames(x),key)
  if i == 0
    throw(KeyError(key))
  end
  return measurements(x)[i,1,1,1]
end

# LogFile can access its measurments as a read only array
Base.getindex(x::NonSteppedLogFile, index::Integer) = measurements(x)[index,1,1,1]
Base.getindex(x::LogFile, i1::Integer, i2::Integer, i3::Integer, i4::Integer) = 
  measurements(x)[i1,i2,i3,i4]

Base.length(x::SteppedLogFile) = length(getmeasurements(x))

# NonSteppedLogFile iterates over its Dict
Base.start(x::NonSteppedLogFile) = 1
function Base.next(x::NonSteppedLogFile,state)
  return (measurementnames(x)[state]=>measurements(x)[state,1,1,1],state+1)
end
Base.done(x::NonSteppedLogFile, state) = state > length(measurementnames(x))

function parseline!(lf::NonSteppedLogFile, ::HeaderCircuitPath, line::ASCIIString)
  m = match(r"^Circuit: \*\s*([\w\:\\/. ~]+)"i,line)
  if m!=nothing
    circuitpath!(lf,m.captures[1])
    return true
  else
    return false
  end
end
function parseline!(lf::SteppedLogFile, x::HeaderCircuitPath, line::ASCIIString)
  parseline!(lf.nonsteppedlogfile,x,line)
end

function parseline!(lf::NonSteppedLogFile, measurement::Measurement, line::ASCIIString)
  m = match(r"^([a-z][a-z0-9_@#$.:\\]*):.*=([0-9.eE+-]+)"i,line)
  if m!=nothing
    name = m.captures[1]
    value = parse(Float64,m.captures[2])
    push!(measurement.measurementnames,name)
    push!(measurement.measurements,value)
    return true
  else
    return false
  end
end
function parseline!(lf::SteppedLogFile, x::Measurement, line::ASCIIString)
  parseline!(lf.nonsteppedlogfile,x,line)
end 

function parseline!(slf::SteppedLogFile, sp::StepParameters, line::ASCIIString)
  m = match(r"(\.step)(?:\s+(.*?)=(.*?))(?:\s+(.*?)=(.*?)){0,1}(?:\s+(.*?)=(.*?)){0,1}\s*$"i,line)
  if m!=nothing
    sp.steps += 1
    if length(slf.stepnames)==0 # if we dont have the step names yet
      for i in (2,4,6)
        if m.captures[i] != nothing  # we have a step name
          push!(slf.stepnames,m.captures[i]) # save the name
        end
      end 
    end
    for (i,k) in ((3,1),(5,2),(7,3))
      if m.captures[i] != nothing # we have a value
        value = parse(Float64,m.captures[i])
        if ~issubset(value,slf.steps[k]) # if we haven't seen this value yet
          push!(slf.steps[k],value) # add it to the list
        end 
      end
    end
    return true
  else
    return false
  end
end

function parseline!(slf::SteppedLogFile, smn::StepMeasurementName, line::ASCIIString)
  m = match(r"^Measurement: ([a-z0-9_@#$.:\\]*)",line)
  if m!=nothing
    name = m.captures[1]
    smn.name = name
    push!(slf.nonsteppedlogfile.measurementnames,name)
    return true
  else
    return false
  end
end

function parseline!(::SteppedLogFile, smv::StepMeasurementValue, line::ASCIIString)
  m = match(r"^\s*[0-9]+\s+([0-9.eE+-]+)"i,line)
  if m!=nothing
    value = parse(Float64,m.captures[1])
    push!(smv.values,value)
    return true
  else
    return false
  end
end

function parseline!(lf::NonSteppedLogFile, ::FooterDate, line::ASCIIString)
  m = match(r"Date:\s*(.*?)\s*$",line)
  if m!=nothing
    timestamp = DateTime(m.captures[1],"e u d HH:MM:SS yyyy")
    lf.timestamp = timestamp
    return true
  else
    return false
  end
end
function parseline!(lf::SteppedLogFile, x::FooterDate, line::ASCIIString)
  parseline!(lf.nonsteppedlogfile,x,line)
end

function parseline!(lf::NonSteppedLogFile, ::FooterDuration, line::ASCIIString)
  m = match(r"Total[ ]elapsed[ ]time:\s*([\w.]+)\s+seconds.\s*$",line)
  if m!=nothing
    duration = parse(Float64,m.captures[1])
    lf.duration = duration
    return true
  else
    return false
  end
end
function parseline!(lf::SteppedLogFile, x::FooterDuration, line::ASCIIString)
    parseline!(lf.nonsteppedlogfile,x,line)
end

function processlines!(io::IO, lf::LogFile, findlines, untillines=[])
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

function parselog(logpath::ASCIIString)
  header = HeaderCircuitPath()
  measurement = Measurement()
  stepparameters = StepParameters()
  footerdate = FooterDate()
  footerduration = FooterDuration()
  io = open(logpath,true,false,false,false,false)
  lf = NonSteppedLogFile()
  lf.logpath = logpath
  slf = SteppedLogFile(lf)
  exitcode = processlines!(io, slf, [header],[measurement,stepparameters])
  if exitcode == 1 # a non-steped log file
    exitcode = processlines!(io, lf, [measurement],[footerdate])
    lf.measurementnames = measurement.measurementnames
    lf.measurements = reshape(measurement.measurements,length(measurement.measurements),1,1,1)
    processlines!(io,slf,[footerduration])
    close(io)
    return lf
  else # a steped log file
    stepmeasurementname = StepMeasurementName()
    stepmeasurementvalue = StepMeasurementValue()
    footerdate = FooterDate()
    # parse the step parameters
    exitcode = processlines!(io,slf,[stepparameters],[stepmeasurementname, footerdate])
    while exitcode<2 # keep processing until we get a footerdate
      exitcode = processlines!(io,slf,[stepmeasurementvalue],[stepmeasurementname, footerdate])
    end
    # reshape measurement values
    lengthnames = length(slf.nonsteppedlogfile.measurementnames)
    if lengthnames >0
      zeroisone(x) = x==0?1:x
      lengthsweep1 = zeroisone(length(slf.steps[1]))
      lengthsweep2 = zeroisone(length(slf.steps[2]))
      lengthsweep3 = zeroisone(length(slf.steps[3]))
      measurementdimentions = (lengthnames, lengthsweep1, lengthsweep2, lengthsweep3)
      slf.nonsteppedlogfile.measurements = Array(Float64, measurementdimentions...)
      i = 1
      for nameindex in 1:lengthnames
        for sweep3index in 1:lengthsweep3
          for sweep2index in 1:lengthsweep2
            for sweep1index in 1:lengthsweep1
              slf.nonsteppedlogfile.measurements[nameindex,sweep1index,sweep2index,sweep3index] = stepmeasurementvalue.values[i]
              i+=1
            end
          end
        end
      end
    else # no measurements if a special case
      slf.nonsteppedlogfile.measurements = Array(Float64,0,0,0,0)
    end
    processlines!(io,slf,[footerduration])
    close(io)
    return slf
  end
end

function Base.parse{T<:LogFile}(::Type{T}, logpath::ASCIIString)
  lf = parselog(logpath)
  if typeof(lf)!=T
    throw(ParseError(".log file is not expected type (stepped or nonstepped)"))
  end
  return lf::T
end


function Base.parse{T<:LogFile}(x::T)
  # reread log file from disk
  # should not change type (steppped, non stepped)
  lf::T = parse(T, getlogpath(x))  
  return lf
end

### END overloading Base ###

### BEGIN LogFile specific methods ###

getlogpath(x::NonSteppedLogFile) = x.logpath
getlogpath(x::SteppedLogFile) = getlogpath(x.nonsteppedlogfile)
getcircuitpath(x::NonSteppedLogFile) = x.circuitpath
getcircuitpath(x::SteppedLogFile) = getcircuitpath(x.nonsteppedlogfile)
getmeasurementnames(x::NonSteppedLogFile) = x.measurementnames
getmeasurementnames(x::SteppedLogFile) = getmeasurementnames(x.nonsteppedlogfile)
getmeasurements(x::NonSteppedLogFile) = x.measurements
getmeasurements(x::SteppedLogFile) = getmeasurements(x.nonsteppedlogfile)
getstepnames(x::SteppedLogFile) = x.stepnames
getsteps(x::SteppedLogFile) = x.steps

### END LogFile specific methods ###

### BEGIN other ###



### END other