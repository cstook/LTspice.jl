function testinc1()
  sim = LTspiceSimulation("testInc1.asc",executablepath="",tempdir=true)
  show(IOBuffer(),sim)
  @test measurementnames(sim) == ("incA","incB","incC","incD","incE","incF")
end
testinc1()
