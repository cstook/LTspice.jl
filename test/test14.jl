function test14()
  filename = "test14.asc"
  # exectuablepath = null string will not run LTspice.exe.  Test parsing only.
  sim = LTspiceSimulation(filename,executablepath="")
  show(IOBuffer(),sim)
  @test measurementnames(sim) == ("m1",)
  @test parameternames(sim) == ("a","b","d", "e", "φ", "Ω", "this_is_a_long_name")
end
test14()
