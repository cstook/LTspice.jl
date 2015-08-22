
type LogDataArray <: AbstractArray{Float64,4}
    data :: Array{Float64,4}
    needsupdate :: Bool
end
Base.size(x::LogDataArray) = (size(x.data))
Base.linearindexing(::Type{LogDataArray}) = Base.LinearFast()
function Base.getindex(x::LogDataArray, i::Int)
    if needsupdate
      
    end
    return x.data[i]
end
Base.convert(Array{Float64,4}, x::LogDataArray) = x.data
Base.promote_rule(::LogDataArray, ::Array{Float64,4}) = Array{Float64,4}


