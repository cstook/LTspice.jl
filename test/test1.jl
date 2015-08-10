filename = "test1.asc"
exc = ""  # null string will not run LTspice.exe.  Test parsing only.
test1 = ltspicesimulation!(filename,exc)
LTspice.readlog!(test1)

@test test1["Vin"] == 5
@test test1["load"] == 2
@test test1["current"] == 2.5
