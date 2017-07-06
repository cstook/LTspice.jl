function test10()
  sim = LTspiceSimulation("test10.asc",executablepath="")
  @test LTspice.does_circuitfilearray_file_match(sim)
  show(IOBuffer(),sim)
  @test sim["m1"] == 0.0
  @test isnan(sim["bad_meas"])
  show(IOBuffer(),sim)
end
test10()
