using LTspice
using Base.Test

PCF_test1file = "PCF_test1.asc"
exc = ""
PCF_test1 = LTspiceSimulation(PCF_test1file,exc)
show(PCF_test1)
show(PCF_test1.circuit)
show(PCF_test1.log)

alist = [1.0,2.0]
blist = [10.0,15.0,20.0,25.0]
clist = [100.0,200.0,300.0]

@test steps(PCF_test1) == (alist,blist,clist)
@test measurementnames(PCF_test1) == ["sum","sump1000"]
@test measurementnames(PCF_test1.log) == measurementnames(PCF_test1)
@test stepnames(PCF_test1) == ["a","b","c"]
@test stepnames(PCF_test1.log) == stepnames(PCF_test1)
@test logpath(PCF_test1) != ""
islinux = @linux? true:false
if ~islinux
    @test circuitpath(PCF_test1) == PCF_test1file
end
@test typeof(circuitpath(PCF_test1.log)) == Type(ASCIIString)
@test typeof(parametervalues(PCF_test1)) == Array{Float64,1}
@test measurements(PCF_test1)[1,1,1,1] == 111.0
@test ltspiceexecutablepath(PCF_test1) == ""
@test haskey(PCF_test1,"sum") == false  # measurments in stepped files are not a Dict
@test length(PCF_test1.log) == 48


verify = zeros(Float64,2,2,4,3)
for (i,a) in enumerate(alist)
    for (j,b) in enumerate(blist)
        for (k,c) in enumerate(clist)
            verify[1,i,j,k] = a+b+c
            @test PCF_test1[1,i,j,k] == verify[1,i,j,k]
            verify[2,i,j,k] = a+b+c+1000
            @test PCF_test1[2,i,j,k] == verify[2,i,j,k]
        end
    end
end

pli = PerLineIterator(PCF_test1)
show(pli)
for line in pli
    @test (line[1]+line[2]+line[3] == line[4])
    @test (line[4] + 1000 == line[5])
end

pli = PerLineIterator(PCF_test1,resultnames=["sum"],steporder=["b","a","c"])
for line in pli
    @test (line[1]+line[2]+line[3] == line[4])
end


@test measurements(PCF_test1) == verify
show(PCF_test1)
show(PCF_test1.circuit)
show(PCF_test1.log)

