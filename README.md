# LTspice.jl

[![Build Status](https://travis-ci.org/cstook/LTspice.jl.svg?branch=master)](https://travis-ci.org/cstook/LTspice.jl)


LTspice.jl provides a julia interface to [LTspice<sup>TM</sup>](http://www.linear.com/designtools/software/#LTspice) simulation parameters and measurments.

## Example 1

<img src="https://github.com/cstook/LTspice.jl/blob/master/examples/example%201/example1.jpg">

In this example parameter x is the voltage accross a 5 Ohm resistor and measurment y is the current throught the resistor.

Create an instance of LTspiceSimulation.

```
using LTspice
filename = "example1.asc"
exc = defaultLTspiceExcutable()
ex1 = LTspiceSimulation(exc,filename)
```
Where filename includes path to the simulation file and exc is the path to the LTspice excutable scad3.exe.  The function defaultLTspiceExcutable() retruns the correct path on a windows machine.  For now, this will need to be manualy determined for other systems.

Access parameters and measurments using their name as the key.

Set a parameter to a new value.
```
ex1["x"] = 12.0
```

Run the simulation.
```
run!(ex1)
```

Read the resulting measurment.
```
print(ex1["y"])
```
This will print 2.4.

getMeasurments returns a dictionary of just the measurments
```
dict_of_measurments = getMeasurments(ex1)
```

getParameters returns a dictionary of just the parameters.
```
dict_of_parameters = getParameters(ex1)
```

getSimulationFile returns the simulation file name ACSIIString. 
```
filename = getSimulationFile(ex1)
```


## Example 2

Use [Optim.jl](https://github.com/JuliaOpt/Optim.jl) to perform an optimization on a LTspice simulation

<img src="https://github.com/cstook/LTspice.jl/blob/master/examples/example%202/example2.jpg">

Load modules.
```
using Optim
using LTspice
```

Create inctance of LTspiceSimulation type.
```
filename = "example2.asc"
exc = defaultLTspiceExcutable()
example2 = LTspiceSimulation(exc,filename)
```
Define function to minimize. In this case we will find Rload for maximum power transfer.
```
function minimizeMe(x::Float64, sim::LTspiceSimulation)
    sim["Rload"] = x
    run!(sim)
    return(-sim["pload"])
end
```

Perform the optimization.
```
result = optimize(x -> minimizeMe(x,example2),10.0,100.0)
```

```example2["Rload"]``` is now 49.997848295918075





