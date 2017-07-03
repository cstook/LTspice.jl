using LTspice
using StringEncodings

open("test/test1.asc",enc"UTF-8") do io
  for line in eachline(io, chomp=false)
    print("line2: ",line)
  end
end


enc"UTF-8"

cd("C:/Users/Chris/.julia/v0.5/LTspice/test")
sim1 = LTspiceSimulation("test1.asc",tempdir=true)
show(sim1)
run!(sim1)
sim1["Current"]
sim1["vin"] = 3.0
sim1

cd("C:/Users/Chris/Documents/LTspiceXVII/myfiles")
sim = LTspiceSimulation("Draft2.asc",tempdir=true)
print(sim)
m1 = sim["m1"]
sim["d"] = 10.0
flush(sim,true)
for a in 1:10
  sim["a"] = Float64(a)
  print(sim["m1"]," ")
end
