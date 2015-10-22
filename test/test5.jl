using LTspice
using Base.Test

test5file = "test5.asc"
exc = ""
test5 = LTspiceSimulation(test5file,exc)
show(test5)
show(test5.circuit)
show(test5.log)

alist = [1.0,2.0]

@test getsteps(test5) == (alist,[],[])
@test getmeasurementnames(test5) == ["sum","sump1000"]
@test getmeasurementnames(test5.log) == getmeasurementnames(test5)
@test getstepnames(test5) == ["a"]
@test getstepnames(test5.log) == getstepnames(test5)
@test getlogpath(test5) != ""

islinux = @linux? true:false
if ~islinux
    @test getcircuitpath(test5) == test5file
end

@test typeof(getcircuitpath(test5.log)) == Type(ASCIIString)
@test typeof(getparameters(test5)) == Array{Float64,1}
@test getmeasurements(test5)[1,1,1,1] == 1.0
@test getltspiceexecutablepath(test5) == ""
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


@test getmeasurements(test5) == verify
show(test5)
show(test5.circuit)
show(test5.log)

