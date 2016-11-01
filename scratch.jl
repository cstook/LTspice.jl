using LTspice
cd("C:/Users/Chris/.julia/v0.5/LTspice/test")
cd("C:/Users/Chris/Documents/LTspiceXVII/myfiles")

sim1 = LTspiceSimulation("test3.asc",tempdir=true)
show(sim1)
run!(sim1)
sim1["Current"]
sim1["vin"] = 3.0
sim1

sim = LTspiceSimulation("Draft2.asc")
print(sim)
sim["d"] = 10.0
flush(sim,true)

line = "TEXT -48 -24 Left 2 !.param a=7897 b=8.9 k=9 + x pppp=76"
line = "TEXT -48 -24 Left 2 !.param a=7"
line = "TEXT -48 -24 Left 2 !.param k  = 9 / x pppp=76"
line = "TEXT -424 -152 Left 2 !.param a = 10.0\n.param b 7.999999999999999e9n\n.param c = 2.0"
parameterregex =
r"""
[.](?:parameter|param)[ ]+
([a-z][a-z0-9_@#$.:\\]*)
[= ]+
([-+]{0,1}[0-9.]+e{0,1}[-+0-9]*)(k|meg|g|t|m|u|μ|n|p|f){0,1}[ ]*
"""ix
parameterregex =
r"""
[.](?:parameter|param)[ ]+
"""ix
m = match(parameterregex, line)
regex =
r"""
([a-z][a-z0-9_@#$.:\\]*)
[ ]*={0,1}[ ]*
([-+]{0,1}[0-9.]+e{0,1}[-+0-9]*)(k|meg|g|t|m|u|μ|n|p|f){0,1}
(?:\s|\n|\r|$)
(?![/+-/*//])
"""ix
m = match(regex, line, 29)

regex = r"\n"

const parameterregex = r"[.](?:parameter|param)[ ]+([a-z][a-z0-9_@#$.:\\]*)[= ]+([-+]{0,1}[0-9.]+e{0,1}[-+0-9]*)(k|meg|g|t|m|u|n|p|f){0,1}[ ]*(?:\\n|\r|$)"ix
