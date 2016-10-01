
abstract SpecialArray{T,n} <: AbstractArray{T,n}

Base.size(a::SpecialArray) = size(a.values)
Base.linearindexing{T<:SpecialArray}(::Type{T}) = Base.LinearFast()
Base.getindex(a::SpecialArray, i::Int) = a.values[i]
Base.convert(::Type{Array}, x::SpecialArray) = x.values
Base.promote_rule{T,n}(::Type{AbstractArray{T,n}},::SpecialArray{T,n}) =
  Type{Array{T,n}}

"""
Same as Array, but tracks if user has modified values.
"""
type ParameterValuesArray{T,n} <: SpecialArray{T,n}
  values :: Array{T,n}
  ismodified :: Bool
end
function Base.setindex!(a::ParameterValuesArray, v, i::Int)
  if ~isfinite(v)
    throw(DomainError("$v is not valid LTspice parameter value"))
  end
  a.ismodified = true
  a.values[i] = v
end
Base.convert{T,n,S}(::Type{ParameterValuesArray{T,n}}, x::AbstractArray{S,n}) =
  ParameterValuesArray{T,n}(Array{T,n}(x),true)

"""
Same as Array, but setindex! returns error.
"""
# User cannot modify, only
# updated by running simulation
type MeasurementValuesArray{T,n} <: SpecialArray{T,n}
  values :: Array{T,n}
end
function Base.setindex!(a::MeasurementValuesArray, ::Any, ::Any)
  throw(ErrorException("Measurments may not be set.  Run simulation to update."))
end
