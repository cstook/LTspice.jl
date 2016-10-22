
function test1()
  filename = "test1.asc"
  #filename = "C:/Users/Chris/.julia/v0.5/LTspice/test/test1.asc"
  sim = LTspiceSimulation(filename,executablepath="")
  show(IOBuffer(),sim)
  (circuitdir,file) = splitdir(circuitpath(sim))
  @test file == "test1.asc"
  (logdir,file) = splitdir(logpath(sim))
  @test logdir == circuitdir
  @test executablepath(sim) == ""
  @test parameternames(sim) == ("vin","load")
  @test measurementnames(sim) == ("Current",)
  @test stepnames(sim) == ()
  @test parametervalues(sim) == [5.00, 2.00]
  @test measurementvalues(sim) == [2.50]
  show(IOBuffer(),sim)
  @test stepvalues(sim) == ()
  @test sim["vin"] == 5
  @test sim["load"] == 2
  @test sim["Current"] == 2.5
  @test keys(sim) == ["load","vin","Current"]
  @test values(sim) == [2.0,5.0,2.5]
  for key in keys(sim)
    @test haskey(sim,key)
    @test sim[key] == get(sim,key,NaN)
  end
  @test_throws KeyError sim["not a valid key"]
  @test_throws KeyError sim["not a valid key"] = 1.0
  @test isnan(get(sim,"not a valid key",NaN))
  @test eltype(sim) == Float64
  @test length(sim) == 3
  sim["vin"] = 1.0
  @test sim["vin"] == 1.0
  sim["vin"] = 5.0

end
test1()
