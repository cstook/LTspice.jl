function test3()
  # copy test3 files to temp so we can test writing to them
  cp("test3.asc","temp\\test3.asc",remove_destination = true)
  cp("test3.log","temp\\test3.log",remove_destination = true)

  filename = "temp\\test3.asc"
  # exectuablepath = null string will not run LTspice.exe.  Test parsing only.
  sim = LTspiceSimulation(filename,executablepath="")
  show(IOBuffer(),sim)

  parameternamesverify = ["a","b","c","d","e","f","g","h","i","j","k","l"]
  for (verify,parameter,value) in zip(parameternamesverify,parameternames(sim),parametervalues(sim))
    @test parameter == verify
    @test value == sim[parameter]
  end

  # parameters
  @test sim["a"]≈10.0
  @test sim["b"]≈8.0
  @test sim["c"]≈2.0
  @test sim["d"]≈100.0
  @test sim["e"]≈2.6e-12
  @test sim["f"]≈1.0e7
  @test sim["g"]≈1.0e-9
  @test sim["h"]≈1.0e-15
  @test sim["i"]≈0.005
  @test sim["j"]≈1.276e6
  @test sim["k"]≈-3.45e6
  @test sim["l"]≈454.5

  # measurements
  @test_approx_eq(sim["x"],1.00394)
  @test_approx_eq(sim["z"],0.019685)
  @test_approx_eq(sim["y"],0.984252)

  for key in parameternames(sim)
    sim[key] = 1.0
  end
  dummyread = sim["x"]
  sim_b = LTspiceSimulation(filename, executablepath="")
  for key in parameternames(sim_b)
    @test_approx_eq(sim_b[key],1.0)
  end

  for key in parameternames(sim)
    sim[key] = 2.0
  end
  dummyread = measurementvalues(sim)
  sim_b = LTspiceSimulation(filename, executablepath="")
  for key in parameternames(sim_b)
    @test_approx_eq(sim_b[key],2.0)
  end
  show(IOBuffer(),sim_b)
end
test3()
