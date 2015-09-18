import Base:start, next, done, eltype, length

# muli-lever iterator
immutable MultiLevelIterator
    max :: Array{Int,1}
end

function start(x::MultiLevelIterator)
    s = ones(x.max)
    if x.max != []
        s[1] = 0
    end
    return s
end

function next(x :: MultiLevelIterator, state :: Array{Int,1})
    i = 1
    d = false
    while (i<=length(x.max)) && ~d
        if state[i] < x.max[i]
            state[i] += 1
            d = true
        else
            state[i] = 1
            i += 1
        end
    end
    return (state,state)
end

function done(x::MultiLevelIterator, state::Array{Int,1})
    d = true
    for (s,m) in zip(state,x.max)
        if s<m
            d = false
        end
    end
    return d
end

eltype(::MultiLevelIterator) = Int

function length(x::MultiLevelIterator)
    if x.max == []
        l = 0
    else
        l = 1
        for m in x.max
            l *= m
        end
    end
    return l
end

