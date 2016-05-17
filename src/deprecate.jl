# warn for deprecated methods

export getcircuitpath
function getcircuitpath(x::LTspiceSimulation) 
  warn("getcircuitpath(x) is deprecated, use circuitpath(x) instead")
  circuitpath(x)
end

export getlogpath
function getlogpath(x::LTspiceSimulation) 
  warn("getlogpath(x) is deprecated, use logpath(x) instead")
  logpath(x)
end

export getltspiceexecutablepath
function getltspiceexecutablepath(x::LTspiceSimulation) 
  warn("getltspiceexecutablepath(x) is deprecated, use ltspiceexecutablepath(x) instead")
  ltspiceexecutablepath(x)
end

export getparameternames
function getparameternames(x::LTspiceSimulation) 
  warn("getparameternames(x) is deprecated, use parameternames(x) instead")
  parameternames(x)
end

export getparameters
function getparameters(x::LTspiceSimulation) 
  warn("getparameters(x) is deprecated, use getparametervalues(x) instead")
  getparametervalues(x)
end

export getmeasurementnames
function getmeasurementnames(x::LTspiceSimulation) 
  warn("getmeasurementnames(x) is deprecated, use measurementnames(x) instead")
  measurementnames(x)
end

export getstepnames
function getstepnames(x::LTspiceSimulation) 
  warn("getstepnames(x) is deprecated, use stepnames(x) instead")
  stepnames(x)
end

export getmeasurements
function getmeasurements(x::LTspiceSimulation)
  warn("getmeasurements(x) is deprecated, use measurementvalues(x) instead")
  measurementvalues(x)
end

export getsteps
function getsteps(x::LTspiceSimulation)
  warn("getsteps(x) is deprecated, use stepvalues(x) instead")
  stepvalues(x)
end