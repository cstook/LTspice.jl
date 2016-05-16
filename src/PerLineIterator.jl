# PerLineIterator(LTspiceSimulation) --> iterable collection of 1d arrays
#
# used to pass to writedlm to create a delimited file

export getheaders, header

"Iterator used to dump result of simulations to csv"
immutable PerLineIterator
  simulation        :: LTspiceSimulation
  header            :: Array{ASCIIString,1}
  stepindexes       :: Array{Int,1}
  resultindexes     :: Array{Tuple{Bool,Int},1} # is parameter and index into array
  mli               :: MultiLevelIterator

  function PerLineIterator(simulation :: LTspiceSimulation;
                           steporder = stepnames(simulation),
                           resultnames = vcat(parameternames(simulation),
                                              measurementnames(simulation)))
    for step in steporder
      if findfirst(stepnames(simulation),step) == 0 
        error("$step step not found")
      end
    end
    if length(steporder) != length(stepnames(simulation))
      error("length(steporder) must equal number of steped items in simulation")
    end
    args = Array(Int,0)
    stepindexes = Array(Int,0)
    for step in steporder
      index = findfirst(stepnames(simulation),step)
      push!(args,length(steps(simulation)[index]))
      push!(stepindexes,index)
    end
    resultindexes = Array(Tuple{Bool,Int},0) 
    for resultname in resultnames
      i = findfirst(parameternames(simulation),resultname)
      if i > 0
        push!(resultindexes,(true,i))
      else
        i = findfirst(measurementnames(simulation),resultname)
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
```julia
PerLineIterator(sim :: LTspiceSimulation;
                steporder = stepnames(sim),
                resultnames = vcat(parameternames(sim), measurementnames(sim)))
```

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
PerLineIterator(x)

function Base.show(io ::IO, x :: PerLineIterator)
  numberoflines = length(x.mli)
  println(io,"$(numberoflines)-line PerLineIterator")
end

Base.start(x :: PerLineIterator) = start(x.mli)

function Base.next(x :: PerLineIterator, state :: Array{Int,1})
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
    line[i] = steps(x.simulation)[si][k[si]]
    i +=1
  end
  for (isparameter,j) in x.resultindexes
    if isparameter
      line[i] = parametervalues(x.simulation)[j]
    else 
      line[i] = measurements(x.simulation)[j,k...]
    end
    i +=1
  end
  return (line,nextstate)
end

Base.done(x :: PerLineIterator, state) = done(x.mli, state)
Base.length(x :: PerLineIterator) = length(x.mli)

"""
```julia
getheaders(perlineiterator)
```
Returns an array of strings of parameter and measurement names of `perlineiterator`.
"""
getheaders(x :: PerLineIterator) = x.header
"""
```julia
header(Perlineiterator)
```
Returns the header for `perlineterator` in the format needed for writecsv or 
writedlm.  this is equivalent to 
```julia
transpose(getheaders(perlineiterator))
```
"""
header(x::PerLineIterator) = transpose(x.header) 

