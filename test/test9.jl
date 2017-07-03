function test9()
  sim = LTspiceSimulation("test9.asc",executablepath="")
  show(IOBuffer(),sim)
  compare_arrays(measurementvalues(sim),[-0.5 -1.0 1.0; 0.0 NaN NaN; 0.5 1.0 -1.0])
#  @test measurementvalues(sim)≈[-0.5 -1.0 1.0; 0.0 NaN NaN; 0.5 1.0 -1.0]
  show(IOBuffer(),sim)
end
test9()
