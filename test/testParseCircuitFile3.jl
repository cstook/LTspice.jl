using LTspice
using Base.Test

PCF_test3file = "PCF_test3.asc"
exc = ""
PCF_test3 = LTspiceSimulation(PCF_test3file,exc)

npnlist = [50.0, 75.0, 100.0]
v2list = [10.0, 15.0, 20.0, 25.0, 30.0]
v1list = [1.0, 2.0]
teststepnames = ["2n2222(vaf)","v2","v1"]

testmeasurementnames = ["aaaaaa", "b43"]


@test stepvalues(PCF_test3) == (npnlist,v2list,v1list)
@test measurementnames(PCF_test3) == testmeasurementnames
@test stepnames(PCF_test3) == teststepnames
@test stepnames(PCF_test3.log) == teststepnames
@test length(measurementvalues(PCF_test3)) == length(testmeasurementnames)*length(npnlist)*length(v2list)*length(v1list)
