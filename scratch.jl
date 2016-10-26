using LTspice
cd("C:/Users/Chris/.julia/v0.5/LTspice/test")

sim1 = LTspiceSimulation("test5.asc",tempdir=true)
show(sim1)
run!(sim1)
sim1["Current"]
sim1["vin"] = 3.0
sim1


using LTspice
using StringEncodings
cd("C:/Users/Chris/.julia/v0.5/LTspice/test")
open("test4.log",enc"UTF-16LE") do io
  c = ""
  while ~eof(io)
    line = readline(io)
  #for line in eachline(io)
    m = match(r"\.step\s+(?:.*?)=(.*?)\s+(?:.*?)=(.*?)\s*$"i,line)
    if m != nothing
      println(line)
      println(line.data)
      c = m.captures[1]
      break
    end
  end
end
println(c)
c
f = parse(Float64,c)
f = parse(Float64,decode(c,"UTF-16BE"))
s = String(c)
f = parse(Float64,decode(s.data,"UTF-16BE"))




sim5 = LTspiceSimulation("test/test5.asc",tempdir=true)
show(sim5)
sim5["sum"]
measurementvalues(sim5)

simPCF1 = LTspiceSimulation("test/PCF_test1.asc",tempdir=true)
show(simPCF1)
a = measurementvalues(simPCF1)
simPCF1
simPCF1["sump1000"]
measurementnames(simPCF1)
parameternames(simPCF1)
pli = perlineiterator(simPCF1,header=true)
for line in pli
  println(line)
end

for line in perlineiterator(simPCF1,steporder=["a","c","b"],resultnames=("sum",),header=true)
  println(line)
end

using LTspice
cd("C:/Users/Chris/.julia/v0.5/LTspice/test")
LTspice.generatealltestlogfiles()

using StringEncodings
a = "\x002\0.\x005\0"
f = parse(Float64,decode(a.data,"UTF-16BE"))

print("\x002\0.\x005\0")
parse(Float64,a)
parse(Float64,"\x002\0.\x005\0")
print("\x002.\x005")
transcode(String,a)
LegacyStrings.ascii(a)
utf16(2.5)
buf = IOBuffer()
print(buf,a)
b = takebuf_string(buf)

2.5 -> "\x002\0.\x005\0"
1.00394 -> "\x001\0.\x000\x000\x003\09\x004\0"


s = "abcdefghij"
m = match(r"(bcd)",s)
typeof(String(m.captures[1]))
String(m.captures[1])

Pkg.test("LTspice")
