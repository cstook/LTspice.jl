

const dirlist = Array(AbstractString,0) # list of directories to remove on exit
"""
    removetempdirectories()

Deletes directories in global array `dirlist`.
"""
function removetempdirectories()
  for dir in dirlist
  	if ispath(dir)
    	rm(dir,recursive=true)
    end
  end
  return nothing
end

atexit(removetempdirectories)

