function linkintempdirectoryunderwine(circuitpath::AbstractString)
  (d,f) = splitdir(abspath(circuitpath))
      linkdir = "/home/$(ENV["USER"])/.wine/drive_c/Program Files (x86)/LTC/LTspice.jl_links"
      if ~isdir(linkdir)
        mkpath(linkdir)
      end
      atexit(()->ispath(linkdir)&&rm(linkdir,recursive=true)) # delete this on exit
      templinkdir = mktempdir(linkdir)
      cd(templinkdir) do
        symlink(d,"linktocircuit")
      end
  joinpath(templinkdir,"linktocircuit",f)
end

function logpath(circuitpath::AbstractString)
  (everythingbeforedot,dontcare) = splitext(circuitpath)
  string(everythingbeforedot,".log")  # log file is .log instead of .asc
end

"""
    defaultltspiceexecutable()

Returns the default LTspice executable path for the operating system.
"""
function defaultltspiceexecutable()
  @static if is_windows()
    possibleltspiceexecutablelocations = [
    "C:\\Program Files (x86)\\LTC\\LTspiceIV\\scad3.exe",
    "C:\\Program Files\\LTC\\LTspiceIV\\scad3.exe"
    ]
  end
  @static if is_apple()
    possibleltspiceexecutablelocations = [
    "/Applications/LTspice.app/Contents/MacOS/LTspice"]
  end
  @static if is_linux()
    possibleltspiceexecutablelocations = [
    "/home/$(ENV["USER"])/.wine/drive_c/Program Files (x86)/LTC/LTspiceIV/scad3.exe"]
  end
  for canidatepath in possibleltspiceexecutablelocations
    if ispath(canidatepath)
      return canidatepath
    end
  end
  error("Could not find LTspice executable")
end
