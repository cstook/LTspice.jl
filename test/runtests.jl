using LTspice
using Base.Test

include("test1.jl")
include("test2.jl")

@test 1 == 1
