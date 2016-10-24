function test7()
  filename = "test7.asc"
  # exectuablepath = null string will not run LTspice.exe.  Test parsing only.
  sim = LTspiceSimulation(filename,executablepath="")
  show(IOBuffer(),sim)

  @test sim["A"] == 10e-12
  @test ~haskey(sim,"b") # keys only for numbers
  @test ~haskey(sim,"C") # keys only for numbers
  @test ~haskey(sim,"d") # keys only for numbers
  @test ~haskey(sim,"a") # keys are case sensitive
  @test ~haskey(sim,"B") # both
  @test ~haskey(sim,"D") # both


  @test sim["Ee"] == 1e3
  @test sim["fF"] == 1e3
  @test sim["GG"] == 1e6
  @test sim["h"] == 1.123e6
  @test sim["i"] == 1e9
  @test sim["j"] == 1e9
  @test sim["k"] == 1e12
  @test sim["l"] == 1e12
  @test sim["m"] == 1e-3
  @test sim["n"] == 1e-3
  @test sim["o"] == 1e-6
  @test sim["p"] == 1e-6
  @test sim["q"] == 1e-9
  @test sim["r"] == 1e-9
  @test sim["s"] == 1e-12
  @test sim["t"] == 1e-12
  @test sim["u"] == 1e-15
  @test sim["v"] == 1e-15
  show(IOBuffer(),sim)
end
test7()
