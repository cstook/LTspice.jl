# tests to be run on a computer where LTspice is installed.
using LTspice
using Base.Test

filename = "test1.asc"
test1 = LTspiceSimulation(filename)
println(getltspiceexecutablepath(test1))
println(getcircuitpath(test1))
v = 20.0
r = 2.0
i = test1(v,r)[1]
@test i == 10.0
