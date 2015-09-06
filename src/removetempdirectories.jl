

const dirlist = Array(ASCIIString,0) # list of directories to remove on exit

function removetempdirectories()
  for dir in dirlist
    rm(dir,recursive=true)
  end
  return nothing
end

atexit(removetempdirectories)

