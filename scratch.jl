sim1 = LTspiceSimulation("test/test1.asc",tempdir=true)
show(sim1)
sim1["Current"]
sim1


sim5 = LTspiceSimulation("test/test5.asc",tempdir=true)
show(sim5)
sim5["sum"]
measurementvalues(sim5)

simPCF1 = LTspiceSimulation("test/PCF_test1.asc",tempdir=true)
show(simPCF1)
a = measurementvalues(simPCF1)
simPCF1["sum"]
simPCF1["sump1000"]
measurementnames(simPCF1)
