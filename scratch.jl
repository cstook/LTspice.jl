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
regex = r"""
        ([^\d ][^ =]*)()
        [ ]*={0,1}[ ]*
        ([-+]{0,1}[0-9.]+e{0,1}[-+0-9]*)()(k|meg|g|t|m|u|μ|n|p|f){0,1}()
        [^-+*/ ]*
        (?:\s|\\n|\r|$)
        (?![-+*/])()
        """ix

card1 = ".param m = 2\\n"
card2 = ".param μ = 3\\n"
card3 = ".param MEG = 4\\n"
card4 = ".param Ω = 5\\n"
card5 = ".param θ = 6\\n"
card6 = ".param Δ = 7\\n"
card7 = ".param Φ = 8μ\\n"
card8 = ".param ψ = 9μF\n"
m1=match(regex,card1)
m1.offsets
card1[8:9-1]


m2=match(regex,card2)
m2.offsets
card2[8:10-1]


m3=match(regex,card3)
match(regex,card4)
match(regex,card5)
match(regex,card6)
match(regex,card7)
match(regex,card8)


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

Regular expressions seems to be returning offsets in bytes not characters.  Is this the intended behavior?  Is there a way to get the offsets in characters?
regex = r"(3).*(5)"
s1 = "123a56789"
m1 = match(regex,s1)
println(m1.offsets)
s2 = "123α56789"
m2 = match(regex,s2)
println(m2.offsets)
s1[5:5]
s2[6:6]

m3 = match(r"(α)()",s2)
m3.offsets
length("α")
