# parses the circuit file changing all paths
# in .inc, .include, and .lib directives to 
# absolute paths

function MakeCircuitFileIncludeAbsolutePath(originalcircuitpath::ASCIIString,
                                     workingcircuitpath::ASCIIString,
                                     executablepath::ASCIIString)
  executabledir = dirname(executablepath)
  originalcircuitdir = dirname(originalcircuitpath)
  ltspiceincludesearchpath = [joinpath(executabledir,"\\lib\\sub"),
                              originalcircuitdir]
  ltspicelibsearchpath = [joinpath(executabledir,"\\lib\\cmp"),
                          joinpath(executabledir,"\\lib\\sub"),
                          originalcircuitdir]
  workingdirectory = pwd()
  cd(originalcircuitdir)
  iocircuitread  = open(workingcircuitpath,true,false,false,false,false)
  lines = readall(iocircuitread)
  close(iocircuitread)
  iocircuitwrite  = open(workingcircuitpath,false,true,false,true,false)
  for line in lines
    regexposition = 1
    if ismatch(r"^TEXT .*?!"i,line) # found a directive
      while regexposition < endof(line)
        includematch = match(r"(?:.include|inc)[ ]+(.*)(?:\\n|\r|$)"ix,
                        line,regexposition)
        if includematch != nothing
          regexposition += includematch.offset+length(includematch.match)-1
          includefile = includematch.captures[1]
          if ~islinux
            if ~isabspath(includefile) |
               ~isfile(joinpath(ltspiceincludesearchpath[1],includefile))
              absolutefilepathfile = abspath(includefile)
              line = replace(line,includefile,absolutefilepathfile)
              regexposition += length(absolutefilepathfile)-length(includefile)
            end
          else
            # put linux code here
          end
        end
        libmatch = match(r"(?:.lib)[ ]+(.*)(?:\\n|\r|$)"ix,
                        line,regexposition)
        if libmatch != nothing
          regexposition += libmatch.offset+length(libmatch.match)-1
          libfile = libmatch.captures[1]
          if ~islinux
            if ~isabspath(libfile) |
               ~isfile(joinpath(ltspiceincludesearchpath[1],libfile)) |
               ~isfile(joinpath(ltspiceincludesearchpath[2],libfile))
              absolutefilepathfile = abspath(libfile) 
              line = replace(line,libfile,absolutefilepathfile)
              regexposition += length(absolutefilepathfile)-length(libfile)
            end
          else
            # put linux code here
          end
        end
      end
    end
    write(iocircuitwrite,line)
  end
  close(iocircuitwrite)
  return nothing
end