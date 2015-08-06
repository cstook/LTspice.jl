filename = "test2.asc"
exc = defaultLTspiceExcutable()
test2 = LTspiceSimulation!(exc,filename)
LTspice.readlog!(test2)

@test_approx_eq(test2["c"],2.0)
@test_approx_eq(test2["b"],8.0)
@test_approx_eq(test2["a"],10.0)
@test_approx_eq(test2["d"],100.0)
@test_approx_eq(test2["x"],1.00394)
@test_approx_eq(test2["z"],0.019685)
@test_approx_eq(test2["y"],0.984252)

@test(length(test2.meas)==3)
@test(length(test2.param)==4)

@test(length(keys(test2))==7)
@test(length(values(test2))==7)
@test(length(test2)==7)
