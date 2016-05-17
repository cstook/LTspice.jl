
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
type IsStepParameters <: LogLine end
type StepParameters <: LogLine 
  stepvalues :: Int
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
logpath!(nslf::NonSteppedLogFile,path::AbstractString) = nslf.logpath = path
logpath(nslf::NonSteppedLogFile) = nslf.logpath
circuitpath!(nslf::NonSteppedLogFile,path::AbstractString) = nslf.circuitpath = path
circuitpath(nslf::NonSteppedLogFile) = nslf.circuitpath
timestamp!(nslf::NonSteppedLogFile,ts::DateTime) = nslf.timestamp = ts 
timestamp(nslf::NonSteppedLogFile) = nslf.timestamp
duration!(nslf::NonSteppedLogFile,duration) = nslf.duration = duration 
duration(nslf::NonSteppedLogFile) = nslf.duration
measurementnames!(nslf::NonSteppedLogFile,measurementnames) = nslf.measurementnames = measurementnames
measurementnames(nslf::NonSteppedLogFile) = nslf.measurementnames
measurementvalues!(nslf::NonSteppedLogFile,measurements) = nslf.measurements = measurements
measurementvalues(nslf::NonSteppedLogFile) = nslf.measurements
stepnames(nslf::NonSteppedLogFile) = []

type SteppedLogFile <: LogFile
  nonsteppedlogfile :: NonSteppedLogFile
  stepnames         :: Array{ASCIIString,1}
  stepvalues             :: Tuple{Array{Float64,1},Array{Float64,1},Array{Float64,1}}
  SteppedLogFile(nslf::NonSteppedLogFile) = new(nslf,[],([],[],[])) 
end
SteppedLogFile() = SteppedLogFile(NonSteppedLogFile())
SteppedLogFile(logpath::ASCIIString) = SteppedLogFile(NonSteppedLogFile(logpath))
stepnames!(slf::SteppedLogFile, s::Array{ASCIIString,1}) = slf.stepnames = s
stepnames(slf::SteppedLogFile) = slf.stepnames
stepvalues(slf::SteppedLogFile) = slf.stepvalues
logpath(slf::SteppedLogFile) = logpath(slf.nonsteppedlogfile)
logpath!(slf::SteppedLogFile,path::AbstractString) = logpath!(slf.nonsteppedlogfile,path)
circuitpath(slf::SteppedLogFile) = circuitpath(slf.nonsteppedlogfile)
circuitpath!(slf::SteppedLogFile,path::AbstractString) = circuitpath!(slf.nonsteppedlogfile,path)
timestamp(slf::SteppedLogFile) = timestamp(slf.nonsteppedlogfile)
timestamp!(slf::SteppedLogFile,ts::DateTime) = timestamp!(slf.nonsteppedlogfile,ts)
duration(slf::SteppedLogFile) = duration(slf.nonsteppedlogfile)
duration!(slf::SteppedLogFile,duration) = duration!(slf.nonsteppedlogfile,duration)
measurementnames(slf::SteppedLogFile) = measurementnames(slf.nonsteppedlogfile)
measurementnames!(slf::SteppedLogFile,measurementnames) = measurementnames!(slf.nonsteppedlogfile,measurementnames)
measurementvalues(slf::SteppedLogFile) = measurementvalues(slf.nonsteppedlogfile)
measurementvalues!(slf::SteppedLogFile,measurements) = measurementvalues!(slf.nonsteppedlogfile,measurements)

# END LogFile

### BEGIN overloading Base ###

function Base.show(io::IO, x::NonSteppedLogFile)
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

function Base.show(io::IO, x::SteppedLogFile)
   show(io,x.nonsteppedlogfile) 
   if length(stepnames(x))>0
    println(io,"")
    println(io,"Step")
    for name in stepnames(x)
      println(io,"  ",name)
    end
  end
end

# NonSteppedLogFile is a read only Dict of its measurements
Base.haskey(x::NonSteppedLogFile,key::ASCIIString) = findfirst(measurementnames(x),key) > 0
Base.haskey(x::SteppedLogFile,   key::ASCIIString) = false
Base.keys(x::NonSteppedLogFile)   = measurementnames(x)
Base.keys(x::SteppedLogFile)      = []
Base.values(x::NonSteppedLogFile) = measurementvalues(x)[:,1,1,1]
Base.values(x::SteppedLogFile)    = []
Base.length(x::NonSteppedLogFile) = length(measurementnames(x))
Base.eltype(x::NonSteppedLogFile) = Float64
function Base.getindex(x::NonSteppedLogFile, key::ASCIIString)
  i = findfirst(measurementnames(x),key)
  if i == 0
    throw(KeyError(key))
  end
  return measurementvalues(x)[i,1,1,1]
end

# LogFile can access its measurements as a read only array
Base.getindex(x::NonSteppedLogFile, index::Integer) = measurementvalues(x)[index,1,1,1]
Base.getindex(x::LogFile, i1::Integer, i2::Integer, i3::Integer, i4::Integer) = 
  measurementvalues(x)[i1,i2,i3,i4]

Base.length(x::SteppedLogFile) = length(measurementvalues(x))

# NonSteppedLogFile iterates over its Dict
Base.start(x::NonSteppedLogFile) = 1
function Base.next(x::NonSteppedLogFile,state)
  return (measurementnames(x)[state]=>measurementvalues(x)[state,1,1,1],state+1)
end
Base.done(x::NonSteppedLogFile, state) = state > length(measurementnames(x))

function parseline!(lf::LogFile, ::HeaderCircuitPath, line::ASCIIString)
  m = match(r"^Circuit: \*\s*([\w\:\\/. ~]+)"i,line)
  if m!=nothing
    circuitpath!(lf,m.captures[1])
    return true
  else
    return false
  end
end

function parseline!(lf::LogFile, measurement::Measurement, line::ASCIIString)
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
function parseline!(::NonSteppedLogFile, ::IsStepParameters, line::ASCIIString)
  ismatch(stepregex, line)
end

function parseline!(slf::SteppedLogFile, sp::StepParameters, line::ASCIIString)
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

function parseline!(slf::SteppedLogFile, smn::StepMeasurementName, line::ASCIIString)
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

function parseline!(::SteppedLogFile, smv::StepMeasurementValue, line::ASCIIString)
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

function parseline!(lf::LogFile, ::FooterDate, line::ASCIIString)
  m = match(r"Date:\s*(.*?)\s*$",line)
  if m!=nothing
    timestamp = DateTime(m.captures[1],"e u d HH:MM:SS yyyy")
    timestamp!(lf,timestamp)
    return true
  else
    return false
  end
end

function parseline!(lf::LogFile, ::FooterDuration, line::ASCIIString)
  m = match(r"Total[ ]elapsed[ ]time:\s*([\w.]+)\s+seconds.\s*$",line)
  if m!=nothing
    duration = parse(Float64,m.captures[1])
    duration!(lf,duration)
    return true
  else
    return false
  end
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

function Base.parse(::Type{SteppedLogFile}, logpath::ASCIIString)
  header = HeaderCircuitPath()
  measurement = Measurement()
  stepparameters = StepParameters()
  footerdate = FooterDate()
  footerduration = FooterDuration()
  lf = NonSteppedLogFile()
  logpath!(lf,logpath)
  slf = SteppedLogFile(lf)
  io = open(logpath,true,false,false,false,false)
  exitcode = processlines!(io, slf, [header],[measurement,stepparameters])
  if exitcode == 1 # a non-steped log file
    close(io)
    throw(ParseError(".log file is not expected type.  expexted SteppedLogFile, got NonSteppedLogFile"))
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

function Base.parse(::Type{NonSteppedLogFile}, logpath::ASCIIString)
  header = HeaderCircuitPath()
  measurement = Measurement()
  isstepparameters = IsStepParameters()
  footerdate = FooterDate()
  footerduration = FooterDuration()
  lf = NonSteppedLogFile()
  logpath!(lf,logpath)
  io = open(logpath,true,false,false,false,false)
  exitcode = processlines!(io, lf, [header],[measurement,isstepparameters])
  if exitcode == 2 # this was supposed to be a NonSteppedFile
    close(io)
    throw(ParseError(".log file is not expected type.  expexted NonSteppedLogFile, got SteppedLogFile"))
  end
  exitcode = processlines!(io, lf, [measurement],[footerdate])
  measurementnames!(lf, measurement.measurementnames)
  measurementvalues!(lf, reshape(measurement.measurements,length(measurement.measurements),1,1,1))
  processlines!(io,lf,[footerduration])
  close(io)
  return lf
end

Base.parse{T<:LogFile}(x::T) = parse(T, logpath(x))  
