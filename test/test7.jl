using LTspice
using Base.Test

test7file = "test7.asc"
exc = ""
test7 = LTspiceSimulation(test7file,exc)
show(test7)
show(LTspice.circuitparsed(test7))
show(LTspice.logparsed(test7))

@test test7["a"] == 10e-12
@test ~haskey(test7,"b")
@test ~haskey(test7,"c")
@test ~haskey(test7,"d")
@test ~haskey(test7,"A")
@test ~haskey(test7,"B")
@test ~haskey(test7,"C")
@test ~haskey(test7,"D")


@test test7["ee"] == 1e3
@test test7["ff"] == 1e3 
@test test7["gg"] == 1e6
@test test7["h"] == 1.123e6
@test test7["i"] == 1e9
@test test7["j"] == 1e9 
@test test7["k"] == 1e12 
@test test7["l"] == 1e12 
@test test7["m"] == 1e-3 
@test test7["n"] == 1e-3 
@test test7["o"] == 1e-6 
@test test7["p"] == 1e-6
@test test7["q"] == 1e-9 
@test test7["r"] == 1e-9 
@test test7["s"] == 1e-12 
@test test7["t"] == 1e-12
@test test7["u"] == 1e-15 
@test test7["v"] == 1e-15