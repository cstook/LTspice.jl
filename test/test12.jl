function test12()
  filename = "test12.asc"
  # exectuablepath = null string will not run LTspice.exe.  Test parsing only.
  sim = LTspiceSimulation(filename,executablepath="")
  @test LTspice.does_circuitfilearray_file_match(sim)
  show(IOBuffer(),sim)

  v1steps = [1.0, 1.1487, 1.31951, 1.51572, 1.7411,
            2.0, 2.2974, 2.63902, 3.03143, 3.4822,
            4.0, 4.59479, 5.27803, 6.06287, 6.9644,
            8.0, 9.18959, 10.5561, 12.1257, 13.9288,
            16, 18.3792, 20]
  bsteps = [1.0, 3.0, 5.0, 7.0, 9.0, 10.0]
  csteps = [4.0, 5.0, 6.0]

  @test stepvalues(sim) == (v1steps, bsteps, csteps)
  @test measurementnames(sim) == ()
  @test stepnames(sim) == ("V1","b","c")
  @test measurementvalues(sim) == [23.0,6.0,3.0,0.0]

  @test length(collect(perlineiterator(sim))) == length(v1steps)*length(bsteps)*length(csteps)

  pli = perlineiterator(sim,header=true)
  state = start(pli)
  (header,state) = next(pli,state)
  @test header == ("V1","b","c","a")
  show(IOBuffer(),sim)
end
test12()
