using Base.Test 
using LTspice 

levels = []
l = 1
for i in 1:10
  push!(levels,i)
  mli = LTspice.MultiLevelIterator(levels)
  l *= i
  @test length(mli) == l
  l2 = 0
  for k in mli 
    l2 +=1
  end
  @test l2 == l
  @test eltype(mli) == Type(Int)
end

