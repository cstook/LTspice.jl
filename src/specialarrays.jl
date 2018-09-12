
abstract type SpecialArray{T,n} <: AbstractArray{T,n} end

Base.size(a::SpecialArray) = size(a.values)
Base.IndexStyle(::Type{<:SpecialArray}) = IndexLinear()
#Base.linearindexing{T<:SpecialArray}(::Type{T}) = Base.LinearFast()
Base.getindex(a::SpecialArray, i::Int) = a.values[i]
Base.convert(::Type{Array{T,n}}, x::SpecialArray) where {T,n} = x.values
Base.promote_rule(::Type{AbstractArray{T,n}},::SpecialArray{T,n}) where {T,n} =
  Type{Array{T,n}}

"""
    ParameterValuesArray{T,n}

Same as Array, but tracks if user has modified values.
"""
mutable struct ParameterValuesArray{T,n} <: SpecialArray{T,n}
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
Base.convert(::Type{ParameterValuesArray{T,n}}, x::AbstractArray{S,n}) where {T,n,S} =
  ParameterValuesArray{T,n}(Array{T,n}(x),true)
Base.convert(::Type{LTspice.ParameterValuesArray{T,n}}, x::LTspice.ParameterValuesArray{T,n}) where {T,n} =
  ParameterValuesArray{T,n}(Array{T,n}(x),true)
"""
    MeasurementValuesArray{T,n}

Same as Array, but setindex! returns error.
"""
# User cannot modify, only
# updated by running simulation
mutable struct MeasurementValuesArray{T,n} <: SpecialArray{T,n}
  values :: Array{T,n}
end
function Base.setindex!(a::MeasurementValuesArray, ::Any, ::Any)
  throw(ErrorException("Measurments may not be set.  Run simulation to update."))
end
