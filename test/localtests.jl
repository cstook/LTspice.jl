# tests to be run on a computer where LTspice is installed.
using LTspice
using Base.Test

function localtests()
  localdir = "C:/Users/Chris/.julia/v0.5/LTspice/test"
  test1 = LTspiceSimulation(joinpath(localdir,"test1.asc"),tempdir=true)
  v = 20.0
  r = 2.0
  i = test1(v,r)[1]
  @test i == 10.0
  testinc1 = LTspiceSimulation(joinpath(localdir,"testInc1.asc"),tempdir=true)
  @test testinc1["incA"] == 1.0
  @test testinc1["incB"] == 2.0
  @test testinc1["incC"] == 3.0
  @test testinc1["incD"] == 4.0
  @test testinc1["incE"] == 5.0
  @test testinc1["incF"] == 6.0
end
localtests()
