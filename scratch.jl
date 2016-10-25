using LTspice
cd("C:/Users/Chris/.julia/v0.5/LTspice/test")

sim1 = LTspiceSimulation("test5.asc",tempdir=true)
show(sim1)
run!(sim1)
sim1["Current"]
sim1["vin"] = 3.0
sim1

io = open("test1.log","r")
for line in readlines(io)
  m = match(r".*",line)
  println(m)
end

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


using LegacyStrings
a = "\x002\0.\x005\0"
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
