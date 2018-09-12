

"""
    PossibleEncodings

**fields**
- `encodings`           -- Array of encodings to try
- `iscorrectencoding`   -- callable object
- `lastcorrectencoding` -- index of correct encoding last time open was called
"""
mutable struct PossibleEncodings
  encodings :: Array{StringEncodings.Encodings.Encoding,1}
  iscorrectencoding :: Function
  lastcorrectencoding :: Int
  io :: IO
  PossibleEncodings(enc,ice) = new(enc,ice,0,IOStream(""))
end

function iscorrectencoding_logfile(io)
  firstline = readline(io)
  if firstline[1:nextind(firstline, 1, 7)] == "Circuit:"
    seekstart(io.stream) # good idea?
    return true
  else
    return false
  end
end

function tryopen!(fname::AbstractString, enc::PossibleEncodings, i)
  try_io = open(fname,enc.encodings[i])
  if try_io!=nothing
    if enc.iscorrectencoding(try_io)
      enc.io = try_io
      return true
    else
      close(try_io.stream)  # ???
    end
  end
  return false
end

function Base.open(fname::AbstractString, enc::PossibleEncodings)
  if enc.lastcorrectencoding != 0 &&
     tryopen!(fname,enc,enc.lastcorrectencoding)
    return enc.io
  end
  for i in eachindex(enc.encodings)
    if i!=enc.lastcorrectencoding && tryopen!(fname,enc,i)
      enc.lastcorrectencoding = i
      return enc.io
    end
  end
  throw(ErrorException("no valid encoding found for $fname"))
end
