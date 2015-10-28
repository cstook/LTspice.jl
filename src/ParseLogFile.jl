# overload parse for LogFile type
# used to parse LTspice log files

include("MultiLevelIterator.jl")

import Base: parse, show
import Base: haskey, keys, values
import Base: getindex, setindex!, endof
import Base: start, next, done, length, eltype

### BEGIN abstract type LogFile, subtypes and constructors ###

abstract LogFile

type NonSteppedLogFile <: LogFile
  logpath           :: ASCIIString  # path to log file
  circuitpath       :: ASCIIString  # path to circuit file in the log file
  timestamp         :: DateTime
  duration          :: Float64  # simulation time in seconds
  measurementnames  :: Array{ASCIIString,1}   
  measurements      :: Array{Float64,4}

  function NonSteppedLogFile(logpath::ASCIIString)
    new(logpath,"",DateTime(2015),0.0,[],Array(Float64,0,0,0,0))
  end
  function NonSteppedLogFile(logpath, circuitpath, timestamp, duration, measurementnames, measurements)
    new(logpath, circuitpath, timestamp, duration, measurementnames, measurements)
  end
end

type SteppedLogFile <: LogFile
  nonsteppedlogfile :: NonSteppedLogFile
  stepnames         :: Array{ASCIIString,1}
  steps             :: Tuple{Array{Float64,1},Array{Float64,1},Array{Float64,1}}

  function SteppedLogFile(logpath::ASCIIString)
    new(NonSteppedLogFile(logpath),[],([],[],[]))
  end
  function SteppedLogFile(nslf, stepnames,steps)
    new(nslf, stepnames,steps)
  end
end

### END abstract type LogFile, subtypes and constructors ###

### BEGIN overloading Base ###

function show(io::IO, x::NonSteppedLogFile)
  println(io,x.logpath)  
  println(io,x.circuitpath)
  println(io,x.timestamp)
  println(io,"$(x.duration) seconds")
  if length(x.measurementnames)>0
    println(io,"")
    println(io,"Measurements")
    for name in x.measurementnames
      println(io,"  $name")
    end
  end
end

function show(io::IO, x::SteppedLogFile)
   show(io,x.nonsteppedlogfile) 
   if length(x.stepnames)>0
    println(io,"")
    println(io,"Step")
    for name in x.stepnames
      println(io,"  $name")
    end
  end
end

# NonSteppedLogFile is a read only Dict of its measurements
haskey(x::NonSteppedLogFile,key::ASCIIString) = findfirst(x.measurementnames,key) > 0
haskey(x::SteppedLogFile,   key::ASCIIString) = false
keys(x::NonSteppedLogFile)   = x.measurementnames
keys(x::SteppedLogFile)      = []
values(x::NonSteppedLogFile) = x.measurements[:,1,1,1]
values(x::SteppedLogFile)    = []
length(x::NonSteppedLogFile) = length(getmeasurementnames(x))
eltype(x::NonSteppedLogFile) = Float64
function getindex(x::NonSteppedLogFile, key::ASCIIString)
  i = findfirst(x.measurementnames,key)
  if i == 0
    throw(KeyError(key))
  end
  return x.measurements[i,1,1,1]
end

# LogFile can access its measurments as a read only array
getindex(x::NonSteppedLogFile, index::Int) = x.measurements[index,1,1,1]
function getindex(x::NonSteppedLogFile, i1::Int, i2::Int, i3::Int, i4::Int)
  x.measurements[i1,i2,i3,i4]
end
function getindex(x::SteppedLogFile, i1::Int, i2::Int, i3::Int, i4::Int)
  getmeasurements(x.nonsteppedlogfile)[i1,i2,i3,i4]
end

length(x::SteppedLogFile) = length(getmeasurements(x))

# NonSteppedLogFile iterates over its Dict
start(x::NonSteppedLogFile) = 1
function next(x::NonSteppedLogFile,state)
  return (x.measurementnames[state]=>x.measurements[state,1,1,1],state+1)
end
done(x::NonSteppedLogFile, state) = state > length(x.measurementnames)

function parse(::Type{LogFile}, logpath::ASCIIString)  
  IOlog = open(logpath,true,false,false,false,false) # open log file read only
  lines = eachline(IOlog)
  # scan file once to get measurement names, step names
  # and a few other items
  # data will be read on second scan
  measurementnames = Array(ASCIIString,0)
  stepnames = Array(ASCIIString,0)
  circuitpath = ""
  timestamp = DateTime(2015)
  duration = 0.0
  steps = (Array(Float64,0),Array(Float64,0),Array(Float64,0))
  state = 0
  isstep = false
  foundmeasurement = false
  for line in lines
    if state == 0  # looking for "Circuit:"
      m = match(r"^Circuit: \*\s*([\w\:\\/. ~]+)",line)
      if m!=nothing
        circuitpath = m.captures[1]
        state = 1
      end
    elseif state == 1 # look for either ".step" or measurement
      regex = r"^(?:([a-z][a-z0-9_@#$.:\\]*):|
        (\.step)
        (?:\s+(.*?)=(.*?))
        (?:\s+(.*?)=(.*?)){0,1}
        (?:\s+(.*?)=(.*?)){0,1}\s*$)"ix
      m = match(regex,line)
      if m!=nothing  
        if m.captures[1]!=nothing # we have a measurement
          foundmeasurement = true
          push!(measurementnames,m.captures[1]) # save the name
        elseif m.captures[2]!=nothing # we have a step
          if ~isstep # grab the names from the first line
            for i in (3,5,7)
              if m.captures[i] != nothing  # we have a step name
                push!(stepnames,m.captures[i]) # save the name
              end
            end
          end
          for (i,k) in ((4,1),(6,2),(8,3))
            if m.captures[i] != nothing # we have a value
              value = parse(Float64,m.captures[i])
              if ~issubset(value,steps[k]) # if we haven't seen this value yet
                push!(steps[k],value) # add it to the list
              end 
            end
          end
          isstep = true
        end
      elseif isstep || foundmeasurement # if we are seeing .step's measurements and then see a blank line
        state = 3 # check to see if a measurment failed
      end
    elseif state ==  2 # look for stepped measurements or date or time
      regex = r"^(?:Measurement:\s*([a-z][a-z0-9_@#$.:\\]*)\s*$|
        Date:\s*(.*?)\s*$|
        Total[ ]elapsed[ ]time:\s*([\w.]+)\s+seconds.\s*$)"ix
      m = match(regex,line)
      if m!= nothing
        if m.captures[1]!=nothing # found a measurement
          push!(measurementnames,m.captures[1]) # save the name
        elseif m.captures[2]!=nothing # found time stamp
          timestamp = DateTime(m.captures[2],"e u d HH:MM:SS yyyy")
        else # found duration
          duration = parse(Float64,m.captures[3])
        end
      end
    elseif state == 3 # test for failed measurement, and ignore that it failed
      if ismatch(r"^Measurement.*FAIL'ed",line)
        state = 1
      else
        state = 2
      end
    end
  end
  close(IOlog)  # do I need to do this?
  #=
  now that we know the size of the data 
  we can create and fill in measurements array
  dimensions
    1 - measurementnames is header
    2 - inner sweep.  steps[1] is header. stepname[1] is name.
    3 - middle sweep. steps[2] is header. stepname[2] is name.
    4 - outer sweep.  steps[3] is header. stepname[3] is name.
  =#
  # restart at beginning of file
  zeroisone(x) = x==0?1:x
  l1 = length(measurementnames)
  if l1 > 0 
    IOlog = open(logpath,true,false,false,false,false) # open log file read only
    if isstep
      l2 = zeroisone(length(steps[1]))
      l3 = zeroisone(length(steps[2]))
      l4 = zeroisone(length(steps[3]))
      measurementsiterator = MultiLevelIterator([l2,l3,l4,l1])
      measurements = Array(Float64,l1,l2,l3,l4)
      ismeasurementblock = false
      state = start(measurementsiterator)
      while ~done(measurementsiterator,state) && ~eof(IOlog)
        line = readline(IOlog)
        if ismeasurementblock
          m = match(r"^\s*[0-9]+\s+([0-9.eE+-]+)"i,line)
          if m != nothing
            value = parse(Float64,m.captures[1])
            (i,state) = next(measurementsiterator,state)
            measurements[i[4],i[1],i[2],i[3]] = value
          else 
            ismeasurementblock = false 
          end
        else 
          if ismatch(r"^Measurement:",line)
            line = readline(IOlog)
            ismeasurementblock = true
          end
        end
      end
    else
      measurements = Array(Float64,l1,1,1,1)
      line = ""; lom = 0; shortline = true; foundmatch = false
      for (i,measurement) in enumerate(measurementnames)
        lom = length(measurement)+1
        foundmatch = false
        while ~foundmatch && ~eof(IOlog)
          shortline = true
          while shortline && ~eof(IOlog)
            line = readline(IOlog)
            shortline = length(line)<lom
          end
          foundmatch = line[1:lom] == measurement*":"
        end
        m = match(r"^[a-z][a-z0-9_@#$.:\\]*:.*?=([0-9.eE+-]+)"i,line)
        measurements[i,1,1,1] = parse(Float64,m.captures[1])
      end

#=
      measurementsrange = 1:l1  
      line = readline(IOlog)
      line = readline(IOlog)
      while ~ismatch(r"^[a-z][a-z0-9_@#$.:\\]*:"i,line)
        line = readline(IOlog)
      end
      for i in measurementsrange
        m = match(r"^[a-z][a-z0-9_@#$.:\\]*:.*?=([0-9.eE+-]+)"i,line)
        measurements[i,1,1,1] = parse(Float64,m.captures[1])
        line = readline(IOlog)
      end
=#
      if eof(IOlog) 
        throw(ParseError("log file EOF before all measurements found."))
      end
    end
  else 
    measurements = Array(Float64,0,0,0,0)
  end
  cpascii = convert(ASCIIString,copy(circuitpath))
  nslf = NonSteppedLogFile(logpath, cpascii, timestamp, duration, measurementnames, measurements)
  close(IOlog)
  if isstep
    return SteppedLogFile(nslf, stepnames, steps)
  else 
    return nslf 
  end
end

function parse{T<:LogFile}(x::T)
  # reread log file from disk
  # should not change type (steppped, non stepped)
  lf::T = parse(LogFile, getlogpath(x))  
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