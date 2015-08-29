# copy test3 files to temp so we can test writing to them
cp("test3.asc","temp\\test3.asc",remove_destination = true)
cp("test3.log","temp\\test3.log",remove_destination = true)

filename = "temp\\test3.asc"
exc = ""  # null string will not run LTspice.exe.  Test parsing only.
test3 = LTspiceSimulation!(filename, exc)

parameternamesverify = ["a","b","c","d","e","f","g","h","i","j","k","l"]
for (verify,parameter,value) in zip(parameternamesverify,getparameternames(test3),getparameters(test3))
  @test parameter == verify
  @test value == test3[parameter]
end

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

for (key,value) in test3.circuit
  test3[key] = 1.0
end

dummyread = test3["x"]  # will force parameters to write to file
                        # sim will not run since exc = ""

test3b = LTspiceSimulation(filename, exc)
for (key,value) in test3b.circuit
  @test_approx_eq(test3b[key],1.0)
end


