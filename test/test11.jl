function test11()
  filename = "test11.asc"
  # exectuablepath = null string will not run LTspice.exe.  Test parsing only.
  sim = LTspiceSimulation(filename,executablepath="")
  show(IOBuffer(),sim)

  asteps = [1.0,2.0]
  bsteps = [10.0,15.0,20.0,25.0]
  csteps = [100.0,200.0,300.0]

  @test stepvalues(sim) == (asteps,bsteps,csteps)
  @test measurementnames(sim) == ("sum","sump1000")
  @test stepnames(sim) == ("a","b","c")
  @test logpath(sim) != ""

  @static if is_windows()
      @test circuitpath(sim) == filename
  end

  @test parametervalues(sim) == []
  @test measurementvalues(sim)[1,1,1,1] == 111.0
  @test executablepath(sim) == ""
  @test haskey(sim,"sum") == true  # measurments in stepped files are not a Dict
  @test length(sim) == 48

  for i in eachindex(asteps)
      for j in eachindex(bsteps)
          for k in eachindex(csteps)
              @test measurementvalues(sim)[i,j,k,1] == asteps[i]+bsteps[j]+csteps[k]
              @test sim["sum"][i,j,k] == asteps[i]+bsteps[j]+csteps[k]
              @test measurementvalues(sim)[i,j,k,2] == asteps[i]+bsteps[j]+csteps[k]+1000
              @test sim["sump1000"][i,j,k] == asteps[i]+bsteps[j]+csteps[k]+1000
          end
      end
  end

  for line in perlineiterator(sim)
      @test (line[1]+line[2]+line[3] == line[4])
      @test (line[4] + 1000 == line[5])
  end

  for line in perlineiterator(sim,resultnames=["sum"],steporder=["b","a","c"])
      @test (line[1]+line[2]+line[3] == line[4])
  end
  show(IOBuffer(),sim)
end
test11()
