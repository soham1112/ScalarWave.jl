#--------------------------------------------------------------------
# Spacetime Discretization methods in Julia
# Soham 08-2018
# Define basic math and array operations for 2D spaces
#--------------------------------------------------------------------

import Base: +, -, *, /, size, range, vec, zero, similar, typeof

# dimensions and shape
order(PS::Type{ProductSpace{S1, S2}}) where {S1, S2} = (order(S2), order(S1))
dim(PS::Type{ProductSpace{S1, S2}}) where {S1, S2} = dim(S1) + dim(S2)
range(PS::Type{ProductSpace{S1, S2}}) where {S1, S2} = CartesianRange((length(S2), length(S1)))
size(PS::Type{ProductSpace{S1, S2}}) where {S1, S2} = (length(S2), length(S1))

# typeof
typeof(ProductSpace{S1, S2}) where {S1, S2 <: GaussLobatto{Tag,N}} where {Tag, N} = Float64
typeof(ProductSpace{S1, S2}) where {S1, S2 <: Taylor{Tag,N}} where {Tag, N} = Rational{BigInt}

# identity element
zero(u::Type{T}) where {T<:Field} = 0.0
zero(::Type{ProductSpace{S1, S2}}) where {S1, S2} = Field(ProductSpace{S1, S2}, (u,v)->0)
zero(::Type{ProductSpace{S1, S2}})::ProductSpaceOperator{ProductSpace{S1, S2}} where {S1, S2 <: Cardinal{Tag}} where {Tag} = 0*boundary(Null, ProductSpace{S1, S2})

# Allocate memory for a similar field
similar(u::Field{S, D, T})::Field{S,D,T} where {S, D, T} = Field(u.space, Array{T,D}(size(u.space)))

# unary operators
-(A::Field{ProductSpace{S1, S2}}) where {S1, S2 <: Cardinal{Tag}} where {Tag} = Field(ProductSpace{S1, S2}, -A.value)
+(A::Field{ProductSpace{S1, S2}}) where {S1, S2 <: Cardinal{Tag}} where {Tag} = Field(ProductSpace{S1, S2}, +A.value)

# field / field
+(A::Field{ProductSpace{S1, S2}},
  B::Field{ProductSpace{S1, S2}}) where {S1, S2 <: Cardinal{Tag}} where {Tag} = Field(ProductSpace{S1, S2}, A.value .+ B.value)
-(A::Field{ProductSpace{S1, S2}},
  B::Field{ProductSpace{S1, S2}}) where {S1, S2 <: Cardinal{Tag}} where {Tag} = Field(ProductSpace{S1, S2}, A.value .- B.value)
*(A::Field{ProductSpace{S1, S2}},
  B::Field{ProductSpace{S1, S2}}) where {S1, S2 <: Cardinal{Tag}} where {Tag} = Field(ProductSpace{S1, S2}, A.value .* B.value)
/(A::Field{ProductSpace{S1, S2}},
  B::Field{ProductSpace{S1, S2}}) where {S1, S2 <: Cardinal{Tag}} where {Tag} = Field(ProductSpace{S1, S2}, A.value ./ B.value)

# scalar / field
+(a::T,
  B::Field{ProductSpace{S1, S2}}) where {S1, S2 <: Cardinal{Tag}, T<:Real} where {Tag} = Field(ProductSpace{S1, S2}, a .+ B.value)
-(a::T,
  B::Field{ProductSpace{S1, S2}}) where {S1, S2 <: Cardinal{Tag}, T<:Real} where {Tag} = Field(ProductSpace{S1, S2}, a .- B.value)
*(a::T,
  B::Field{ProductSpace{S1, S2}}) where {S1, S2 <: Cardinal{Tag}, T<:Real} where {Tag} = Field(ProductSpace{S1, S2}, a .* B.value)
/(a::T,
  B::Field{ProductSpace{S1, S2}}) where {S1, S2 <: Cardinal{Tag}, T<:Real} where {Tag} = Field(ProductSpace{S1, S2}, a ./ B.value)
/(B::Field{ProductSpace{S1, S2}}, a::T) where {S1, S2 <: Cardinal{Tag}, T<:Real} where {Tag} = Field(ProductSpace{S1, S2}, B.value ./ a)

# scalar / operator
*(a::T, A::ProductSpaceOperator{PS}) where {T<:Real, PS} = ProductSpaceOperator(PS, a.*A.value)
/(A::ProductSpaceOperator{PS}, b::T) where {T<:Real, PS} = ProductSpaceOperator(PS, A.value ./b)

# operator / operator
+(A::ProductSpaceOperator{PS}, B::ProductSpaceOperator{PS}) where {PS} = ProductSpaceOperator(PS, A.value + B.value)
-(A::ProductSpaceOperator{PS}, B::ProductSpaceOperator{PS}) where {PS} = ProductSpaceOperator(PS, A.value - B.value)

function *(A::ProductSpaceOperator{ProductSpace{S1,S2}},
           B::ProductSpaceOperator{ProductSpace{S1,S2}})::ProductSpaceOperator{ProductSpace{S1, S2}} where {S1, S2}
    ni = length(S2)
    nj = length(S1)
    n = ni * nj
    C = reshape(reshape(A.value, n, n) * reshape(B.value, n, n), ni, nj, ni, nj)
    return ProductSpaceOperator(ProductSpace{S1, S2}, C)
end

# operator / field
function *(A::ProductSpaceOperator{ProductSpace{S1,S2}},
           u::Field{ProductSpace{S1, S2}})::Field{ProductSpace{S1, S2}} where {S1, S2}
    v = similar(u.value)
    for index in CartesianRange(size(v))
        i, ii = index.I
        v[index] = sum(A.value[i, ii, k, kk]*u.value[k, kk] for k in range(S2), kk in range(S1))
    end
    return Field(ProductSpace{S1, S2}, v)
end

function *(u::Field{PS}, A::ProductSpaceOperator{PS})::ProductSpaceOperator{PS} where {PS}
    B = similar(A.value)
    for index in CartesianRange(size(B))
        i, j, ii, jj = index.I
        B[index]     = u.value[i, j]*A.value[index]
    end
    return ProductSpaceOperator(PS, B)
end

function solve(A::ProductSpaceOperator{ProductSpace{S1, S2}}, u::Field{ProductSpace{S1, S2}})::Field{ProductSpace{S1, S2}} where {S1, S2}
    X =  vec(A) \ vec(u)
    return Field(ProductSpace{S1, S2}, shape(ProductSpace{S1, S2}, X))
end

# compute fields
function Field(PS::Type{ProductSpace{S1, S2}}, umap::Function)::Field{PS} where {S1, S2 <: Cardinal{Tag}} where {Tag}
    value = zeros(typeof(PS), size(PS))
    for index in range(PS)
        value[index] = umap(collocation(typeof(PS), index.I[1], order(S2)),
                            collocation(typeof(PS), index.I[2], order(S1)))
    end
    return Field(PS, value)
end

# compute fields at given U, V
function Field(PS::Type{ProductSpace{S1, S2}}, umap::Function,
               u::Field{ProductSpace{S1, S2}},
               v::Field{ProductSpace{S1, S2}})::Field{ProductSpace{S1, S2}} where {S1, S2 <: GaussLobatto{Tag,N}} where {Tag, N}
    value = zeros(Float64, size(PS))
    for index in range(PS)
        value[index] = umap(u.value[index], v.value[index])
    end
    return Field(PS, value)
end

# Kronecker product of two 1D operators
function ⦼(A::Operator{S1}, B::Operator{S2})::ProductSpaceOperator{ProductSpace{S1, S2}} where {S1, S2 <: Cardinal{Tag}} where {Tag}
    AB = zeros(typeof(A.space), length(S2), length(S1), length(S2), length(S1))
    for index in CartesianRange(size(AB))
        i ,j ,ii ,jj = index.I
        AB[index]    = A.value[j,jj]*B.value[i,ii]
    end
    return ProductSpaceOperator(ProductSpace{S1, S2}, AB)
end

# derivative operators
function derivative(PS::Type{ProductSpace{S1, S2}}) where {S1, S2}
    return (derivative(S1) ⦼ eye(S2), eye(S1) ⦼ derivative(S2))
end

# Null and Spatial boundary operators
function boundary(::Type{Spatial}, PS::Type{ProductSpace{S1, S2}})::ProductSpaceOperator{ProductSpace{S1, S2}} where {S1, S2 <: Cardinal{Tag}}  where {Tag}
    B = zeros(typeof(PS), length(S2), length(S1))
    B[1, :] = B[:, 1] = B[end, :] = B[:, end] = convert(typeof(PS), 1)
    return ProductSpaceOperator(ProductSpace{S1, S2}, reshape(diagm(vec(B)), (length(S2), length(S1), length(S2), length(S1))))
end

function boundary(::Type{Null},    PS::Type{ProductSpace{S1, S2}})::ProductSpaceOperator{ProductSpace{S1, S2}} where {S1, S2 <: Cardinal{Tag}}  where {Tag}
    B = zeros(typeof(PS), length(S2), length(S1))
    B[1, :] = B[:, 1] = convert(typeof(PS), 1)
    return ProductSpaceOperator(ProductSpace{S1, S2}, reshape(diagm(vec(B)), (length(S2), length(S1), length(S2), length(S1))))

end

# map functions to boundaries
function Boundary(PS::Type{ProductSpace{S1, S2}}, bmap::Function...)::Boundary{PS} where {S1, S2 <: Cardinal{Tag}}  where {Tag}
    B = zeros(typeof(PS), length(S2), length(S1))
    @assert length(bmap) == 4
    bnd1 = map(bmap[1], [collocation(typeof(PS), i,  order(S2)) for i  in range(S2)])
    bnd2 = map(bmap[2], [collocation(typeof(PS), ii, order(S1)) for ii in range(S1)])
    bnd3 = map(bmap[3], [collocation(typeof(PS), j,  order(S2)) for j  in range(S2)])
    bnd4 = map(bmap[4], [collocation(typeof(PS), jj, order(S1)) for jj in range(S1)])
    eltype(bnd1) <: typeof(PS) ? B[:,1] = bnd1 : error("Mapping doesn't preserve eltype. Aborting")
    eltype(bnd2) <: typeof(PS) ? B[1,:] = bnd2 : error("Mapping doesn't preserve eltype. Aborting")
    eltype(bnd3) <: typeof(PS) ? B[:, end] = bnd3 : error("Mapping doesn't preserve eltype. Aborting")
    eltype(bnd4) <: typeof(PS) ? B[end, :] = bnd4 : error("Mapping doesn't preserve eltype. Aborting")
    return Boundary(ProductSpace{S1, S2}, B)
end

# field / boundary
function +(u::Real, b::Boundary{ProductSpace{S1,S2}})::Field{ProductSpace{S1,S2}} where {S1,S2}
    return Field(ProductSpace{S1,S2}, u + b.value)
end

# scalar / boundary
function +(u::Field{ProductSpace{S1,S2}}, b::Boundary{ProductSpace{S1,S2}})::Field{ProductSpace{S1,S2}} where {S1,S2}
    return Field(ProductSpace{S1,S2}, u.value + b.value)
end

# shape and reshape operators
function vec(u::Field{ProductSpace{S1, S2}})::Array{eltype(u.value),1} where {S1, S2}
    return vec(u.value)
end

function vec(A::ProductSpaceOperator{ProductSpace{S1, S2}})::Array{eltype(A.value),2} where {S1, S2}
    return reshape(A.value, (prod(size(ProductSpace{S1, S2})), prod(size(ProductSpace{S1, S2}))))
end

function shape(PS::Type{ProductSpace{S1, S2}}, u::Array{T,1})::Array{eltype(u),2} where {S1, S2, T}
    return reshape(u, size(PS))
end
