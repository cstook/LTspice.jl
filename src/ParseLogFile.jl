# overload parse for LogFile type
# used to parse LTspice log files


type LogFile
  logpath         :: ASCIIString  # path to log file
  circuitpath     :: ASCIIString  # path to circuit file in the log file
  timestamp       :: DateTime
  duration        :: Float64  # simulation time in seconds
  stepnames      :: Array{ASCIIString,1}
  steps          :: Tuple{Array{Float64,1},Array{Float64,1},Array{Float64,1}}
  measurementnames:: Array{ASCIIString,1}   
  measurements     :: Array{Float64,4}
end

getlogpath(x::LogFile) = x.logpath
getcircuitpath(x::LogFile) = x.circuitpath
getstepnames(x::LogFile) = x.stepnames
getsteps(x::LogFile) = x.steps
getmeasurementnames(x::LogFile) = x.measurementnames
getmeasurement(x::LogFile) = x.measurementnames

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
  for line in lines
    if state == 0  # looking for "Circuit:"
#      println("state = 0")
      m = match(r"^Circuit: \*\s*(.+)",line)
      if m!=nothing
        circuitpath = m.captures[1]
#        println("found circuit file  $circuitpath")
        state = 1
      end
    elseif state == 1 # look for either ".step" or measurement
#      println("state = 1")
      regex = r"^(?:(\w+):|(\.step)
        (?:\s+(.*?)=(.*?))
        (?:\s+(.*?)=(.*?)){0,1}
        (?:\s+(.*?)=(.*?)){0,1}\s*$)"x
      m = match(regex,line)
      if m!=nothing  
        if m.captures[1]!=nothing # we have a measurement
          println("found measurment $(m.captures[1])")
          push!(measurementnames,m.captures[1]) # save the name
        elseif m.captures[2]!=nothing # we have a step
#          println("found step")
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
      elseif isstep # if we are seeing .step's and then see a blank line
        state = 2 # start looking for stepped measurements
      end
    elseif state ==  2 # look for stepped measurements or date or time
      regex = r"^(?:Measurement:\s*(\w+)\s*$|
        Date:\s*(.*?)\s*$|
        Total[ ]elapsed[ ]time:\s*([\w.]+)\s+seconds.\s*$)"x
      m = match(regex,line)
      if m!= nothing
        if m.captures[1]!=nothing
          println("found stepped measurment")
          push!(measurementnames,m.captures[1]) # save the name
        elseif m.captures[2]!=nothing
          println("found time date")
          timestamp = DateTime(m.captures[2],"e u d HH:MM:SS yyyy")
        else 
          println("found duration")
          duration = parse(Float64,m.captures[3])
        end
      end
    end
  end
  # now that we know the size of the data arrays
  # we can create and fill them in
  #=
  IOlog = open(logpath,true,false,false,false,false) # open log file read only
  lines = eachline(IOlog)
  if isstep 
  =#
  measurements = Array(Float64,1,1,1,1)
  return LogFile(logpath, circuitpath, timestamp, duration, stepnames, steps, measurementnames, measurements)
end





