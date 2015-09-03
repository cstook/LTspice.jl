# LTspice.jl

[![Build Status](https://travis-ci.org/cstook/LTspice.jl.svg?branch=master)](https://travis-ci.org/cstook/LTspice.jl)
[![Coverage Status](https://coveralls.io/repos/cstook/LTspice.jl/badge.svg?branch=v0r4_working&service=github)](https://coveralls.io/github/cstook/LTspice.jl?branch=v0r4_working)

LTspice.jl provides a julia interface to [LTspice<sup>TM</sup>](http://www.linear.com/designtools/software/#LTspice).  Several interfaces are provided.

1. A dictionary like interface to access parameters and measurements by name.
2. An array interface, which is primarily for measurements of stepped simulations.
3. Simulations can be called like functions.

## [Example 1](https://github.com/cstook/LTspice.jl/blob/v0r4_working/examples/example%201/example1.ipynb)

<img src="https://github.com/cstook/LTspice.jl/blob/v0r4_working/examples/example%201/example1.jpg">

Import the module.
```julia
using LTspice
```

Create an instance of LTspiceSimulation!.
```julia
circuitpath = "example1.asc"
executablepath = "C:/Program Files (x86)/LTC/LTspiceIV/scad3.exe"
example1 = LTspiceSimulation(circuitpath,executablepath)
```

Access parameters and measurements using their name as the key.

Set a parameter to a new value.
```julia
example1["rload"] = 20.0  # set parameter Rload to 25.0
```

Read the resulting measurement.
```julia
loadpower = example1["pload"] # run simulation, return Pload
```

Circuit can be called like a function
```julia
loadpower = example1(100.0)  # pass Rload, return Pload
```

Use [Optim.jl](https://github.com/JuliaOpt/Optim.jl) to perform an optimization on a LTspice simulation

```julia
using Optim
result = optimize(rload -> -example1(rload)[1],10.0,100.0)
rload_for_maximum_power = example1["rload"]
```

For additional information

[LTspice.jl API](https://github.com/cstook/LTspice.jl/blob/v0r4_working/doc/api.md)

[Introduction to LTspice.jl](https://github.com/cstook/LTspice.jl/blob/v0r4_working/doc/introduction.ipynb)





