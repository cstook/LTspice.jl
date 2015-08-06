# copy test3 files to temp so we can test writing to them
cp("test3.asc","temp\\test3.asc")
cp("test3.log","temp\\test3.log")

filename = "temp\\test3.asc"
exc = defaultLTspiceExcutable()
test3 = LTspiceSimulation!(exc,filename)
LTspice.readlog!(test3)

@test_approx_eq(test3["a"],10.0)
@test_approx_eq(test3["b"],8.0)
@test_approx_eq(test3["c"],2.0)
@test_approx_eq(test3["d"],100.0)
@test_approx_eq(test3["e"],2.6e-12)
@test_approx_eq(test3["f"],1.0e7)
@test_approx_eq(test3["g"],1.0e-9)
@test_approx_eq(test3["h"],1.0e-15)
@test_approx_eq(test3["i"],0.005)
@test_approx_eq(test3["j"],1.276e6)
@test_approx_eq(test3["k"],-3.45e6)
@test_approx_eq(test3["l"],454.5)

@test_approx_eq(test3["x"],1.00394)
@test_approx_eq(test3["z"],0.019685)
@test_approx_eq(test3["y"],0.984252)

p = LTspice.getParameters(test3)
for (key,value) in p
  test3[key] = 1.0
end

test3b = LTspiceSimulation(exc,filename)
p = LTspice.getParameters(test3b)
for (key,value) in p
  @test_approx_eq(test3b[key],1.0)
end
