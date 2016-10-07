function parselog!{Nparam,Nmeas}(x::NonSteppedSimulation{Nparam,Nmeas})
  open(x.logpath,true,false,false,false,false) do io
    measurment = Measurment(eachindex(x.measurmentvalues))
    exitcode = processlines!(io, x, [Header()], [measurement,IsStepParameters()])
    if exitcode == 2 # this was supposed to be a NonSteppedFile
      throw(ParseError(".log file is not expected type.  expected non-stepped, got stepped"))
    end
    processlines!(io, x, [measurement], [FooterDate()])
    processlines!(io, x, [FooterDuration()])
  end
  return nothing
end

function parselog!{Nparam,Nmeas,Nmdim,Nstep}(x::LTspiceSimulation{Nparam,Nmeas,Nmdim,Nstep})
  open(x.logpath,true,false,false,false,false) do io
    updaterestepvalues(io,x)
    updatemeasurmentvaluessize(x)
    measurment = Measurement(eachindex(x.measurments))


    exitcode = processlines!(io, slf, [header],[measurement,step])
    if exitcode == 1 # a non-stepped log file
      throw(ParseError(".log file is not expected type.  expected stepped, got non-stepped"))
    end
  end
  return nothing
end
