function test1()
  filename = "test1.asc"
  # exectuablepath = null string will not run LTspice.exe.  Test parsing only.
  sim = LTspiceSimulation(filename,executablepath="")
  show(IOBuffer(),sim)
  @static if is_windows()
    (circuitdir,_filename) = splitdir(circuitpath(sim))
    @test _filename == filename
    (logdir,logfilename) = splitdir(logpath(sim))
    @test logdir == circuitdir
    @test executablepath(sim) == ""
  end
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
  simintempdir = LTspiceSimulation(filename,tempdir=true)
  simintempdir["vin"] = 1.0
  @test simintempdir["vin"] == 1.0
  simintempdir["vin"] = 5.0
  @test circuitpath(sim)!=circuitpath(simintempdir)
end
test1()
