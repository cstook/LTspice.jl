function test4()
  filename = "test4.asc"
  # exectuablepath = null string will not run LTspice.exe.  Test parsing only.
  sim = LTspiceSimulation(filename,executablepath="")
  @test LTspice.does_circuitfilearray_file_match(sim)
  show(IOBuffer(),sim)

  asteps = [1.0,2.0]
  bsteps = [10.0,15.0,20.0,25.0]

  @test stepvalues(sim) == (asteps,bsteps)
  @test measurementnames(sim) == ("sum","sump1000")
  @test stepnames(sim) == ("a","b")

  @static if Sys.iswindows()
      @test circuitpath(sim) == filename
  end

  @test parametervalues(sim) == []
  @test measurementvalues(sim)[1,1,1] == 11.0
  @test executablepath(sim) == ""
  @test haskey(sim,"sum") == true
  @test length(sim) == 16

  for i in eachindex(asteps)
      for j in eachindex(bsteps)
          @test measurementvalues(sim)[i,j,1] == asteps[i]+bsteps[j]
          @test sim["sum"][i,j] == asteps[i]+bsteps[j]
          @test measurementvalues(sim)[i,j,2] == asteps[i]+bsteps[j]+1000
          @test sim["sump1000"][i,j] == asteps[i]+bsteps[j]+1000
      end
  end

  for line in perlineiterator(sim)
      @test (line[1]+line[2] == line[3])
      @test (line[3] + 1000 == line[4])
  end

  for line in perlineiterator(sim,resultnames=["sum"],steporder=["b","a"])
      @test (line[1]+line[2] == line[3])
  end

  show(IOBuffer(),sim)
end
test4()
