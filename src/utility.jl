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
    "C:\\Program Files\\LTC\\LTspiceXVII\\XVIIx64.exe",
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
    "/home/$(ENV["USER"])/.wine/drive_c/Program Files/LTC/LTspiceXVII/XVIIx64.exe",
    "/home/$(ENV["USER"])/.wine/drive_c/Program Files (x86)/LTC/LTspiceIV/scad3.exe"]
  end
  for canidatepath in possibleltspiceexecutablelocations
    if ispath(canidatepath)
      return canidatepath
    end
  end
  error("Could not find LTspice executable")
end

function logfileencoding(path::AbstractString)
  ismatch(r"XVIIx64.exe",path) && return enc"UTF-16LE"
  ismatch(r"XVIIx32.exe",path) && return enc"UTF-16LE"
  ismatch(r"scad3.exe",path) && return enc"UTF-8"
  return enc"UTF-16LE" # for path = ""
end

function generatealltestlogfiles(;executablepath=defaultltspiceexecutable(),dir=pwd())
  for file in readdir(dir)
    (directory,filename_with_stuff_after_dot) = splitdir(file)
    (f,e) = splitext(filename_with_stuff_after_dot)
    if e==".asc" && ~in(f,("testIncA","testIncB","testIncC","testIncD","testIncE","testIncF",))
      sim=LTspiceSimulation(file,executablepath=executablepath)
      run!(sim,true)
      show(sim)
    end
  end
end

function does_circuitfilearray_file_match(sim::LTspiceSimulation)
  buf = IOBuffer()
  for element in sim.circuitfilearray
    write(buf,element)
  end
  y = take!(buf)
  s1 = String(y)
  x = open(sim.circuitpath,sim.circuitfileencoding) do io
    read(io)
  end
  s2 = String(x)
  s1 == s2
end
