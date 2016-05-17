using LTspice
using Base.Test

test5file = "test5.asc"
exc = ""
test5 = LTspiceSimulation(test5file,exc)
show(test5)
show(LTspice.circuitparsed(test5))
show(test5.log)

alist = [1.0,2.0]

@test stepvalues(test5) == (alist,[],[])
@test measurementnames(test5) == ["sum","sump1000"]
@test measurementnames(test5.log) == measurementnames(test5)
@test stepnames(test5) == ["a"]
@test stepnames(test5.log) == stepnames(test5)
@test logpath(test5) != ""

islinux = @linux? true:false
if ~islinux
    @test circuitpath(test5) == test5file
end

@test typeof(circuitpath(test5.log)) == Type(ASCIIString)
@test typeof(parametervalues(test5)) == Array{Float64,1}
@test measurementvalues(test5)[1,1,1,1] == 1.0
@test ltspiceexecutablepath(test5) == ""
@test haskey(test5,"sum") == false  # measurments in stepped files are not a Dict
@test length(test5.log) == 4

verify = zeros(Float64,2,2,1,1)
for (i,a) in enumerate(alist)
    verify[1,i,1,1] = a
    @test test5[1,i,1,1] == verify[1,i,1,1]
    verify[2,i,1,1] = a+1000
    @test test5[2,i,1,1] == verify[2,i,1,1]
end

pli = PerLineIterator(test5)
show(pli)
for line in pli
    @test (line[1] == line[2])
    @test (line[2] + 1000 == line[3])
end


@test measurementvalues(test5) == verify
show(test5)
show(LTspice.circuitparsed(test5))
show(test5.log)

