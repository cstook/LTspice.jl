# example1.jl
# the file example1.asc is a circuit where x is the voltage accross 
# a 5 Ohm resistor and y is the current through the resistor

# load LTspice module
using LTspice

# filename of simulation file including path
filename = "example1.asc"

# path to scad3.exe 
exc = defaultLTspiceExcutable()	

# create an instance of LTspiceSimulation type
ex1 = LTspiceSimulation(exc,filename) 

# change parameter x to 12.0
ex1["x"] = 12.0

# run the simualtion
run!(ex1)

# print a measurment
print(ex1["y"])

# dictionary od just measurments
dict_of_measurments = getMeasurments(ex1)

# dictionary of just parameters
dict_of_parameters = getParameters(ex1)

# same as filename above
filename = getSimulationFile(ex1)
