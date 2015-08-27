filename = "test2.asc"
exc = ""  # null string will not run LTspice.exe.  Test parsing only.
test2 = LTspiceSimulation!(filename, exc)

@test_approx_eq(test2["c"],2.0)
@test_approx_eq(test2["b"],8.0)
@test_approx_eq(test2["a"],10.0)
@test_approx_eq(test2["d"],100.0)
@test_approx_eq(test2["x"],1.00394)
@test_approx_eq(test2["z"],0.019685)
@test_approx_eq(test2["y"],0.984252)

@test(length(getmeasurements(test2))==3)
@test(length(getparameters(test2))==4)

@test(length(keys(test2))==7)
@test(length(values(test2))==7)
@test(length(test2)==7)

@test keys(test2.log) == getmeasurementnames(test2)
@test eltype(test2.log) == Type(Float64)