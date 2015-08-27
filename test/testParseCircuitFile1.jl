using LTspice
using Base.Test

PCF_test1file = "PCF_test1.asc"
exc = ""
PCF_test1 = LTspiceSimulation!(PCF_test1file,exc)
show(PCF_test1)

alist = [1.0,2.0]
blist = [10.0,15.0,20.0,25.0]
clist = [100.0,200.0,300.0]

@test getsteps(PCF_test1) == (alist,blist,clist)
@test getmeasurementnames(PCF_test1) == ["sum","sump1000"]
@test getstepnames(PCF_test1) == ["a","b","c"]
@test getlogpath(PCF_test1) != ""
@test getcircuitpath(PCF_test1) == PCF_test1file
@test typeof(getparameters(PCF_test1)) == Dict{ASCIIString,Float64}
@test getmeasurements(PCF_test1)[1,1,1,1] == 111.0
@test getltspiceexecutablepath(PCF_test1) == ""



verify = zeros(Float64,2,2,4,3)
for (i,a) in enumerate(alist)
    for (j,b) in enumerate(blist)
        for (k,c) in enumerate(clist)
            verify[1,i,j,k] = a+b+c
            verify[2,i,j,k] = a+b+c+1000
        end
    end
end
@test getmeasurements(PCF_test1) == verify
show(PCF_test1)