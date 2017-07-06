function test8()
  filename = "test8.asc"
  # exectuablepath = null string will not run LTspice.exe.  Test parsing only.
  sim = LTspiceSimulation(filename,executablepath="")
  @test LTspice.does_circuitfilearray_file_match(sim)
  show(IOBuffer(),sim)

  @test sim["a@"] == 1.0
  @test sim["b#"] == 2.0
  @test sim["c\$"] ==3.0
  @test sim["d."] == 4.0
  @test sim["e:"] == 5.0
  @test sim["x_"] == 11.0
  # @test sim["j\\\\"] == 10.0  # Giving up on support of \
  @test sim["a@m"] == 1.0
  @test sim["b#m"] == 2.0
  @test sim["c\$m"] == 3.0
  @test sim["e:m"] == 5.0
  # @test sim["j\\\\m"] == 10.0 # giving up on support of \
  @test sim["voltage"] == -4.0
  @test sim["y_x"] == 11.0

  show(IOBuffer(),sim)
end
test8()
