function test15()
  filename = "test15.asc"
  # exectuablepath = null string will not run LTspice.exe.  Test parsing only.
  sim = LTspiceSimulation(filename,executablepath="")
  show(IOBuffer(),sim)
  @test measurementnames(sim) == ("σ", "a", "ψπππππ")
  @test parameternames(sim) == ("m", "μ", "MEG", "Ω", "θ", "Δ", "Φ", "ψ")
end
test15()
