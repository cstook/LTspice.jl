filename = "test1.asc"
exc = ""  # null string will not run LTspice.exe.  Test parsing only.
test1 = LTspiceSimulation!(filename,exc)

@test test1["Vin"] == 5
@test test1["load"] == 2
@test test1["current"] == 2.5

#@test getsteps(test1) == (Float64[],Float64[],Float64[])
@test getmeasurementnames(test1) == ["current"]
#@test getstepnames(test1) == []
@test getlogpath(test1) != ""
@test getcircuitpath(test1) != ""
@test typeof(getparameters(test1)) == Dict{ASCIIString,Float64}
@test getmeasurements(test1)[1,1,1,1] == 2.5