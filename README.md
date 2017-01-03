# MsgPack

[![Build Status](https://travis-ci.org/colinfang/MsgPack.jl.svg?branch=master)](https://travis-ci.org/colinfang/MsgPack.jl)

## Overview

This package provides basic support for the [msgpack](http://msgpack.org) format. It only works for 64-bit machine.

This fork adds

    - Custom encoding via the extension type.
    - Better unpacked types for array and dict.

## Usage

```julia
julia> using MsgPack

julia> MsgPack.pack("hi")
3-element Array{Uint8,1}:
 0xa2
 0x68
 0x69

julia> MsgPack.unpack(MsgPack.pack((1, 2)))
2-element Array{Int64,1}:
 1
 2

julia> MsgPack.unpack(MsgPack.pack(-4.5))
-4.5

julia> f = open("in.mp")
julia> MsgPack.unpack(f)
"hello"

julia> f2 = open("out.mp", "w")
julia> MsgPack.pack(f2, [1, 2, "hi"])

```

## Note

In a round trip, `Tuple` would be interpreted as `Array`.

The standard method for encoding integers in msgpack is to use the most compact representation possible, and to encode negative integers as signed ints and non-negative numbers as unsigned ints.

For compatibility with other implementations, I'm following this convention.  On the unpacking side, every integer type becomes an Int64 in Julia, unless it doesn't fit (ie. values greater than 2^63 are unpacked as Uint64).

I might change this at some point, and/or provide a way to control the unpacked types.

## The Extension Type

The MsgPack spec [defines](https://github.com/msgpack/msgpack/blob/master/spec.md#formats-ext) the [extension type](https://github.com/msgpack/msgpack/blob/master/spec.md#types-extension-type) to be a tuple of `(typecode, bytearray)` where `typecode` is an application-specific identifier for the data in `bytearray`. MsgPack.jl provides support for the extension type through the `Ext` immutable.

It is defined like so

```julia
immutable Ext
    typecode::Int8
    data::Vector{Uint8}
end
```

and used like this

```julia
julia> a = [0x34, 0xff, 0x76, 0x22, 0xd3, 0xab]
6-element Array{UInt8,1}:
 0x34
 0xff
 0x76
 0x22
 0xd3
 0xab

julia> b = MsgPack.Ext(22, a)
MsgPack.Ext(22,UInt8[0x34,0xff,0x76,0x22,0xd3,0xab])

julia> p = pack(b)
9-element Array{UInt8,1}:
 0xc7
 0x06
 0x16
 0x34
 0xff
 0x76
 0x22
 0xd3
 0xab

julia> c = unpack(p)
MsgPack.Ext(22,UInt8[0x34,0xff,0x76,0x22,0xd3,0xab])

julia> c == b
true
```

MsgPack reserves typecodes in the range `[-128, -1]` for future types specified by the MsgPack spec. MsgPack.jl enforces this when creating an `Ext` but if you are packing an implementation defined extension type (currently there are none) you can pass `impltype=true`.

```julia
julia> MsgPack.Ext(-43, Uint8[1, 5, 3, 9])
ERROR: MsgPack Ext typecode -128 through -1 reserved by implementation
 in call at /Users/sean/.julia/v0.4/MsgPack/src/MsgPack.jl:48

julia> MsgPack.Ext(-43, Uint8[1, 5, 3, 9], impltype=true)
MsgPack.Ext(-43,UInt8[0x01,0x05,0x03,0x09])
```


## Custom Encoding

```julia
immutable A
    a::Int
    b::String
end

function MsgPack.encode(x::A)::Vector{UInt8}
    tmp = x.a, x.b
    MsgPack.pack(tmp)
end

function MsgPack.decode(::Type{A}, x::Vector{UInt8})::A
   a, b = MsgPack.unpack(x)
   A(a, b)
end

MsgPack.register(A, 4)

julia> x = [A(2, "hi"), A(3, "you")]
julia> MsgPack.unpack(MsgPack.pack(x))
2-element Array{A,1}:
 A(2,"hi")
 A(3,"you")

julia> x = Dict(1 => A(3, "you"), 2 => A(2, "hi"))
julia> MsgPack.unpack(MsgPack.pack(x))
Dict{Int64,A} with 2 entries:
  2 => A(2,"hi")
  1 => A(3,"you")
```

If `encode` or `decode` is not overriden, a generic version is used and it works for simple composite types.

```julia
function encode(x)::Vector{UInt8}
    tmp = [getfield(x, name) for name in fieldnames(x)]
    MsgPack.pack(tmp)
end

function decode{T}(::Type{T}, x::Vector{UInt8})::T
    args = MsgPack.unpack(x)
    T(args...)
end
```