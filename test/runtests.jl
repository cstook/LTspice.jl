using LTspice
using Base.Test

include("test1.jl")
include("test2.jl")
include("test3.jl")
include("testParseCircuitFile1.jl")
include("testParseCircuitFile2.jl")
include("testParseCircuitFile3.jl")
include("testMultiLevelIterator.jl")
include("test4.jl")
include("test5.jl")

@test 1 == 1
