# overloard parse for the CircuitFile type
# used to parse LTspice circuit files *.asc

import Base: parse, show
import Base: haskey, keys, values
import Base: getindex, setindex!, endof
import Base: start, next, done, length, eltype

#export CircuitFile, getcircuitpath, getmeasurmentnames, getstepnames
#export isneedsupdate

### BEGIN Type CircuitFile and constructors ###

type CircuitFile
	circuitpath			:: ASCIIString
	circuitfilearray:: Array{ASCIIString,1}    # text of circuit file
  parameternames  :: Array{ASCIIString,1}
  parameters      :: Array{Tuple{Float64,Float64,Int},1}  # array of parameters (value, multiplier, index)
  measurementnames:: Array{ASCIIString,1}              # measurment names
  stepnames			  :: Array{ASCIIString,1}  
  needsupdate			:: Bool # true if any parameter has been changed
end

### END Type CircuitFile and constructors ###

### BEGIN overloading Base ###

function show(io::IO, x::CircuitFile)
	println(io,x.circuitpath)
  if length(x.parameters)>0
  	println(io,"")
  	println(io,"Parameters")
  	for (key,(value,m,i)) in zip(x.parameternames,x.parameters)
    	println(io,"  $(rpad(key,25,' ')) = $value")
  	end
  end
 	if length(x.measurementnames)>0 
 		println(io,"")
 		println(io,"Measurments")
 	  for name in x.measurementnames
 		 println(io,"  $name")
 	  end
  end
 	if length(x.stepnames)>0
 		println(io,"")
 		println(io,"Sweeps")
 	  for name in x.stepnames
 		 println(io,"  $name")
 	  end
  end
end

# CircuitFile is a Dict of its parameters
haskey(x::CircuitFile,key::ASCIIString) = findfirst(x.parameternames, key) != 0
keys(x::CircuitFile) = [key for key in x.parameternames]
values(x::CircuitFile) = [parameter[1] for parameter in x.parameters]
function getindex(x::CircuitFile, key::ASCIIString)
  k = findfirst(x.parameternames, key)
  if k == 0 
    throw(KeyError(key))
  else
    return x.parameters[k][1]
  end
end

function setindex!(x::CircuitFile, value:: Float64, key:: ASCIIString)
  k = findfirst(x.parameternames, key)
  if k == 0 
    throw(KeyError(key))
  else
    x[k] = value
  end
end

function setindex!(x::CircuitFile, value:: Float64, index:: Int)
  (v,m,i) = x.parameters[index]
  x.parameters[index] = (value,m,i)
  x.circuitfilearray[i] = "$(value/m)"
  x.needsupdate = true
end

length(x::CircuitFile) = length(x.parameters)
eltype(::CircuitFile) = Float64

# CircuitFile iterates over its Dict
start(x::CircuitFile) = 0
function next(x::CircuitFile, state)
  state +=1
  return ((x.parameternames[state]=>x.parameters[state][1]),state)
end
done(x::CircuitFile, state) = ~(state < length(x.parameters))

function parse(::Type{CircuitFile}, circuitpath::ASCIIString)
  #= 
  circuit file array
    The circuit file array is an array of strings which when concatenated
    produce the circuit file.  The elements of the array split the file 
    around parameter values to avoid parsing the file every time a parameter
    is modified
  =#
  IOcircuit  = open(circuitpath,true,false,false,false,false)
  lines = eachline(IOcircuit)
  parameternames = Array(ASCIIString,0)
  parameters = Array(Tuple{Float64,Float64,Int},0)
  measurementnames = Array(ASCIIString,0)
  stepnames	= Array(ASCIIString,0)
  circuitfilearray = Array(ASCIIString,0)
  # parse the file
  regexposition = 1
  cfaposition = 1
  i = 0
  for line in lines
    regexposition = 1
    cfaposition = 1  # has been put in cfa up to (not including) this position
    if ismatch(r"^TEXT .*?!"i,line) # found a directive
      while regexposition < endof(line)
        m = match(r"""[.](parameter|param)[ ]+|
                        [.](measure|meas)[ ]+|
                        [.](step)[ ]+"""ix,line,regexposition)
        if m == nothing
          regexposition = endof(line)
        else
          if m.captures[1] != nothing  # a parameter card
            regexposition = m.offsets[1]+length(m.captures[1])+1
            parametermatch = match(r"""([a-z][a-z0-9_@#$.:\\]*)[= ]+
                                       ([-+]{0,1}[0-9.]+e{0,1}[-+0-9]*)
                                       (k|meg|g|t|m|u|n|p|f){0,1}
                                       [ ]*(?:\\n|\r|$)"""ix,
                                   line,regexposition)
            if parametermatch != nothing
              regexposition += length(parametermatch.match)-1
              parametername = parametermatch.captures[1]
              parametervalue = parametermatch.captures[2]
              valueoffset = parametermatch.offsets[2]  # offset in line
              valuelength = length(parametervalue)
              valueend = valuelength + valueoffset # pos of end of value in line
              parameterunit = parametermatch.captures[3]
              push!(circuitfilearray,line[cfaposition:valueoffset-1]) # before the value
              cfaposition = valueoffset
              i+=1
              push!(circuitfilearray,line[cfaposition:valueend-1]) # the value
              cfaposition = valueend
              i+=1
              if haskey(units,parameterunit)
                multiplier = units[parameterunit]
              else
                multiplier = 1.0
              end
              valuenounit = parse(Float64,parametervalue)
              push!(parameternames, lowercase(parametername))
              push!(parameters, (valuenounit * multiplier, multiplier, i))
            end
          elseif m.captures[2] != nothing # a measure card
            regexposition = m.offsets[2]+length(m.captures[2])+1
            measurematch = match(r"""(?:ac |dc |op |tran |tf |noise ){0,1}
                                  [ ]*([a-z][a-z0-9_@#$.:\\]*)[ ]+"""ix,
                                line,regexposition)
            regexposition +=length(measurematch.match)-1
            measurename = measurematch.captures[1]
            push!(measurementnames,lowercase(measurename))
            regexposition += length(measurematch.match)-1
          elseif m.captures[3] != nothing # a step card
            regexposition = m.offsets[3]+length(m.captures[3])+1
            step1match = match(r"""(?:oct |param ){0,1}
                                [ ]*([a-z][a-z0-9_@#$.:\\]*)[ ]+(?:list ){0,1}
                                [ ]*[0-9.e+-]+[a-z]*[ ]+"""ix,
                                line, regexposition)
            if step1match != nothing # one type of step card
              regexposition += length(step1match.match)-1
              stepname = step1match.captures[1]
              push!(stepnames, lowercase(stepname))
            else
              step2match = match(r"(\w+)[ ]+(\w+[(]\w+[)])[ ]+"i,
                                line,regexposition)
              if step2match != nothing # the other type of step card
                regexposition += length(step2match.match)-1
                stepname = step2match.captures[2]
                push!(stepnames, lowercase(stepname))
              end
            end
          end
        end
      end
      if cfaposition<=endof(line)
        push!(circuitfilearray,line[cfaposition:endof(line)])
        cfaposition = endof(line)+1
        i+=1
      end
    else
      push!(circuitfilearray,line)
      i+=1
    end
  end
  close(IOcircuit)
  return CircuitFile(circuitpath, circuitfilearray, parameternames, parameters,
                     measurementnames, stepnames, false)
end

### END overloading Base ###

### BEGIN CircuitFile specific methods ###

"writes circuit file back to disk if any parameters have changed"
function update!(x::CircuitFile)
	if x.needsupdate
		io = open(x.circuitpath,false,true,false,false,false)  # open circuit file to be overwritten
		for text in x.circuitfilearray
      print(io,text)
		end
		close(io)
  	x.needsupdate = false
  end
  return nothing
end

getcircuitpath(x::CircuitFile) = x.circuitpath
getparameternames(x::CircuitFile) = x.parameternames
getparameters(x::CircuitFile) = [parameter[1] for parameter in x.parameters]
getmeasurementnames(x::CircuitFile) = x.measurementnames
getstepnames(x::CircuitFile) = x.stepnames
hassteps(x::CircuitFile) = length(x.stepnames) != 0
hasmeasurements(x::CircuitFile) = length(x.measurementnames) != 0
hasparameters(x::CircuitFile) = length(x.parameters) != 0

### END CircuitFile specific methods ###

### Begin other ###

# units as defined in LTspice
units = Dict()
units["K"] = 1.0e3
units["k"] = 1.0e3
units["MEG"] = 1.0e6
units["meg"] = 1.0e6
units["G"] = 1.0e9
units["g"] = 1.0e9
units["T"] = 1.0e12
units["t"] = 1.0e12
units["M"] = 1.0e-3
units["m"] = 1.0e-3
units["U"] = 1.0e-6
units["u"] = 1.0e-6
units["N"] = 1.0e-9
units["n"] = 1.0e-9
units["P"] = 1.0e-12
units["p"] = 1.0e-12
units["F"] = 1.0e-15
units["f"] = 1.0e-15

### END other ###
