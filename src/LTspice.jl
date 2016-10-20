__precompile__()

"Main module for `LTspice.jl` - a Julia interface to LTspice"
module LTspice
using Iterators

include("specialarrays.jl")
include("LTspiceSimulation.jl")
include("mcfiap.jl")
include("ParseCircuitFile.jl")
include("ParseLogFile.jl")
include("perlineiterator.jl")
include("utility.jl")

end # module
