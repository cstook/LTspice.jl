# overloard parse for the CircuitFile type
# used to parse LTspice circuit files *.asc

import Base: parse, show, getindex, setindex!,start, next, done, length, eltype, haskey

#export CircuitFile, getcircuitpath, getmeasurmentnames, getsweeps
#export isneedsupdate

type CircuitFile
	circuitpath			:: ASCIIString
	circuitfilearray:: Array{ASCIIString,1}    # text of circuit file
	parameters 			:: Dict{ASCIIString,Tuple{Float64,Float64,Int}} # dictionay of parameters (value, multiplier, index)
  measurementnames:: Array{ASCIIString,1}              # measurment names
  sweeps				  :: Array{Tuple{ASCIIString,Int},1}   # number of points in each sweep
  needsupdate			:: Bool # true if any parameter has been changed
end

getcircuitpath(x::CircuitFile) = x.circuitpath
getmeasurmentnames(x::CircuitFile) = x.measurementnames
getsweeps(x::CircuitFile) = x.sweeps
isneedsupdate(x::CircuitFile) = x.needsupdate

function show(io::IO, x::CircuitFile)
	println(io,x.circuitpath)
  	println(io,"")
  	println(io,"Parameters")
  	for (key,(value,m,i)) in x.parameters
    	println(io,"$(rpad(key,25,' ')) = $value")
  	end
 	if length(x.measurementnames)>0 
 		println(io,"")
 		println(io,"Measurments")
 	end
 	for m in x.measurementnames
 		println(io,m)
 	end
 	if length(x.sweeps)>0
 		println(io,"")
 		println(io,"Sweeps")
 	end
 	println(io,"")
 	for (s,p) in x.sweeps
 		println(io,"$(rpad(s,25,' '))  $p steps")
 	end
end
 	
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


function parse(::Type{CircuitFile}, circuitpath::ASCIIString)
  # reads circuit file and returns a tuple of
  # Dict of parameters
  # Dict of measurements, values N/A
  # circuit file array
  #     The circuit file array is an array of strings which when concatenated produce the circuit file
  #     The elements of the array split the file around parameter values to avoid parsing the file
  #     every time a parameter is modified

  ltspicefile = readall(circuitpath)            # read the circuit file

  # create empty dictionarys to be filled as file is parsed
  parameters = Dict{ASCIIString,Tuple{Float64,Float64,Int}}()     # Dict of parameters.  key = parameter, value = (parameter value, multiplier, circuit file array index)
  measurementnames = Array(ASCIIString,0)
  sweeps	= Array(Tuple{ASCIIString,Int},0)
  circuitfilearray = Array(ASCIIString,1)
  circuitfilearray[1] = ""
  # regex used to parse file.  I know this is a bad comment.
  match_tags = r"""(
                ^TEXT .*?(!|;)|
                [.](param)[ ]+([A-Za-z0-9]*)[= ]*([0-9.eE+-]*)([a-z]*)|
                [.](measure|meas)[ ]+(?:ac|dc|op|tran|tf|noise)[ ]+(\w)[ ]+|
                [.](step)[ ]+(oct |param ){0,1}[ ]*(\w)[ ]+(list ){0,1}[ ]*(([0-9.e+-]*([a-z])[ ]*)*)
                )"""imx

  # parse the file
  directive = false   # true for directives, false for comments
  m = match(match_tags,ltspicefile)
  i = 1  # index for circuit file array
  position = 1   # pointer into ltspicefile
  old_position = 1
  while m!=nothing
    commentordirective = m.captures[2]    # ";" starts a comment, "!" starts a directive
    isparamater = m.captures[3]!=nothing  # true for parameter card
    parametername = m.captures[4]
    parametervalue = m.captures[5]
    parameterunit = m.captures[6]
    ismeasure = m.captures[7]!=nothing   # true for measurement card
    measurementname = m.captures[8]
    isstep = m.captures[9]!=nothing
    oct_or_param_or_nothing = m.captures[10]
    steppedname = m.captures[11]
    islist = m.captures[12]!=nothing
    stepparameterlist = m.captures[13] # all the values and units.  Needs additional parsing.

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
      end
      if ismeasure  # this is a measurement card
        key = lowercase(measurementname)  # measurements are all lower case in log file
        push!(measurementnames,key)
      end
      if isstep # this is a step card
        error(".step directive not supported")
      end
    end
    m = match(match_tags,ltspicefile,m.offset+length(m.match))   # find next match
  end
  circuitfilearray = vcat(circuitfilearray,ltspicefile[position:end])  # the rest of the circuit
  return CircuitFile(circuitpath, circuitfilearray, parameters, measurementnames, sweeps, false)
end

# CircuitFile iterates over its parameters
start(x::CircuitFile) = start(x.parameters)
next(x::CircuitFile, state) = next(x.parameters, state)
done(x::CircuitFile, state) = done(x.parameters, state)
length(x::CircuitFile) = length(x.parameters)
eltype(x::CircuitFile) = lenght(x.parameters)

# CircuitFile is a dict of its parameters
haskey(x::CircuitFile) = haskey(x.parameters)

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

"writes circuit file back to disk if any parameters have changed"
function update(x::CircuitFile)
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