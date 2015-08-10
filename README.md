# LTspice.jl

[![Build Status](https://travis-ci.org/cstook/LTspice.jl.svg?branch=master)](https://travis-ci.org/cstook/LTspice.jl)


LTspice.jl provides a julia interface to [LTspice<sup>TM</sup>](http://www.linear.com/designtools/software/#LTspice) simulation parameters and measurments.  Parameters and measurments are accessed as a dictionary like type.  Simulations with stepped parameters (.step directive) are not supported.

## Example 1

<img src="https://github.com/cstook/LTspice.jl/blob/master/examples/example%201/example1.jpg">

In this example parameter x is the voltage accross a 5 Ohm resistor and measurment y is the current throught the resistor.

Create an instance of ltspicesimulation!.

```
using LTspice
filename = "example1.asc"
exc = defaultltspiceexcutable()
ex1 = ltspicesimulation(exc,filename)
```
Where filename includes path to the simulation file and exc is the path to the LTspice excutable scad3.exe.  The function ```defaultltspiceexcutable()``` retruns the correct path on a windows machine.  For now, this will need to be manualy determined for other systems.

An instance of ```ltspicesimulation!``` created with ```ltspicesimulation``` will copy the circuit file to a temporary working directory leaving the original circuit file unaltered.  Using ```ltspicesimulation!``` will overwrite original circuit file as changes are made.

Access parameters and measurments using their name as the key.

Set a parameter to a new value.
```
ex1["x"] = 12.0
```

Read the resulting measurment.
```
print(ex1["y"])
```
This will print 2.4.

Circuit file writes and simulation runs are lazy.  In this example the write and run occurs when measurment y is requested.

getmeasurments returns a dictionary of just the measurments
```
dict_of_measurments = getmeasurments(ex1)
```

getparameters returns a dictionary of just the parameters.
```
dict_of_parameters = getparameters(ex1)
```

getcircuitpath returns the simulation file name ACSIIString. 
```
filename = getcircuitpath(ex1)
```


## Example 2

Use [Optim.jl](https://github.com/JuliaOpt/Optim.jl) to perform an optimization on a LTspice simulation

<img src="https://github.com/cstook/LTspice.jl/blob/master/examples/example%202/example2.jpg">

Load modules.
```
using Optim
using LTspice
```

Create instance of ltspicesimulation! type.
```
filename = "example2.asc"
exc = defaultltspiceexcutable()
example2 = ltspicesimulation(exc,filename)  # work in temp directory
```
Define function to minimize. In this case we will find Rload for maximum power transfer.
```
function minimizeMe(x::Float64, sim::ltspicesimulation)
    sim["Rload"] = x
    return(-sim["pload"])
end
```

Perform the optimization.
```
result = optimize(x -> minimizeMe(x,example2),10.0,100.0)
```

```example2["Rload"]``` is now 49.997848295918075





