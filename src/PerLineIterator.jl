# PerLineIterator(LTspiceSimulation!) --> iterable collection of 1d arrays
#
# used to pass to writedlm to create a delimited file

export getheader

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

getheader(x :: PerLineIterator) = x.header