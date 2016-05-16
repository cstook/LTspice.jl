# tests to be run on a computer where LTspice is installed.
using LTspice
using Base.Test

filename = "test1.asc"
test1 = LTspiceSimulationTempDir(filename)
println(ltspiceexecutablepath(test1))
println(circuitpath(test1))
v = 20.0
r = 2.0
i = test1(v,r)[1]
@test i == 10.0
test2 = LTspiceSimulationTempDir("testInc1.asc")
@test test2["inca"] == 1.0
@test test2["incb"] == 2.0
@test test2["incc"] == 3.0
@test test2["incd"] == 4.0
@test test2["ince"] == 5.0
@test test2["incf"] == 6.0
