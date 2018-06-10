# composite blocks are iterables
import Base: start, next, done, eltype, length

# composite blocks are indexable
import Base: getindex, setindex!, map!, eachindex

# Additional APIs
export blocks, CompositeBlock


"""
    CompositeBlock{N, T} <: MatrixBlock{N, T}

abstract supertype which composite blocks will inherit from.

# extended APIs

`blocks`: get an iteratable of all blocks contained by this `CompositeBlock`

"""
abstract type CompositeBlock{N, T} <: MatrixBlock{N, T} end

"""
    blocks(composite_block)

get an iterator that iterate through all sub-blocks.
"""
function blocks end

function map!(f::Function, dst::CompositeBlock, itr)
    @assert length(dst) >= length(itr) "composite block should have the same size"

    for (di, each) in zip(eachindex(dst), itr)
        dst[di] = f(each)
    end
    dst
end

function nparameters(c::CompositeBlock)
    count = 0
    for each in blocks(c)
        count += nparameters(each)
    end
    count
end

# TODO: make this a lazy list
function parameters(c::CompositeBlock)
    params = []
    for each in blocks(c)
        append!(params, parameters(each))
    end
    params
end

#################
# Dispatch Rules
#################

# TODO: optimize for blocks full of parameters



"""
    dispatch!(f, c, params) -> c

dispatch parameters and tweak it according to callback function `f(original, parameter)->new`

dispatch a vector of parameters to this composite block according to
each sub-block's number of parameters.
"""
function dispatch!(x::CompositeBlock, itr)
    @assert nparameters(x) == length(itr) "number of parameters does not match"

    count = 0
    for block in filter(x->nparameters(x) > 0, blocks(x))
        params = view(itr, count+1:count+nparameters(block))
        if block isa CompositeBlock
            dispatch!(block, params)
        else
            dispatch!(block, params...)
        end
        count += 1
    end
    x
end

function dispatch!(f::Function, x::CompositeBlock, itr)
    @assert nparameters(x) == length(itr) "number of parameters does not match"

    count = 0
    for block in filter(x->nparameters(x) > 0, blocks(x))
        params = view(itr, count+1:count+nparameters(block))
        if block isa CompositeBlock
            dispatch!(f, block, params)
        else
            dispatch!(f, block, params...)
        end
        count += 1
    end
    x
end

==(lhs::CompositeBlock, rhs::CompositeBlock) = false

include("ChainBlock.jl")
include("KronBlock.jl")
include("Control.jl")
include("Roller.jl")
include("Repeated.jl")
