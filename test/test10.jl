function test10()
  sim = LTspiceSimulation("test10.asc",executablepath="")
  show(IOBuffer(),sim)
  @test sim["m1"] == 0.0
  @test isnan(sim["bad_meas"])
  show(IOBuffer(),sim)
end
test10()
