export perlineiterator

function eachstep(x::StepValues{Nstep}, order=ntuple(i->i,Nstep)) where Nstep
  length(order) != Nstep && throw(ArgumentError())
  if order==(1,2,3)
    return ((i,j,k) for i=1:length(x.values[1]),
                        j=1:length(x.values[2]),
                        k=1:length(x.values[3]))
  elseif order==(1,3,2)
    return ((i,j,k) for i=1:length(x.values[1]),
                        k=1:length(x.values[3]),
                        j=1:length(x.values[2]))
  elseif order==(2,1,3)
    return ((i,j,k) for j=1:length(x.values[2]),
                        i=1:length(x.values[1]),
                        k=1:length(x.values[3]))
  elseif order==(2,3,1)
    return ((i,j,k) for j=1:length(x.values[2]),
                        k=1:length(x.values[3]),
                        i=1:length(x.values[1]))
  elseif order==(3,1,2)
    return ((i,j,k) for k=1:length(x.values[3]),
                        i=1:length(x.values[1]),
                        j=1:length(x.values[2]))
  elseif order==(3,2,1)
    return ((i,j,k) for k=1:length(x.values[3]),
                        j=1:length(x.values[2]),
                        i=1:length(x.values[1]))
  elseif order==(1,2)
    return ((i,j) for   i=1:length(x.values[1]),
                        j=1:length(x.values[2]))
  elseif order==(2,1)
    return ((i,j) for   j=1:length(x.values[2]),
                        i=1:length(x.values[1]))
  elseif order==(1,)
    return ((i) for     i=1:length(x.values[1]))
  else
    throw(ArgumentError())
  end
end

function eachstep(x::LTspiceSimulation{Nparam,Nmeas,Nmdim,Nstep},
                         order=ntuple(i->i,Nstep)) where {Nparam,Nmeas,Nmdim,Nstep}
  eachstep(x.stepvalues,order)
end
function eachstep(x::LTspiceSimulation{Nparam,Nmeas,Nmdim,Nstep},
                         order::NTuple{Nstep,AbstractString}) where {Nparam,Nmeas,Nmdim,Nstep}
  eachstep(x,ntuple(i->findfirst(x.stepnames,order[i]),Nstep))
end

struct ResultNamesIndices
  isparameter :: Array{Bool,1}
  parametervalue :: Array{Float64,1}
  measurementindex :: Array{Int,1}
end
ResultNamesIndices(n::Int) = ResultNamesIndices(Array{Bool}(undef, n),Array{Float64}(undef, n),Array{Int}(undef, n))

"""
```julia
perlineiterator(simulation, <keyword arguments>)
```
Retruns iterator that flattens multidimensional data.

**Keyword Arguments**

- `steporder`     -- specify order of steps
- `resultnames`   -- specify parameters and measurements for output
- `header`        -- `true` to make first line header

The step order defaults to the order the step values appear in the circuit file.
Step order can be specified by passing an array of step names.  By default
there is one column for each step, measurement, and parameter.  The desired
measurements and parameters can be set by passing an array of names to
resultnames.

```julia
# write CSV with headers
using DelimitedFiles
writedlm("test.csv",perlineiterator(circuit2,header=true),',')
```
"""
function perlineiterator(x :: LTspiceSimulation{Nparam,Nmeas,Nmdim,Nstep};
                         steporder = ntuple(i->i,Nstep),
                         resultnames = (x.parameternames...,
                                        x.measurementnames...,),
                         header::Bool = false) where {Nparam,Nmeas,Nmdim,Nstep}
  _perlineiterator(x,steporder,resultnames,header)
end
perlineiterator(::NonSteppedSimulation;
                steporder=nothing,
                resultnames=nothing,
                header=nothing) = ()
function _perlineiterator(x :: LTspiceSimulation{Nparam,Nmeas,Nmdim,Nstep},
                         steporder,
                         resultnames,
                         header::Bool) where {Nparam,Nmeas,Nmdim,Nstep}
  if header
    return Iterators.flatten(([headerline(x,steporder,resultnames)],
          _perlineiterator(x,steporder,resultnames)))
  else
    return _perlineiterator(x,steporder,resultnames)
  end
end
function _perlineiterator(x :: LTspiceSimulation{Nparam,Nmeas,Nmdim,Nstep},
                         steporder,
                         resultnames) where {Nparam,Nmeas,Nmdim,Nstep}
  length(steporder)!=Nstep && throw(ArgumentError("must include all steps"))
  _perlineiterator(x,
                  ntuple(i->something(findfirst(isequal(steporder[i]), x.stepnames), 0),Nstep),
                  resultnames)
end

function _perlineiterator(x :: LTspiceSimulation{Nparam,Nmeas,Nmdim,Nstep},
                         steporder::NTuple{Nstep,Int},
                         resultnames) where {Nparam,Nmeas,Nmdim,Nstep}
  allunique(steporder) || throw(ArgumentError("steps must be unique"))
  run!(x)
  resultnameslength = length(resultnames)
  rni = ResultNamesIndices(resultnameslength)
  for i in eachindex(resultnames)
    if haskey(x.parameterdict,resultnames[i])
      rni.isparameter[i] = true
      rni.parametervalue[i] = x[resultnames[i]]
    elseif haskey(x.measurementdict,resultnames[i])
      rni.isparameter[i] = false
      rni.measurementindex[i] = x.measurementdict[resultnames[i]]
    else
      throw(ArgumentError("result name \"$(resultnames[i])\" not found"))
    end
  end
  n = Nstep + resultnameslength
  return (ntuple(j->pliresultvalue(x,rni,i,j,steporder),n) for i in eachstep(x,steporder))
end
function pliresultvalue(x::LTspiceSimulation{Nparam,Nmeas,Nmdim,Nstep},
                        rni,i,j,steporder) where {Nparam,Nmeas,Nmdim,Nstep}
  if j<=Nstep
    return x.stepvalues.values[steporder[j]][i[steporder[j]]]
  elseif rni.isparameter[j-Nstep]
    return rni.parametervalue[j-Nstep]
  else
    return x.measurementvalues[i...,rni.measurementindex[j-Nstep]]
  end
end

function headerline(x,steporder::NTuple{N,Int},resultnames) where N
  (ntuple(i->x.stepnames[steporder[i]],N)...,resultnames...)
end
function headerline(x,steporder,resultnames)
  (steporder...,resultnames...)
end
