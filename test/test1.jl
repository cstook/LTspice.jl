filename = "test1.asc"
exc = defaultLTspiceExcutable()
test1 = LTspiceSimulation(exc,filename)
LTspice.readlog!(test1)

@test test1["Vin"] == 5
@test test1["load"] == 2
@test test1["current"] == 2.5
