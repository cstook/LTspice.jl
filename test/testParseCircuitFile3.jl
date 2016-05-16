using LTspice
using Base.Test

PCF_test3file = "PCF_test3.asc"
exc = ""
PCF_test3 = LTspiceSimulation(PCF_test3file,exc)

npnlist = [50.0, 75.0, 100.0]
v2list = [10.0, 15.0, 20.0, 25.0, 30.0]
v1list = [1.0, 2.0]
stepnames = ["2n2222(vaf)","v2","v1"]

measurementnames = ["aaaaaa", "b43"]


@test steps(PCF_test3) == (npnlist,v2list,v1list)
@test measurementnames(PCF_test3) == measurementnames
@test stepnames(PCF_test3) == stepnames
@test stepnames(PCF_test3.log) == stepnames
@test length(measurements(PCF_test3)) == length(measurementnames)*length(npnlist)*length(v2list)*length(v1list)
