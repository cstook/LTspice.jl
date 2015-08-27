filename = "test1.asc"
exc = ""  # null string will not run LTspice.exe.  Test parsing only.
test1 = LTspiceSimulation!(filename,exc)
show(test1)
@test test1["Vin"] == 5
@test test1["load"] == 2
@test test1["current"] == 2.5
show(test1)
#@test getsteps(test1) == (Float64[],Float64[],Float64[])
@test getmeasurementnames(test1) == ["current"]
#@test getstepnames(test1) == []
@test getlogpath(test1) != ""
@test getcircuitpath(test1) != ""
@test typeof(getparameters(test1)) == Dict{ASCIIString,Float64}
@test getmeasurements(test1)[1,1,1,1] == 2.5
@test getltspiceexecutablepath(test1) == ""

t = try
  LTspiceSimulation(filename)
catch
  1  # LTspice is not inatalled on travis
end
#@test t == 1   # uncomment for travis

t = try
  LTspiceSimulation!(filename)
catch
  1  # LTspice is not inatalled on travis
end
#@test t == 1   #uncomment for travis

t = try 
  test1["this key is not valid"]
catch
  1
end
#@test t == 1    # uncomment for travis

keyss = ["Vin","load","current","bad key"]
valuess = [5.0,2.0,2.5,1.0]
for (key,value) in zip(keyss,valuess) 
  @test get(test1,key,1.0) == value 
end

@test test1[1] == 2.5
@test test1[1,1,1,1] == 2.5

@test eltype(test1) == Type(Float64)


for (key,value) in test1.log
  i = findfirst(keyss,key)
  @test value == valuess[i]
end

