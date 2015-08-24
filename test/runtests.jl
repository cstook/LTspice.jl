using LTspice
using Base.Test

include("test1.jl")
include("test2.jl")
include("test3.jl")
include("ParseCircuitFileTests/testParseCircuitFile1.jl")

@test 1 == 1
