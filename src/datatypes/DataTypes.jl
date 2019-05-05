#--------------------------------------------------------------------
# Spacetime Discretization methods in Julia
# Soham 08-2018
# Define concrete datatypes
#--------------------------------------------------------------------

struct U  end
struct V  end
struct CU end
struct CV end

struct _uu end
struct _dd end
struct _u  end
struct _d  end
struct _udd end

struct Null end
struct Spacelike end 

struct GaussLobatto{Tag ,N, min, max} <: Space{Tag, N, max, min} end
struct Chebyshev{Tag ,N, min, max} <: Space{Tag, N, max, min} end
struct Taylor{Tag ,N, min, max} <: Space{Tag, N, max, min} end

# add new basis representations here.
Cardinal{Tag, N} = Union{GaussLobatto{Tag, N}, Taylor{Tag, N}} 
Galerkin{Tag, N} = Union{Chebyshev{Tag, N}} 

struct Field{S, D, T}
    space::Type{S}
    value::AbstractArray{T, D}
end

struct Boundary{S, D, T}
    space::Type{S}
    value::Array{T, D}
end

struct Operator{S, D, T}
    space::Type{S}
    value::AbstractArray{T, D}
end

struct IntegrationOperator{S}
    space::Type{S}
    value::Union{AbstractArray{T, D}, UniformScaling} where {T,D}
end

struct ProductSpace{S1<:Space, S2<:Space, S3<:Space} end

struct ProductSpaceOperator{S, D, T}
    space::Type{S}
    value::Array{T, D}
end
