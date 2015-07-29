filename = "test3.asc"
exc = defaultLTspiceExcutable()
test3 = LTspiceSimulation(exc,filename)
LTspice.readlog!(test3)