using LTspice
using Base.Test

test6file = "test6.asc"
exc = ""
test6 = LTspiceSimulation!(test6file,exc)
show(test6)
show(test6.circuit)
show(test6.log)

@test getmeasurementnames(test6) == []
@test getmeasurementnames(test6.log) == getmeasurementnames(test6)
@test getstepnames(test6) == []
@test getlogpath(test6) != ""
@test getcircuitpath(test6) == test6file
@test typeof(getcircuitpath(test6.log)) == Type(ASCIIString)
@test typeof(getparameters(test6)) == Array{Float64,1}
#@test getmeasurements(test6)[1,1,1,1] == 1.0
@test getltspiceexecutablepath(test6) == ""
@test haskey(test6,"sum") == false  # measurments in stepped files are not a Dict
@test length(test6.log) == 0


pli = PerLineIterator(test6)
show(pli)
@test length(pli) == 0
@test getheader(pli) == []


show(test6)
show(test6.circuit)
show(test6.log)

