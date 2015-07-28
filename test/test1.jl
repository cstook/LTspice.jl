filename = "test1.asc"
exc = defaultLTspiceExcutable()
test1 = LTspiceSimulation(exc,filename)

@test test1["Vin"] = 5
@test test1["load"] = 2
@test test1["Current"] = 2.5
