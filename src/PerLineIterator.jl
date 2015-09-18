# PerLineIterator(LTspiceSimulation!) --> iterable collection of 1d arrays
#
# used to pass to writedlm to create a delimited file

export getheaders, header

immutable PerLineIterator
  simulation        :: LTspiceSimulation!
  header            :: Array{ASCIIString,1}
  stepindexes       :: Array{Int,1}
  resultindexes     :: Array{Tuple{Bool,Int},1} # is parameter and index into array
  mli               :: MultiLevelIterator

  function PerLineIterator(simulation :: LTspiceSimulation!;
                           steporder = getstepnames(simulation),
                           resultnames = vcat(getparameternames(simulation),
                                              getmeasurementnames(simulation)))
    for step in steporder
      if findfirst(getstepnames(simulation),step) == 0 
        error("$step step not found")
      end
    end
    if length(steporder) != length(getstepnames(simulation))
      error("length(steporder) must equal number of steped items in simulation")
    end
    args = Array(Int,0)
    stepindexes = Array(Int,0)
    for step in steporder
      index = findfirst(getstepnames(simulation),step)
      push!(args,length(getsteps(simulation)[index]))
      push!(stepindexes,index)
    end
    resultindexes = Array(Tuple{Bool,Int},0) 
    for resultname in resultnames
      i = findfirst(getparameternames(simulation),resultname)
      if i > 0
        push!(resultindexes,(true,i))
      else
        i = findfirst(getmeasurementnames(simulation),resultname)
        if i > 0
          push!(resultindexes,(false,i))
        else 
          error("$resultname not found in parameters or measurements")
        end 
      end
    end
    header = vcat(steporder,resultnames)
    new(simulation, header, stepindexes, resultindexes, MultiLevelIterator(args))
  end
end

"""
PerLineIterator(*LTspiceSimulation!*[,steporder=*steporder*]
                [,resultnames=*resultnames*])

Creates an iterator in the format required to pass to writecsv or writedlm.
The step order defaults to the order the steps appear in the circuit file.
Step order can be specified by passing an array of step names.  By default 
there is one column for each step, measurement, and parameter.  The desired
measurements and parameters can be set by passing an array of names to
resultnames.

```julia
# write CSV with headers
io = open("test.csv",false,true,true,false,false)
pli = PerLineIterator(simulation)
writecsv(io,header(pli))
writecsv(io,pli)
close(io)
```
"""
PerLineIterator

function show(io ::IO, x :: PerLineIterator)
  numberoflines = length(x.mli)
  println(io,"$(numberoflines)-line PerLineIterator")
end

start(x :: PerLineIterator) = start(x.mli)

function next(x :: PerLineIterator, state :: Array{Int,1})
  # flip MultiLevelIterator indexes around to be order required 
  # by the measurements array
  (q,nextstate) = next(x.mli,state)
  k = [1,1,1]
  for (i,si) in enumerate(x.stepindexes)
    k[si] = q[i] 
  end
  # gather the data into a line of output
  line = Array(Float64, length(x.stepindexes)+length(x.resultindexes))
  i = 1
  for si in x.stepindexes
    line[i] = getsteps(x.simulation)[si][k[si]]
    i +=1
  end
  for (isparameter,j) in x.resultindexes
    if isparameter
      line[i] = getparameters(x.simulation)[j]
    else 
      line[i] = getmeasurements(x.simulation)[j,k...]
    end
    i +=1
  end
  return (line,nextstate)
end

done(x :: PerLineIterator, state) = done(x.mli, state)
length(x :: PerLineIterator) = length(x.mli)

"""
getheaders(*PerLineIterator*)

Returns an array of strings of parameter and measurement names.
"""
getheaders(x :: PerLineIterator) = x.header
"""
header(*PerLineIterator*)

Returns the header for PerLineIterator in the format needed for writecsv or 
writedlm.  this is equivalent to 
```julia
transpose(getheaders(PerLineIterator))
```
"""
header(x::PerLineIterator) = transpose(x.header) 

