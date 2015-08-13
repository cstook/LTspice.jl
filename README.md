# LTspice.jl

[![Build Status](https://travis-ci.org/cstook/LTspice.jl.svg?branch=master)](https://travis-ci.org/cstook/LTspice.jl)


LTspice.jl provides a julia interface to [LTspice<sup>TM</sup>](http://www.linear.com/designtools/software/#LTspice) simulation parameters and measurements.  Parameters and measurements are accessed as a dictionary like type.  .step directive is not supported.

## Example 1

<img src="https://github.com/cstook/LTspice.jl/blob/master/examples/example%201/example1.jpg">

In this example parameter x is the voltage across a 5 Ohm resistor and measurement y is the current through the resistor.

Import the module.
```
using LTspice
```

Create an instance of LTspiceSimulation!.
```
circuitpath = "example1.asc"
example1 = LTspiceSimulation(circuitpath)
```

If the LTspice executable cannot be found, it's location can be specified.
```
circuitpath = "example1.asc"
executablepath = "C:\\Program Files (x86)\\LTC\\LTspiceIV\\scad3.exe"
example1 = LTspiceSimulation(circuitpath, executablepath)
```

An instance of ```LTspiceSimulation!``` created with ```LTspiceSimulation``` will copy the circuit file to a temporary working directory leaving the original circuit file unaltered.  Using ```LTspiceSimulation!``` will overwrite original circuit file as changes are made.

Access parameters and measurements using their name as the key.

Set a parameter to a new value.
```
example1["x"] = 12.0
```

Read the resulting measurement.
```
print(example1["y"])
```
This will print 2.4.

Circuit file writes and simulation runs are lazy.  In this example the write and run occurs when measurement y is requested.

```getmeasurements``` returns a dictionary of just the measurements.
```
dict_of_measurements = getmeasurements(example1)
```

```getparameters``` returns a dictionary of just the parameters.
```
dict_of_parameters = getparameters(example1)
```

```getcircuitpath``` returns the circuit file path. 
```
filepath = getcircuitpath(example1)
```

```getltspiceexecutablepath``` returns the LTspice executable path.
```
ltspiceexecutablepath = getltspiceexecutablepath(example1)
```



## Example 2

Use [Optim.jl](https://github.com/JuliaOpt/Optim.jl) to perform an optimization on a LTspice simulation

<img src="https://github.com/cstook/LTspice.jl/blob/master/examples/example%202/example2.jpg">

Load modules.
```
using Optim
using LTspice
```

Create instance of LTspiceSimulation! type.
```
filepath = "example2.asc"
example2 = LTspiceSimulation(filepath) 	  # work in temp directory
```
Define function to minimize. In this case we will find Rload for maximum power transfer.
```
function minimizeme(x::Float64, sim::LTspiceSimulation)
    sim["Rload"] = x
    return(-sim["pload"])
end
```

Perform the optimization.
```
result = optimize(x -> minimizeme(x,example2),10.0,100.0)
```

```example2["Rload"]``` is now 49.997848295918075





