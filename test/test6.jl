using LTspice
using Base.Test

test6file = "test6.asc"
exc = ""
test6 = LTspiceSimulation(test6file,exc)
show(test6)
show(LTspice.circuitparsed(test6))
show(LTspice.logparsed(test6))

@test measurementnames(test6) == []
@test measurementnames(LTspice.logparsed(test6)) == measurementnames(test6)
@test stepnames(test6) == []
@test logpath(test6) != ""

islinux = @linux? true:false
if ~islinux
    @test circuitpath(test6) == test6file
end

@test typeof(circuitpath(LTspice.logparsed(test6))) == Type(ASCIIString)
@test typeof(parametervalues(test6)) == Array{Float64,1}
#@test measurementvalues(test6)[1,1,1,1] == 1.0
@test ltspiceexecutablepath(test6) == ""
@test haskey(test6,"sum") == false  # measurments in stepped files are not a Dict
@test length(LTspice.logparsed(test6)) == 0


pli = PerLineIterator(test6)
show(pli)
@test length(pli) == 0
@test getheaders(pli) == []


show(test6)
show(LTspice.circuitparsed(test6))
show(LTspice.logparsed(test6))

