# overload parse for LogFile type
# used to parse LTspice log files


type LogFile
  logpath         :: ASCIIString  # path to log file
  circuitpath     :: ASCIIString  # path to circuit file in the log file
  timestamp       :: DateTime
  duration        :: Float64  # simulation time in seconds
  stepnames      :: Array{ASCIIString,1}
  steps          :: Array{Array{Float64,1},1}
  measurementnames:: Array{ASCIIString,1}   
  measurments     :: Array{Float64,4}
end

getlogpath(x::LogFile) = x.logpath
getcircuitpath(x::LogFile) = x.circuitpath
getstepnames(x::LogFile) = x.stepnames
getsteps(x::LogFile) = x.steps
getmeasurmentnames(x::LogFile) = x.measurementnames
getmeasurement(x::LogFile) = x.measurementnames

function parse(::Type{LogFile}, logpath::ASCIIString)
  IOlog = open(logpath,true,false,false,false,false) # open log file read only
  lines = eachline(IOlog)
  # scan file once to get measurment names, step names
  # and a few other items
  # data will be read on second scan
  measurmentnames = Array(ASCIIString,0)
  stepnames = Array(ASCIIString,0)
  state = 0
  isstep = false
  for line in lines
    if state == 0  # looking for "Circuit:"
      m = match(r"^Circuit: \*\s*(.+)",line)
      if m!=nothing
        circuitpath = m.captures[1]
        state = 1
      end
    elseif state == 1 # look for either ".step" or measurment
      regex = r"^(?:(\w+):|(\.step)
        (?:\s+(.*?)=.*?)
        (?:\s+(.*?)=.*?){0,1}
        (?:\s+(.*?)=.*?){0,1}\s*$)",x
      m = match(regex,line)
      if m!=nothing  # we have a measurment
        if m.captures[1]!=nothing
          push!(measurmentnames,m.captures[1]) # save the name
        end
      elseif m!=nothing # we have a step
        isstep = true
        state = 2 # we have our names, just scan for measurments
        for i in (3,4,5)
          if m.captures[i] != nothing  # we have a step name
            push!(stepnames,m.captures[i]) # save the name
          end
        end
      end
    elseif state ==  2 # look for stepped measurments or date or time
      regex = r"^(?:Measurement:\s*(\w+)\s*$|
        Date:\s*(.*?)\s*$|
        Total[ ]elapsed[ ]time:\s*([\w.]+)\s+seconds.\s*$)"x
      m = match(regex,line)
      if m!= nothing
        if m.captures[1]!=nothing
          push!(measurmentnames,m.captures[1]) # save the name
        elseif m.captures[2]!=nothing
          timestamp = DateTime(m.captures[2],"e u d HH:MM:SS yyyy")
        else 
          duration = parse(Float64,m.captures[3])
        end
      end
    end
  end
  # now that we know the size of the data arrays
  # we can create and fill them in





end

# DateTime(dt,"e u d HH:MM:SS yyyy")

#=
non swept file
--------------

Circuit:
meas1:
meas2:
  .
  .
  .
meas_last:
Date:
Total elapsed time:


swept file
----------

Circuit:
.step
.step
  .
  .
  .
.step
Measurment: meas1
  {list of steps here}
Measurment: meas2
  {list of steps here}
    .
    .
    .
Measurment: meas_last
  {list of steps here}
Date:
Total elapsed time:






