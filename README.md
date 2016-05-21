# LTspice.jl

[![Build Status](https://travis-ci.org/cstook/LTspice.jl.svg?branch=master)](https://travis-ci.org/cstook/LTspice.jl)
[![Coverage Status](https://coveralls.io/repos/cstook/LTspice.jl/badge.svg?branch=v0r4_working&service=github)](https://coveralls.io/github/cstook/LTspice.jl?branch=v0r4_working)
[![Build status](https://ci.appveyor.com/api/projects/status/uf5kr5bb7xvd8wrp/branch/master?svg=true)](https://ci.appveyor.com/project/cstook/ltspice-jl/branch/master)

LTspice.jl provides a julia interface to [LTspice<sup>TM</sup>](http://www.linear.com/designtools/software/#LTspice).  Several interfaces are provided.

1. A dictionary like interface to access parameters and measurements by name.
2. An array interface, which is primarily for measurements of stepped simulations.
3. Simulations can be called like functions.

##Installation

LTspice.jl is currently unregistered.  It can be installed using ```Pkg.clone```.
```julia
Pkg.clone("https://github.com/cstook/LTspice.jl.git")
```
The [julia documentation](http://docs.julialang.org) section on installing unregistered packages provides more information.

LTspice.jl is only compatible with julia v0.4 and v0.5dev

## [Example 1](https://github.com/cstook/LTspice.jl/blob/master/examples/example%201/example1.ipynb)

<img src="https://github.com/cstook/LTspice.jl/blob/master/examples/example%201/example1.jpg">

Import the module.
```julia
using LTspice
```

Create an instance of LTspiceSimulation.
```julia
circuitpath = "example1.asc"
example1 = LTspiceSimulationTempDir(circuitpath)
```

Access parameters and measurements using their name as the key.

Set a parameter to a new value.
```julia
example1["rload"] = 20.0  # set parameter Rload to 20.0
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
## Supported Platforms

LTspice.jl works on windows and linux with LTspice under wine.  Osx is not supported.

## Additional Information

Documentation is [here](http://cstook.github.io/LTspice.jl).

[Introduction to LTspice.jl](https://github.com/cstook/LTspice.jl/blob/master/docs/src/introduction.ipynb)

The [Linear Technology<sup>TM</sup>](http://www.linear.com) website

The [LTspice Yahoo Group](https://groups.yahoo.com/neo/groups/LTspice/info)

[LTwiki](http://www.ltwiki.org)



