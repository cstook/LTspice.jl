using LTspice
using Base.Test

test4file = "test4.asc"
exc = ""
test4 = LTspiceSimulation(test4file,exc)
show(test4)
show(LTspice.circuitparsed(test4))
show(test4.log)

alist = [1.0,2.0]
blist = [10.0,15.0,20.0,25.0]

@test stepvalues(test4) == (alist,blist,[])
@test measurementnames(test4) == ["sum","sump1000"]
@test measurementnames(test4.log) == measurementnames(test4)
@test stepnames(test4) == ["a","b"]
@test stepnames(test4.log) == stepnames(test4)
@test logpath(test4) != ""

islinux = @linux? true:false
if ~islinux
    @test circuitpath(test4) == test4file
end

@test typeof(circuitpath(test4.log)) == Type(ASCIIString)
@test typeof(parametervalues(test4)) == Array{Float64,1}
@test measurementvalues(test4)[1,1,1,1] == 11.0
@test ltspiceexecutablepath(test4) == ""
@test haskey(test4,"sum") == false  # measurments in stepped files are not a Dict
@test length(test4.log) == 16

verify = zeros(Float64,2,2,4,1)
for (i,a) in enumerate(alist)
    for (j,b) in enumerate(blist)
        verify[1,i,j,1] = a+b
        @test test4[1,i,j,1] == verify[1,i,j,1]
        verify[2,i,j,1] = a+b+1000
        @test test4[2,i,j,1] == verify[2,i,j,1]
    end
end

pli = PerLineIterator(test4)
show(pli)
for line in pli
    @test (line[1]+line[2] == line[3])
    @test (line[3] + 1000 == line[4])
end

pli = PerLineIterator(test4,resultnames=["sum"],steporder=["b","a"])
for line in pli
    @test (line[1]+line[2] == line[3])
end

@test measurementvalues(test4) == verify
show(test4)
show(LTspice.circuitparsed(test4))
show(test4.log)

