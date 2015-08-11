# example1.jl
# the file example1.asc is a circuit where x is the voltage across 
# a 5 Ohm resistor and y is the current through the resistor

# load LTspice module
using LTspice

# filename of simulation file including path
circuitpath = "example1.asc"

# create an instance of ltspicesimulation! type in a temporary directory
example1 = ltspicesimulation(circuitpath)

# create an instance of ltspicesimulation! type which will modify original circuit file
example1 = ltspicesimulation!(circuitpath)

# you can also specify path of LTspice executable.
example1 = ltspicesimulation!(circuitpath,"C:\\Program Files (x86)\\LTC\\LTspiceIV\\scad3.exe")
example1 = ltspicesimulation(circuitpath,"C:\\Program Files (x86)\\LTC\\LTspiceIV\\scad3.exe")

# change parameter x to 12.0
example1["x"] = 12.0

# print a measurement
print(example1["y"])

# dictionary of just measurements
dict_of_measurements = getmeasurements(example1)

# dictionary of just parameters
dict_of_parameters = getparameters(example1)

# same as circuitpath above
filepath = getcircuitpath(example1)

# the LTspice executable path.
ltspiceexecutablepath = getltspiceexecutablepath(example1)