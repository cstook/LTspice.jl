using LTspice
using Base.Test

# make work with atom on my pc
if isdir("C:/Users/Chris/.julia/v0.5/LTspice/test")
  cd("C:/Users/Chris/.julia/v0.5/LTspice/test")
end

include("test1.jl")
include("test2.jl")
include("test3.jl")
include("test4.jl")
#include("testParseCircuitFile1.jl")
#include("testParseCircuitFile2.jl")
#include("testParseCircuitFile3.jl")

#include("test5.jl")
#include("test6.jl")
#include("test7.jl")
#include("test8.jl")
#include("test9.jl")
#include("test10.jl")
