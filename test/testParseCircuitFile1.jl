using LTspice
using Base.Test

PCF_test1file = "PCF_test1.asc"
exc = ""
PCF_test1 = LTspiceSimulation!(PCF_test1file,exc)
show(PCF_test1)

alist = [1.0,2.0]
blist = [10.0,15.0,20.0,25.0]
clist = [100.0,200.0,300.0]
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