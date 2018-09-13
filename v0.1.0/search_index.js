var documenterSearchIndex = {"docs": [

{
    "location": "#",
    "page": "Home",
    "title": "Home",
    "category": "page",
    "text": ""
},

{
    "location": "#LTspice.jl-1",
    "page": "Home",
    "title": "LTspice.jl",
    "category": "section",
    "text": "LTspice.jl provides a julia interface to LTspice<sup>TM</sup>.  Several interfaces are provided.A dictionary like interface to access parameters and measurements by name.\nAn array interface, which is primarily for measurements of stepped simulations.\nSimulations can be called like functions."
},

{
    "location": "install/#",
    "page": "Installation",
    "title": "Installation",
    "category": "page",
    "text": "#InstallationLTspice.jl is currently unregistered.  It can be installed using Pkg.clone.Pkg.clone(\"https://github.com/cstook/LTspice.jl.git\")The julia documentation section on installing unregistered packages provides more information.LTspice.jl is compatible with julia v0.7."
},

{
    "location": "install/#Supported-Platforms-1",
    "page": "Installation",
    "title": "Supported Platforms",
    "category": "section",
    "text": "LTspice.jl works on windows and linux with LTspice under wine.  macOS is not supported."
},

{
    "location": "quickstart/#",
    "page": "Quickstart",
    "title": "Quickstart",
    "category": "page",
    "text": ""
},

{
    "location": "quickstart/#Quickstart-1",
    "page": "Quickstart",
    "title": "Quickstart",
    "category": "section",
    "text": "jupyter version(Image: example 1)Import the module.using LTspice;Create an instance of LTspiceSimulation.example1 = LTspiceSimulation(\"example1.asc\",tempdir=true)Access parameters and measurements using their name as the key.Set a parameter to a new value.example1[\"Rload\"] = 20.0;  # set parameter Rload to 20.0Read the resulting measurement.loadpower = example1[\"Pload\"] # run simulation, return PloadCircuit can be called like a functionloadpower = example1(100.0)  # pass Rload, return PloadUse Optim.jl to perform an optimization on a LTspice simulationusing Optim\r\nresult = optimize(rload -> -example1(rload)[1],10.0,100.0)\r\nrload_for_maximum_power = example1[\"Rload\"]"
},

{
    "location": "quickstart/#Additional-Information-1",
    "page": "Quickstart",
    "title": "Additional Information",
    "category": "section",
    "text": "Introduction to LTspice.jl - a jupyter notebook with more examples."
},

{
    "location": "examples/#",
    "page": "Examples",
    "title": "Examples",
    "category": "page",
    "text": ""
},

{
    "location": "examples/#Example-2-1",
    "page": "Examples",
    "title": "Example 2",
    "category": "section",
    "text": "jupyter versionIn this example, the efficiency of a LTM6423 will be measured vs Vin and Iout.(Image: example2)Import modules.  For the plot Plots and PyPlot modules are used.using LTspice, Plots\r\npyplot()Create an instance of LTspiceSimulation.example2 = LTspiceSimulation(\"example2.asc\",tempdir=true)Define the values of vin and iout to test.vin_list = linspace(6.0,20.0,10)\r\niout_list = linspace(0.5,3.0,4)Loop over vin and iout measuring efficiency.  Vout is fixed at 3.3V.rfb(vout)= 0.6*60.4e3/(vout-0.6)\r\nfunction compute_efficiency_array(vin_list, iout_list, vout)\r\n    efficiency = Array{Float64}((length(vin_list),length(iout_list)))\r\n    for vin_index in eachindex(vin_list)\r\n        for iout_index in eachindex(iout_list)\r\n            (pin,pout) = example2(vin_list[vin_index],iout_list[iout_index],rfb(vout))\r\n            efficiency[vin_index,iout_index] = -pout/pin\r\n        end\r\n    end\r\n    return efficiency\r\nend\r\n@time efficiency = compute_efficiency_array(vin_list, iout_list, 3.3)Plot the results.plt = plot()\r\nfor iout_index in eachindex(iout_list)\r\n    plot!(plt,vin_list,efficiency[:,iout_index],label = \"Iout=\"*@sprintf(\"%2.2f\",iout_list[iout_index]))\r\nend\r\nplot!(plt, title = \"LTM6423 Efficiency @ Vout = 3.3V\")\r\nplot!(plt, xlabel = \"Vin (V)\", ylabel = \"Efficiency\")\r\nsavefig(plt,\"example2.svg\"); nothing # hide(Image: )"
},

{
    "location": "public_api/#",
    "page": "Public API",
    "title": "Public API",
    "category": "page",
    "text": ""
},

{
    "location": "public_api/#Public-Documentation-1",
    "page": "Public API",
    "title": "Public Documentation",
    "category": "section",
    "text": "Documentation for LTspice.jl\'s public interface"
},

{
    "location": "public_api/#Index-1",
    "page": "Public API",
    "title": "Index",
    "category": "section",
    "text": "Pages = [\"public_api.md\"]"
},

{
    "location": "public_api/#LTspice",
    "page": "Public API",
    "title": "LTspice",
    "category": "module",
    "text": "Main module for LTspice.jl - a Julia interface to LTspice\n\n\n\n\n\n"
},

{
    "location": "public_api/#LTspice.LTspiceSimulation",
    "page": "Public API",
    "title": "LTspice.LTspiceSimulation",
    "category": "type",
    "text": "Access parameters and measurements of an LTspice simulation.  Runs simulation as needed.\n\nAccess as a dictionary:\n\nmeasurement_value = sim[\"measurement_name\"]\nparameter_value = sim[\"parameter_name\"]\nsim[\"parameter_name\"] = new_parameter_value\n\nAccess as a function:\n\n(m1,m2,m3) = sim(p1,p2,p3)  # simulation with three measurements and three parameters\n\nAccess as arrays or tuples:\n\npnames = parameternames(sim)\nmnames = measurementnames(sim)\nsnames = stepnames(sim)\npvalues = parametervalues(sim)\nmvalues = measurementvalues(sim)\nsvalues = stepvalues(sim)\n\n\n\n\n\n"
},

{
    "location": "public_api/#LTspice.parametervalues",
    "page": "Public API",
    "title": "LTspice.parametervalues",
    "category": "function",
    "text": "parametervalues(sim)\n\nReturns an array of the parameters of sim in the order they appear in the circuit file\n\n\n\n\n\n"
},

{
    "location": "public_api/#LTspice.parameternames",
    "page": "Public API",
    "title": "LTspice.parameternames",
    "category": "function",
    "text": "parameternames(sim)\n\nReturns an tuple of the parameters names of sim in the order they appear in the circuit file.\n\n\n\n\n\n"
},

{
    "location": "public_api/#LTspice.measurementvalues",
    "page": "Public API",
    "title": "LTspice.measurementvalues",
    "category": "function",
    "text": "measurementvalues(sim)\n\nRetruns measurements of sim as an a array of Float64 values.\n\nvalue = measurementvalues(sim)[inner_step,\n                               middle_step,\n                               outer_step,\n                               measurement_name] # 3 nested steps\n\n\n\n\n\n"
},

{
    "location": "public_api/#LTspice.measurementnames",
    "page": "Public API",
    "title": "LTspice.measurementnames",
    "category": "function",
    "text": "measurementnames(sim)\n\nReturns an tuple of the measurement names of sim in the order they appear in the circuit file.\n\n\n\n\n\n"
},

{
    "location": "public_api/#LTspice.stepvalues",
    "page": "Public API",
    "title": "LTspice.stepvalues",
    "category": "function",
    "text": "stepvalues(sim)\n\nReturns the steps of sim as a tuple of three arrays of the step values.\n\n\n\n\n\n"
},

{
    "location": "public_api/#LTspice.stepnames",
    "page": "Public API",
    "title": "LTspice.stepnames",
    "category": "function",
    "text": "stepnames(sim)\n\nReturns an tuple of step names of sim.\n\n\n\n\n\n"
},

{
    "location": "public_api/#LTspice.circuitpath",
    "page": "Public API",
    "title": "LTspice.circuitpath",
    "category": "function",
    "text": "circuitpath(sim)\n\nReturns path to the circuit file.\n\nThis is the path to the working circuit file.  If tempdir=ture was used or if running under wine, this will not be the path given to the constructor.\n\n\n\n\n\n"
},

{
    "location": "public_api/#LTspice.executablepath",
    "page": "Public API",
    "title": "LTspice.executablepath",
    "category": "function",
    "text": "executablepath(sim)\n\nReturns path to the LTspice executable\n\n\n\n\n\n"
},

{
    "location": "public_api/#LTspice.logpath",
    "page": "Public API",
    "title": "LTspice.logpath",
    "category": "function",
    "text": "logpath(sim)\n\nReturns path to the log file.\n\n\n\n\n\n"
},

{
    "location": "public_api/#LTspice.parselog!",
    "page": "Public API",
    "title": "LTspice.parselog!",
    "category": "function",
    "text": "parselog!(sim)\n\nLoads log file of sim without running simulation. The user does not normally need to call parselog!.\n\n\n\n\n\n"
},

{
    "location": "public_api/#Base.flush",
    "page": "Public API",
    "title": "Base.flush",
    "category": "function",
    "text": "flush(sim)\n\nWrites sim\'s circuit file back to disk if any parameters have changed.  The user does not usually need to call flush.  It will be called automatically  when a measurement is requested and the log file needs to be updated.  It can be used  to update a circuit file using julia for simulation with the LTspice GUI.\n\n\n\n\n\n"
},

{
    "location": "public_api/#LTspice.run!",
    "page": "Public API",
    "title": "LTspice.run!",
    "category": "function",
    "text": "run!(sim)\n\nWrites circuit changes, calls LTspice to run sim, and reloads the log file.  The user normally does not need to call this.\n\n\n\n\n\n"
},

{
    "location": "public_api/#Working-With-Simulations-1",
    "page": "Public API",
    "title": "Working With Simulations",
    "category": "section",
    "text": "LTspice\r\nLTspiceSimulation\r\nparametervalues\r\nparameternames\r\nmeasurementvalues\r\nmeasurementnames\r\nstepvalues\r\nstepnames\r\ncircuitpath\r\nexecutablepath\r\nlogpath\r\nparselog!\r\nflush\r\nrun!"
},

{
    "location": "public_api/#LTspice.perlineiterator",
    "page": "Public API",
    "title": "LTspice.perlineiterator",
    "category": "function",
    "text": "perlineiterator(simulation, <keyword arguments>)\n\nRetruns iterator in the format required to pass to writecsv or writedlm.\n\nKeyword Arguments\n\nsteporder     – specify order of steps\nresultnames   – specify parameters and measurements for output\nheader        – true to make first line header\n\nThe step order defaults to the order the step values appear in the circuit file. Step order can be specified by passing an array of step names.  By default there is one column for each step, measurement, and parameter.  The desired measurements and parameters can be set by passing an array of names to resultnames.\n\n# write CSV with headers\nopen(\"test.csv\",false,true,true,false,false) do io\n    writecsv(io,perlineiterator(circuit2,header=true))\nend\n\n\n\n\n\n"
},

{
    "location": "public_api/#Exporting-Data-1",
    "page": "Public API",
    "title": "Exporting Data",
    "category": "section",
    "text": "perlineiterator"
},

{
    "location": "contents/#",
    "page": "Contents",
    "title": "Contents",
    "category": "page",
    "text": ""
},

{
    "location": "contents/#Contents-1",
    "page": "Contents",
    "title": "Contents",
    "category": "section",
    "text": "Pages = [\"install.md\",\"quickstart.md\",\"examples.md\",\"public_api.md\",\"internal_api.md\"]\r\nDepth = 2"
},

]}
