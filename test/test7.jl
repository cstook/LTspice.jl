function test7()
  filename = "test7.asc"
  # exectuablepath = null string will not run LTspice.exe.  Test parsing only.
  sim = LTspiceSimulation(filename,executablepath="")
  show(IOBuffer(),sim)

  @test sim["a"] == 10e-12
  @test ~haskey(sim,"b")
  @test ~haskey(sim,"c")
  @test ~haskey(sim,"d")
  @test ~haskey(sim,"A")
  @test ~haskey(sim,"B")
  @test ~haskey(sim,"C")
  @test ~haskey(sim,"D")


  @test sim["ee"] == 1e3
  @test sim["ff"] == 1e3
  @test sim["gg"] == 1e6
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
