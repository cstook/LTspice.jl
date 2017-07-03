function test2()
  filename = "test2.asc"
  # exectuablepath = null string will not run LTspice.exe.  Test parsing only.
  sim = LTspiceSimulation(filename,executablepath="")
  show(IOBuffer(),sim)
  @test sim["c"]≈2.0
  @test sim["b"]≈8.0
  @test sim["a"]≈10.0
  @test sim["d"]≈100.0
  @test sim["x"]≈1.00394
  @test sim["z"]≈0.019685
  @test sim["y"]≈0.984252

  @test(length(measurementvalues(sim))==3)
  @test(length(parametervalues(sim))==4)

  @test(length(keys(sim))==7)
  @test(length(values(sim))==7)
  @test(length(sim)==7)
  show(IOBuffer(),sim)
end
test2()
