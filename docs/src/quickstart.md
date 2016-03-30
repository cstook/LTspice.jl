# Example 1 
[jupyter version](https://github.com/cstook/LTspice.jl/blob/master/examples/example%201/example1.ipynb)

![example 1](img/example1.jpg)


Import the module.
```julia
{example 1}
using LTspice;
```

Create an instance of `LTspiceSimulation`.
```julia
{example 1}
circuitpath = "example1.asc"
example1 = LTspiceSimulationTempDir(circuitpath)
```

Access parameters and measurements using their name as the key.

Set a parameter to a new value.
```julia
{example 1}
example1["rload"] = 20.0;  # set parameter Rload to 20.0
```

Read the resulting measurement.
```julia
{example 1}
loadpower = example1["pload"] # run simulation, return Pload
```

Circuit can be called like a function
```julia
{example 1}
loadpower = example1(100.0)  # pass Rload, return Pload
```

Use [Optim.jl](https://github.com/JuliaOpt/Optim.jl) to perform an optimization on a LTspice simulation

```julia
{example 1}
using Optim
result = optimize(rload -> -example1(rload)[1],10.0,100.0)
rload_for_maximum_power = example1["rload"]
```

# Additional Information

[Introduction to LTspice.jl](https://github.com/cstook/LTspice.jl/blob/master/docs/src/introduction.ipynb) - a jupyter notebook with more examples.