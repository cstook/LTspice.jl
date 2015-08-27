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
	parameters 			:: Dict{ASCIIString,Tuple{Float64,Float64,Int}} # dictionay of parameters (value, multiplier, index)
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
  	for (key,(value,m,i)) in x.parameters
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
haskey(x::CircuitFile,key::ASCIIString) = haskey(x.parameters,key::ASCIIString)
keys(x::CircuitFile) = keys(x.parameters)

function values(x::CircuitFile)
  result = Array(Float64,0)
  for (key,(value,m,i)) in x.parameters
    push!(result,value)
  end
  return result
end

function getindex(x::CircuitFile, key::ASCIIString)
  (v,m,i) =  x.parameters[key]  # just want the value.  Hide internal stuff
  return v
end

function setindex!(x::CircuitFile, value:: Float64, key:: ASCIIString)
  (v,m,i) = x.parameters[key]
  x.parameters[key] = (value,m,i)
  x.circuitfilearray[i] = "$(value/m)"
  x.needsupdate = true
end

length(x::CircuitFile) = length(x.parameters)
eltype(::CircuitFile) = Float64

# CircuitFile iterates over its parameters
start(x::CircuitFile) = start(x.parameters)
function next(x::CircuitFile, state)
  ((key,(value,m,i)),state) = next(x.parameters, state)
  return ((key=>value),state)
end
done(x::CircuitFile, state) = done(x.parameters, state)

function parse(::Type{CircuitFile}, circuitpath::ASCIIString)
  #= reads circuit file and returns a tuple of
  Dict of parameters
  Dict of measurements, values N/A
  circuit file array
    The circuit file array is an array of strings which when concatenated
    produce the circuit file.  The elements of the array split the file 
    around parameter values to avoid parsing the file every time a parameter
    is modified
  =#
  ltspicefile = readall(circuitpath)            # read the circuit file
  # create empty dictionarys to be filled as file is parsed
  #key = parameter, value = (parameter value, multiplier, circuit file array index)
  parameters = Dict{ASCIIString,Tuple{Float64,Float64,Int}}() 
  measurementnames = Array(ASCIIString,0)
  stepnames	= Array(ASCIIString,0)
  circuitfilearray = Array(ASCIIString,1)
  circuitfilearray[1] = ""
  # regex used to parse file.  I know this is a bad comment.
  match_tags = r"""(
                ^TEXT .*?(!|;)|
                [.](param)[ ]+([A-Za-z0-9]*)[= ]*([0-9.eE+-]*)([a-z]*)|
                [.](measure|meas)[ ]+(?:ac|dc|op|tran|tf|noise)[ ]+(\w+)[ ]+|
                [.](step)[ ]+(oct |param ){0,1}[ ]*
                (\w+)[ ]+(?:list ){0,1}[ ]*[0-9.e+-]+[a-z]*[ ]+|
                [.](step)[ ]+(\w+)[ ]+(\w+[(]\w+[)])[ ]+
                )"""imx

  # parse the file
  directive = false   # true for directives, false for comments
  m = match(match_tags,ltspicefile)
  i = 1  # index for circuit file array
  position = 1   # pointer into ltspicefile
  old_position = 1
  while m!=nothing
    commentordirective = m.captures[2] # ";" starts a comment, "!" starts a directive
    isparamater = m.captures[3]!=nothing  # true for parameter card
    parametername = m.captures[4]
    parametervalue = m.captures[5]
    parameterunit = m.captures[6]
    ismeasure = m.captures[7]!=nothing   # true for measurement card
    measurementname = m.captures[8] # name in .log
    isstep = m.captures[9]!=nothing
    oct_or_param_or_nothing = m.captures[10]
    steppedname = m.captures[11] # name in .log
    issteppedmodel = m.captures[12]!=nothing
    modeltype = m.captures[13] # for example NPN
    modelname = m.captures[14] # name in .log

    # determine if we are processign a comment or directive
    if commentordirective == "!"
      directive = true
    elseif commentordirective == ";"
      directive = false
    end
    if directive
      if isparamater  # this is a paramater card
        if haskey(units,parameterunit) # if their is an SI unit
          multiplier = units[parameterunit] # find the multiplier
        else
          multiplier = 1.0 # if no unit, multiplier is 1.0
        end
        valuenounit = try  # try to convert the value.  might just want to let the exception happen...
          parse(Float64,parametervalue)
        catch
          convert(Float64,NaN)
        end
        old_position = position
        position = m.offsets[5]   # offset of the begining if the value in the circuit file
        circuitfilearray = vcat(circuitfilearray,ltspicefile[old_position:position-1])  # text before the value
        i += 1
        circuitfilearray = vcat(circuitfilearray,ltspicefile[position:position+length(parametervalue)-1])  # text of the value
        i += 1
        parameters[parametername] = (valuenounit * multiplier, multiplier, i)
        position = position+length(parametervalue)
      elseif ismeasure  # this is a measurement card
        key = lowercase(measurementname)  # measurements are all lower case in log file
        push!(measurementnames,key)
      elseif isstep # this is a step card
        push!(stepnames,steppedname)
      elseif issteppedmodel
        push!(stepnames,modelname)
      end
    end
    m = match(match_tags,ltspicefile,m.offset+length(m.match))   # find next match
  end
  circuitfilearray = vcat(circuitfilearray,ltspicefile[position:end])  # the rest of the circuit
  return CircuitFile(circuitpath, circuitfilearray, parameters,
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

function getparameters(x::CircuitFile)
  result = Dict{ASCIIString,Float64}()
  [result[y] = x.parameters[y][1] for y in keys(x.parameters)]
  return result
end

getmeasurementnames(x::CircuitFile) = x.measurementnames
getstepnames(x::CircuitFile) = x.stepnames
isstep(x::CircuitFile) = length(x.stepnames) != 0
hasmeasurements(x::CircuitFile) = length(x.measurementnames) != 0

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