using LTspice
using Base.Test

function compare_arrays(x,y)
  @test length(x) == length(y)
  for i in eachindex(x)
    if !isnan(x[i])
      @test x[i]≈y[i]
    end
  end
  return nothing
end


@testset "tests not calling LTspice.exe" begin
  include("test1.jl")
  include("test2.jl")
  include("test3.jl")
  include("test4.jl")
  include("test5.jl")
  include("test6.jl")
  include("test7.jl")
  include("test8.jl")
  include("test9.jl")
  include("test10.jl")
  include("test11.jl")
  include("test12.jl")
  include("test13.jl")
  include("test14.jl")
  include("test15.jl")
  include("testinc.jl")
end


is_ltspice_installed = (try LTspice.defaultltspiceexecutable() end)!=nothing

if is_ltspice_installed
  @testset "tests calling LTspice.exe" begin
    include("localtests.jl")
  end
else
  println("LTspice.exe not found.  Skipping tests.")
end
