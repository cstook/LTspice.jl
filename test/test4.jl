using LTspice
using Base.Test

test4file = "test4.asc"
exc = ""
test4 = LTspiceSimulation!(test4file,exc)
show(test4)
show(test4.circuit)
show(test4.log)

alist = [1.0,2.0]
blist = [10.0,15.0,20.0,25.0]

@test getsteps(test4) == (alist,blist,[])
@test getmeasurementnames(test4) == ["sum","sump1000"]
@test getmeasurementnames(test4.log) == getmeasurementnames(test4)
@test getstepnames(test4) == ["a","b"]
@test getstepnames(test4.log) == getstepnames(test4)
@test getlogpath(test4) != ""

islinux = @linux? true:false
if ~islinux
    @test getcircuitpath(test4) == test4file
end

@test typeof(getcircuitpath(test4.log)) == Type(ASCIIString)
@test typeof(getparameters(test4)) == Array{Float64,1}
@test getmeasurements(test4)[1,1,1,1] == 11.0
@test getltspiceexecutablepath(test4) == ""
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

@test getmeasurements(test4) == verify
show(test4)
show(test4.circuit)
show(test4.log)

