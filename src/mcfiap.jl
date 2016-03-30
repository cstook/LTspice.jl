"""
parses the circuit file changing all paths
in .inc, .include, and .lib directives to 
absolute paths
"""
function makecircuitfileincludeabsolutepath(originalcircuitpath::ASCIIString,
                                     workingcircuitpath::ASCIIString,
                                     executablepath::ASCIIString)
  executabledir = abspath(dirname(executablepath))
  originalcircuitdir = abspath(dirname(originalcircuitpath))
  ltspiceincludesearchpath = [joinpath(executabledir,"lib\\sub"),
                              originalcircuitdir]
  ltspicelibsearchpath = [joinpath(executabledir,"lib\\cmp"),
                          joinpath(executabledir,"lib\\sub"),
                          originalcircuitdir]                       
  workingdirectory = pwd()
  cd(originalcircuitdir)
  iocircuitread  = open(workingcircuitpath,true,false,false,false,false)
  lines = readlines(iocircuitread)
  close(iocircuitread)
  iocircuitwrite  = open(workingcircuitpath,false,true,false,true,false)
  regexposition = 1
  for line in lines
    regexposition = 1
    if ismatch(r"^TEXT .*?!"i,line) # found a directive
      while regexposition < endof(line)
        m = match(r"""(.include|.inc|.lib)[ ]+
                  [\"]{0,1}(.*?)[\"]{0,1}(?:\\n|\r|$)"""ix,
                  line,regexposition)
        if m == nothing 
          regexposition = endof(line)
        else
          regexposition = m.offset+length(m.match)
          if (m.captures[1] == ".include") | (m.captures[1] == ".inc")
            includefile = m.captures[2]
            if ~isfile(joinpath(ltspiceincludesearchpath[1],includefile))
              absolutefilepathfile = abspath(includefile)
              line = replace(line,includefile,absolutefilepathfile)
              regexposition += length(absolutefilepathfile)-length(includefile)
            end
          end
          if m.captures[1] == ".lib"
            libfile = m.captures[2]
            inpath1 = isfile(joinpath(ltspicelibsearchpath[1],libfile))
            inpath2 = isfile(joinpath(ltspicelibsearchpath[2],libfile))
            if ~ (inpath1 | inpath2)
              absolutefilepathfile = abspath(libfile) 
              line = replace(line,libfile,absolutefilepathfile)
              regexposition += length(absolutefilepathfile)-length(libfile)
            end
          end
        end
      end
    end
    write(iocircuitwrite,line)
  end
  close(iocircuitwrite)
  cd(workingdirectory)
  return nothing
end