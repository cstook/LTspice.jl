

const dirlist = Array(ASCIIString,0) # list of directories to remove on exit

function removetempdirectories()
  for dir in dirlist
  	if ispath(dir)
    	rm(dir,recursive=true)
    end
  end
  return nothing
end

atexit(removetempdirectories)

