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
    (v,m,i) = x.parameters[k]
    x.parameters[k] = (value,m,i)
    x.circuitfilearray[i] = "$(value/m)"
    x.needsupdate = true
  end
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
#  parameters = Dict{ASCIIString,Tuple{Float64,Float64,Int}}() 
  parameternames = Array(ASCIIString,0)
  parameters = Array(Tuple{Float64,Float64,Int},0)
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
        push!(parameternames, parametername)
        push!(parameters, (valuenounit * multiplier, multiplier, i))
        position = position+length(parametervalue)
      elseif ismeasure  # this is a measurement card
        push!(measurementnames,lowercase(measurementname)) # measurements are all lower case in log file
      elseif isstep # this is a step card
        push!(stepnames,lowercase(steppedname)) # measurements are all lower case in log file
      elseif issteppedmodel
        push!(stepnames,lowercase(modelname)) # measurements are all lower case in log file
      end
    end
    m = match(match_tags,ltspicefile,m.offset+length(m.match))   # find next match
  end
  circuitfilearray = vcat(circuitfilearray,ltspicefile[position:end])  # the rest of the circuit
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