# iterates over steps, return tuple of indices

immutable EachStep{Nstep}
  max :: NTuple{Nstep,Int}
  order :: NTuple{Nstep,Int}
end

EachStep{Nstep}(x::StepValues{Nstep}, order=ntuple(i->i,Nstep)) =
  EachStep{Nstep}(ntuple(i->length(x.values[i]),Nstep),order)

Base.start{Nstep}(x::EachStep{Nstep}) = ntuple(d->1,Nstep)
function Base.next{Nstep}(x::EachStep{Nstep}, state)
  
  return (item, nextstate)
end
Base.done{Nstep}(x::EachStep{0}, state) = true
Base.done{Nstep}(x::EachStep{1}, state) = state[1]==max[1]
Base.done{Nstep}(x::EachStep{2}, state) = state[1]==max[1] &&
                                          state[2]==max[2]
Base.done{Nstep}(x::EachStep{3}, state) = state[1]==max[1] &&
                                          state[2]==max[2] &&
                                          state[3]==max[3]
