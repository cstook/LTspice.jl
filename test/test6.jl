function test6()
  filename = "test6.asc"
  exc = ""
  # exectuablepath = null string will not run LTspice.exe.  Test parsing only.
  sim = LTspiceSimulation(filename,executablepath="")
  @test LTspice.does_circuitfilearray_file_match(sim)
  show(IOBuffer(),sim)

  @test measurementnames(sim) == ()
  @test stepnames(sim) == ()
  @test logpath(sim) != ""

  @static if is_windows()
      @test circuitpath(sim) == filename
  end

  @test parametervalues(sim) == []
  @test measurementvalues(sim) == []
  @test executablepath(sim) == ""
  @test length(sim) == 0

  pli = perlineiterator(sim,header=true)
  for line in pli
    nothing
  end

  show(IOBuffer(),sim)
end
test6()
