# Public Documentation

Documentation for `LTspice.jl`'s public interface

## Index

```@index
Pages = ["public_api.md"]
```


## Working With Simulations

```@docs
LTspice
LTspiceSimulation
LTspiceSimulation(x)
LTspiceSimulationTempDir
parametervalues
parameternames
measurementvalues
measurementnames
stepvalues
stepnames
circuitpath
ltspiceexecutablepath
logpath
loadlog!
flush(::LTspiceSimulation)
```

## Exporrting Data
	
```@docs
PerLineIterator
PerLineIterator(x)
headernames
header
```