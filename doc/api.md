# API

##LTspiceSimulation!(*circuitpath* [,*executablepath*])

Constructor for LTspiceSimulation! object.  Circuitpath and execuatblepath 
are the path to the circuit file (.asc) and the LTspice executable 
(C:/Program Files (x86)/LTC/LTspiceIV/scad3.exe).  If executable path is
omitted, an attempt will be made to find it in the default location.
Operations on LTspiceSimulation will modify the circuit file.

##LTspiceSimulation(*circuitpath* [,*executablepath*])

Creates a temporary directory, copies the circuit file to the temporary
directory, then calls LTspiceSimulation! with the circuit path to the copy 
of the circuit file.  Operations on the LTspiceSimulation! object will leave
the original circuit unmodified.

Note: LTspice will need to be able to find all sub-circuits and libraries
from the new location or the simulation will not run.

##haskey(*LTspiceSimulation!*, *key*)

For non stepped simulations, true if key is the name of a parameter or a
measurement.  For stepped simulations true if key is the name of a parameter.

##keys(*LTspiceSimulation*)

For non stepped simulations, returns an array of the parameter names and the 
measurement names.  For stepped simulation returns a list of parameter names.
Within each group, the names will be in the order they appear in the circuit
file.

##Values(*LTspiceSimulation*)

Returns the values associated with keys(*LTspiceSimualtion*) in the same order.
Simulation will be run before returning values, if necessary.

