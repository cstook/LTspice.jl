function test5()
  filename = "test5.asc"
  # exectuablepath = null string will not run LTspice.exe.  Test parsing only.
  sim = LTspiceSimulation(filename,executablepath="")
  @test LTspice.does_circuitfilearray_file_match(sim)
  show(IOBuffer(),sim)

  asteps = [1.0,2.0]

  @test stepvalues(sim) == (asteps,)
  @test measurementnames(sim) == ("sum","sump1000")
  @test stepnames(sim) == ("a",)
  @test logpath(sim) != ""

  @static if is_windows()
      @test circuitpath(sim) == filename
  end

  @test parametervalues(sim) == []
  @test measurementvalues(sim)[1,1] == 1.0
  @test executablepath(sim) == ""
  @test haskey(sim,"sum") == true
  @test length(sim) == 4

  for i in eachindex(asteps)
      @test measurementvalues(sim)[i,1] == asteps[i]
      @test sim["sum"][i] == asteps[i]
      @test measurementvalues(sim)[i,2] == asteps[i] + 1000
      @test sim["sump1000"][i] == asteps[i] + 1000
  end

  for line in perlineiterator(sim)
      @test (line[1] == line[2])
      @test (line[2] + 1000 == line[3])
  end

  show(IOBuffer(),sim)
end
test5()
