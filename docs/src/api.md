# LTspice.jl API

##LTspiceSimulation(*circuitpath* [,*executablepath*])

Constructor for LTspiceSimulation object.  Circuitpath and execuatblepath are the path to the circuit file (.asc) and the LTspice executable.  If executable path is omitted, an attempt will be made to find it in the default location.  Operations on LTspiceSimulation will modify the circuit file.

##LTspiceSimulationTempDir(*circuitpath* [,*executablepath*])

Creates a temporary directory, copies the circuit file to the temporary directory, then calls LTspiceSimulation with the circuit path to the copy of the circuit file.  Operations on the LTspiceSimulation object will leave the original circuit unmodified.

Note: LTspice will need to be able to find all sub-circuits and libraries from the new location or the simulation will not run.  Anything included with .include or .lib directives will be changed to work correctly in temp directory.

##haskey(*LTspiceSimulation*, *key*)

For non stepped simulations, true if key is the name of a parameter or a measurement.  For stepped simulations true if key is the name of a parameter.

##keys(*LTspiceSimulation*)

For non stepped simulations, returns an array of the parameter names and the measurement names.  For stepped simulation returns a list of parameter names.  Within each group, the names will be in the order they appear in the circuit file.

##values(*LTspiceSimulation*)

Returns the values associated with keys(*LTspiceSimualtion!*) in the same order.  Simulation will be run before returning values, if necessary.

##getindex(*LTspiceSimulation*, *key*)
##getindex(*LTspiceSimulation*, *index1*)
##getindex(*LTspiceSimulation*, *index1*, *index2*, *index3*, *index4*)

Returns the value of the parameter or measurement specified by key or the measurement specified by the index.

The dictionary like interface with an ASCIIString key works for parameters and measurements of a non-stepped simulation and the parameters of a stepped simulation.

The array like interface returns measurement at the specified location in the measurements array.  If index2...index4 are omitted they are assumed 1.

Simulation will be run before returning values, if necessary.

##get(*LTspiceSimulation*, *key*, *default*)

Same as getindex, but with default value if index is not found

##setindex(*LTspiceSimulation*, *value*, *key*)
##setindex(*LTspiceSimulation*, *value*, *index*)

Sets the value of a parameter.  Parameter can be specified by name or position.

##eltype(*LTspiceSimulation*)

Returns Float64.

##length(*LTspiceSimulation*)

Returns length of the dictionary like interface.  The number of parameters and measurements for non-stepped simulations.  The number of parameters for stepped simulations.

##call(*LTspiceSimulation*, *args...*)

Allows non-stepped simulations to have a function call syntax.  Parameters are passed in the order they appear in the circuit file.  An array of measurements is returned in the order they appear in the circuit file.

##getcircuitpath(*LTspiceSimulation*)

Returns path to the circuit file.

##getlogpath(*LTspiceSimulation*)

Returns path to the log file.  Same as circuit file except .log instead of .asc

##getltspiceexecutablepath(*LTspiceSimulation*)

Returns the path to the LTspice executable.

##getparameternames(*LTspiceSimulation*)

Returns an array of the parameters names in the order they appear in the circuit file.

##getparameters(*LTspiceSimulation*)

Returns an array of parameter values in the order they appear in the circuit file.

##getmeasurementnames(*LTspiceSimulation*)

Returns an array of the measurement names in the order they appear in the circuit file.

##getmeasurements(*LTspiceSimulation*)

Returns the measurement array.  The measurement array is a 4-d array of Float64 values.  
 
```julia
value = getmeasurements(simulation, measurement_name, inner_step, middle_step, outer_step)
```

For non-stepped simulations a 4-d array is returned where the length of all the step dimensions is 1.

##getstepnames(*LTspiceSimulation*)

Returns an array of step names.

##getsteps(*LTspiceSimulation*)

Returns a tuple of three arrays of the step values.  Always will return three arrays.

##loadlog!(*LTspiceSimulationTempDir*)

Loads log file without running simulation.

##PerLineIterator(*LTspiceSimulation*[,steporder=*steporder*][,resultnames=*resultnames*])

Creates an iterator in the format required to pass to writecsv or writedlm.  The step order defaults to the order the steps appear in the circuit file.  Step order can be specified by passing an array of step names.  By default there is one column for each step, measurement, and parameter.  The desired measurements and parameters can be set by passing an array of names to resultnames.

```julia
# write CSV with headers
io = open("test.csv",false,true,true,false,false)
pli = PerLineIterator(simulation)
writecsv(io,header(pli))
writecsv(io,pli)
close(io)
```

##header(*PerLineIterator*)

Returns the header for PerLineIterator in the format needed for writecsv or writedlm.  this is equivalent to 
```julia
transpose(getheaders(PerLineIterator))
```

##getheaders(*PerLineIterator*)

Returns an array of strings of parameter and measurement names.


See [Introduction to LTspice.jl](https://github.com/cstook/LTspice.jl/blob/master/docs/src/introduction.ipynb) for more information.

##flush(*LTspiceSimulation*)

Writes changes to circuit file back to disk.

