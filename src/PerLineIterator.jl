function eachstep{Nstep}(x::StepValues{Nstep}, order=ntuple(i->i,Nstep))
  length(order) != Nstep && throw(ArgumentError())
  if order==(1,2,3)
    return ((i,j,k) for i=1:length(x.values[1]),
                        j=2:length(x.values[2]),
                        k=3:length(x.values[3]))
  elseif order==(1,3,2)
    return ((i,j,k) for i=1:length(x.values[1]),
                        k=3:length(x.values[3]),
                        j=2:length(x.values[2]))
  elseif order==(2,1,3)
    return ((i,j,k) for j=2:length(x.values[2]),
                        i=1:length(x.values[1]),
                        k=3:length(x.values[3]))
  elseif order==(2,3,1)
    return ((i,j,k) for j=2:length(x.values[2]),
                        k=3:length(x.values[3]),
                        i=1:length(x.values[1]))
  elseif order==(3,1,2)
    return ((i,j,k) for k=3:length(x.values[3]),
                        i=1:length(x.values[1]),
                        j=2:length(x.values[2]))
  elseif order==(3,2,1)
    return ((i,j,k) for k=3:length(x.values[3]),
                        j=2:length(x.values[2]),
                        i=1:length(x.values[1]))
  elseif order==(1,2)
    return ((i,j) for   i=1:length(x.values[1]),
                        j=2:length(x.values[2]))
  elseif order==(2,1)
    return ((i,j) for   j=2:length(x.values[2]),
                        i=1:length(x.values[1]))
  elseif order==(1)
    return ((i) for     i=1:length(x.values[1]))
  else
    throw(ArgumentError())
  end
end

function eachstep{Nparam,Nmeas,Nmdim,Nstep}(x::LTspiceSimulation{Nparam,Nmeas,Nmdim,Nstep},
                         order=ntuple(i->i,Nstep))
  eachstep(x.stepvalues,order)
end
function eachstep{Nparam,Nmeas,Nmdim,Nstep}(x::LTspiceSimulation{Nparam,Nmeas,Nmdim,Nstep},
                         order::NTuple{Nstep,AbstractString})
  eachstep(x,ntuple(i->findfirst(x.stepnames,order[i]),Nstep))
end

immutable ResultNamesIndices
  isparameter :: Array{Bool,1}
  parametervalue :: Array{Float64,1}
  measurementindex :: Array{Int,1}
end
ResultNamesIndices(n::Int) = ResultNamesIndices(Array(Bool,n),Array(Float64,n),Array(Int,n))

function perlineiterator{Nparam,Nmeas,Nmdim,Nstep}(
                         x :: LTspiceSimulation{Nparam,Nmeas,Nmdim,Nstep};
                         steporder = ntuple(i->i,Nstep),
                         resultnames = (x.parameternames...,
                                        x.measurementnames...))
  length(steporder) != Nstep && throw(ArgumentError())
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
      throw(ArgumentError("result name not found"))
    end
  end
  n = Nstep + resultnameslength
  return (ntuple(j->pliresultvalue(x,rni,i,j),n) for i in eachstep(x,steporder))
end
function pliresultvalue{Nparam,Nmeas,Nmdim,Nstep}(
                        x::LTspiceSimulation{Nparam,Nmeas,Nmdim,Nstep},
                        rni,i,j)
  if j<=Nstep
    return x.stepvalues.values[j][i[j]]
  elseif rni.isparameter[j-Nstep]
    return rni.parametervalue[j-Nstep]
  else
    return x.measurementvalues[i...,rni.measurementindex[j-Nstep]]
  end
end
