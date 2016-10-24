function test13()
  filename = "test13.asc"
  # exectuablepath = null string will not run LTspice.exe.  Test parsing only.
  sim = LTspiceSimulation(filename,executablepath="")
  show(IOBuffer(),sim)

  npnsteps = [50.0, 75.0, 100.0]
  v2steps = [10.0, 15.0, 20.0, 25.0, 30.0]
  v1steps = [1.0, 2.0]
  teststepnames = ("2N2222(VAF)","V2","V1")
  testmeasurementnames = ("aaaaaa", "b43")

  @test stepvalues(sim) == (npnsteps,v2steps,v1steps)
  @test measurementnames(sim) == testmeasurementnames
  @test stepnames(sim) == teststepnames
  @test length(measurementvalues(sim)) == length(testmeasurementnames)*length(npnsteps)*length(v2steps)*length(v1steps)
  show(IOBuffer(),sim)
end
test13()
