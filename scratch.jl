using LTspice
using StringEncodings
enc"windows-1252"
open("test/test14.asc",enc"utf-16le") do io
  for line in eachline(io, chomp=false)
    print("line: ",line)
  end
end


methods(open)

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



using StringEncodings
enc = PossibleEncodings([enc"utf-16le",enc"utf-8"],iscorrectencoding_logfile)
io = open("test/test14.log",enc)


using LTspice
file = "C:\\Users\\Chris\\Desktop\\New folder\\test15.asc"
file = "test/test1.asc"
file = "test/test2.asc"
file = "test/test3.asc"
file = "test/test4.asc"
file = "test/test5.asc"
file = "test/test6.asc"
file = "test/test7.asc"
file = "test/test8.asc"
file = "test/test9.asc"
file = "test/test10.asc"
file = "test/test11.asc"
file = "test/test12.asc"
file = "test/test13.asc"
file = "test/test14.asc"
file = "test/test15.asc"
sim = LTspiceSimulation(file,tempdir=true)
parameternames(sim)
measurementnames(sim)
sim.logfileencoding
sim.circuitfileencoding
sim.logpath
sim.circuitfilearray
sim["a"]

run!(sim)

for line in sim.circuitfilearray
  print(line)
end

run!(sim)

regex = r"""
          ([^\d ][^ =]*)
          [ ]*={0,1}[ ]*
          ([-+]{0,1}[0-9.]+e{0,1}[-+0-9]*)(k|meg|g|t|m|u|μ|n|p|f){0,1}
          [^-+*/ ]*
          (?:\s|\\n|\r|\n|$)
          (?![-+*/])
          """ix
line = "m = 2\\n.param μ = 3\\n.param MEG = 4\\n.param Ω = 5\\n.param θ = 6\\n.param Δ = 7\\n.param Φ = 8μ\\n.param ψ = 9μF\n"
line = "Vin = 5.0\n"
line = "a = 3.0\n"
line = "a=10 b=20 c=50 + a + b d=30\\n"
line2 = "c=50 + a + b d=30\\n"
line2 = "ψ = 9μF\n"
match(regex,line)
match(regex,line2)



match(r"([-+]{0,1}[0-9.]+e{0,1}[-+0-9]*)",line)

regex = r"[.](measure|meas)[ ]+(ac |dc |op |tran |tf |noise ){0,1}[ ]*([^\d ][^ =]*)[ ]+"ix







const parametercaptureregex =
          r"""
          ([a-z][a-z0-9_@#$.:\\]*)
          [ ]*={0,1}[ ]*
          ([-+]{0,1}[0-9.]+e{0,1}[-+0-9]*)(k|meg|g|t|m|u|μ|n|p|f){0,1}
          (?:\n|\\n|\r|\s)+
          (?![-+*/])
          """ix
