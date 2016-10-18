sim1 = LTspiceSimulation("test/test1.asc",tempdir=true)
show(sim1)
sim1["Current"]
sim1


sim5 = LTspiceSimulation("test/test5.asc",tempdir=true)
show(sim5)
sim5["sum"]


sim6 = LTspiceSimulation("test/test6.asc",tempdir=true)
show(sim6)

a = Array(Float64,0)
sizehint!(a,100)
