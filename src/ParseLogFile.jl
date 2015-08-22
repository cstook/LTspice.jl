# overload parse for LogFile type
# used to parse LTspice log files

include("MultiLevelIterator.jl")

import Base:show, parse


type LogFile
  logpath           :: ASCIIString  # path to log file
  circuitpath       :: ASCIIString  # path to circuit file in the log file
  timestamp         :: DateTime
  duration          :: Float64  # simulation time in seconds
  stepnames         :: Array{ASCIIString,1}
  steps             :: Tuple{Array{Float64,1},Array{Float64,1},Array{Float64,1}}
  measurementnames  :: Array{ASCIIString,1}   
  measurements      :: Array{Float64,4}
  isstep            :: Bool
end

getlogpath(x::LogFile) = x.logpath
getcircuitpath(x::LogFile) = x.circuitpath
getstepnames(x::LogFile) = x.stepnames
getsteps(x::LogFile) = x.steps
getmeasurementnames(x::LogFile) = x.measurementnames
getmeasurements(x::LogFile) = x.measurements
isstep(x::LogFile) = x.isstep

function haskey(x::LogFile,key::ASCIIString)
  if x.isstep
    return false  # Dict interface only for non stepped simulations
  else
    return issubset(key,x.measurementnames)
  end
end

function keys(x::Logfile)
  if x.isstep 
    return false
  else 
    return x.measurementnames
  end
end

function values(x::LogFile)
  if x.isstep 
    return false
  else
    return x.measurement[:,1,1,1]
  end
end

function show(io::IO, x::LogFile)
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
   if length(x.stepnames)>0
    println(io,"")
    println(io,"Step")
    for name in x.stepnames
      println(io,"  $name")
    end
  end
end

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
      m = match(r"^Circuit: \*\s*([\w\:\\/. ]+)",line)
      if m!=nothing
        circuitpath = m.captures[1]
        state = 1
      end
    elseif state == 1 # look for either ".step" or measurement
      regex = r"^(?:(\w+):|(\.step)
        (?:\s+(.*?)=(.*?))
        (?:\s+(.*?)=(.*?)){0,1}
        (?:\s+(.*?)=(.*?)){0,1}\s*$)"x
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
      elseif isstep | foundmeasurement # if we are seeing .step's measurements and then see a blank line
        state = 2 # start looking for stepped measurements
      end
    elseif state ==  2 # look for stepped measurements or date or time
      regex = r"^(?:Measurement:\s*(\w+)\s*$|
        Date:\s*(.*?)\s*$|
        Total[ ]elapsed[ ]time:\s*([\w.]+)\s+seconds.\s*$)"x
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
  l1 = length(measurementnames)
  if l1 > 0 
    IOlog = open(logpath,true,false,false,false,false) # open log file read only
    if isstep
      l2 = length(steps[1])
      l3 = length(steps[2])
      l4 = length(steps[3])
      measurementsiterator = MultiLevelIterator([l2,l3,l4,l1])
      measurements = Array(Float64,l1,l2,l3,l4)
      ismeasurementblock = false
      state = start(measurementsiterator)
      while ~done(measurementsiterator,state) & ~eof(IOlog)
        line = readline(IOlog)
        if ismeasurementblock
          m = match(r"^\s*[0-9]+\s+([0-9.eE+-]+)",line)
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
      measurementsrange = 1:l1  
      line = readline(IOlog)
      line = readline(IOlog)
      while ~ismatch(r"^\w+:",line)
        line = readline(IOlog)
      end
      for i in measurementsrange
        m = match(r"^\w+:.*?=([0-9.eE+-]+)",line)
        measurements[i,1,1,1] = parse(Float64,m.captures[1])
        line = readline(IOlog)
      end
      if eof(IOlog) 
        error("log file parse error.  EOF before all measurements found.")
      end
    end
  else 
    measurements = Array(Float64,0,0,0,0)
  end
  return LogFile(logpath, circuitpath, timestamp, duration,
                 stepnames, steps, measurementnames,
                 measurements, isstep)
end





