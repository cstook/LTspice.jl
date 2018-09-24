# tests to be run on a computer where LTspice is installed.
using LTspice
using Test

function localtests()

  test1 = LTspiceSimulation("test1.asc",tempdir=true)
  v = 20.0
  r = 2.0
  i = test1(v,r)[1]
  @test i == 10.0

  testinc1 = LTspiceSimulation("testInc1.asc",tempdir=true)
  @test testinc1["incA"] == 1.0
  @test testinc1["incB"] == 2.0
  @test testinc1["incC"] == 3.0
  @test testinc1["incD"] == 4.0
  @test testinc1["incE"] == 5.0
  @test testinc1["incF"] == 6.0

  test14 = LTspiceSimulation("test14.asc",tempdir=true)
  testarray = [1.0,2.0]
  for a in testarray
    for b in 10*testarray
      for d in 100*testarray
        for e in 1000*testarray
          for this_is_a_long_name in 10000*testarray
            test14["a"] = a
            test14["b"] = b
            test14["d"] = d
            test14["e"] = e
            test14["this_is_a_long_name"] = this_is_a_long_name
            @test test14["m1"] == a + b + d + e + this_is_a_long_name
          end
        end
      end
    end
  end

end
localtests()
