# PerLineIterator(LTspiceSimulation!) --> iterable collection of 1d arrays
#
# used to pass to writedlm to create a delimited file

immutable PerLineIterator
  simulation :: LTspiceSimulation!
  order      :: Array{ASCIIString,1}
  header     :: Array{ASCIIString,1}
  stepindexes:: Array{Int,1}
  mli        :: MultiLevelIterator

  function PerLineIterator(simulation :: LTspiceSimualtion!;
                           order = getstepnames(simulation),
                           header = keys(simulation))
    for step in order
      if findfirst(getstepnames(simulation),step) == 0 
        error("$step step not found")
      end
    end
    for item in header
      if ~haskey(simulation,item) & findfirst(getmeasurementnames(simulation),item) == 0
        error("$item not found in parameters or measurements")
      end
    end
    args = Array(Int,0)
    stepindexs = Array(Int,0)
    for step in x.order
      index = findfirst(getstepnames(x.simulation),step)
      push!(args,length(getsteps(x.simulation)[index]))
      push!(stepindexes,index)
    end
    new(simulation, order, header,stepindexes,MultiLevelIterator(args))
  end
end

start(x :: PerLineIterator) = start(x.mli)

function next(x :: PerLineIterator, state :: Array{Int,1})
  # flip MultiLevelIterator indexes around to be order requires by the measurements array
  nextstate = next(x.mli,state)
  k = [1,1,1]
  for (i,si) in enumerate(x.stepindexes)
    k[i] = si 
  end

  # gather the data into a line of output
  line = Array(ASCIIString, length(x.header))
  for (i,item) in enumerate(header)
    if haskey(x.simulation,item)
      line[i] = x.simulation[item]
    else 
      line[i] = getmeasurments(x.simulation)[findfirst(getmeasurmentnames,item),k...]
    end
  end
  return (line,nextstate)
end

done(x :: PerLineIterator) = done(x.mli)