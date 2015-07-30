# LTspice.jl

[![Build Status](https://travis-ci.org/cstook/LTspice.jl.svg?branch=master)](https://travis-ci.org/cstook/LTspice.jl)


LTspice.jl provides a julia interface to [LTspice<sup>TM</sup>](http://www.linear.com/designtools/software/#LTspice) simulation parameters and measurments.

## Example 1

<img src="https://github.com/cstook/LTspice.jl/blob/readme_examples/examples/example%201/example1.jpg">

In this example parameter x is the voltage accross a 5 Ohm resistor and measurment y is the current throught the resistor.

create an instance of LTspiceSimulation

```
using LTspice
filename = "example1.asc"
exc = defaultLTspiceExcutable()
ex1 = LTspiceSimulation(exc,filename)
```
where filename includes path to the simulation file and exc is the path to the LTspice excutable scad3.exe.  The function defaultLTspiceExcutable() retruns the correct path on a windows machine.  For now, this will need to be manualy determined for other systems.

Access parameters and measurments using their name as the key.

Set a parameter to a new value
```
ex1["x"] = 12.0
```

run the simulation
```
run!(ex1)
```

read the resulting measurment
```
print(ex1["y"])
```
this will print 2.4

getMeasurments returns a dictionary of just the measurments
```
dict_of_measurments = getMeasurments(ex1)
```

getParameters returns a dictionary of just the parameters
```
dict_of_parameters = getParameters(ex1)
```

getSimulationFile returns the simulation file name ACSIIString 
```
filename = getSimulationFile(ex1)
```


## Example 2






