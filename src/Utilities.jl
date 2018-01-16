#--------------------------------------------------------------------
# Spacetime Discretization methods in Julia
# Soham 01-2018
#--------------------------------------------------------------------

function delta{T<:Int}(i::T, j::T)::Float64
	return i==j ? 1 : 0
end

function coordtrans{T<:Int}(M::T, point::Array{Float64, 1}, loc::Array{T, 1})::Array{Float64, 1}
	x, y = point
    s = Float64[d for d in M-1:-2:-M+1]
	xp = (x + s[loc[1]])/M
	yp = (y + s[loc[2]])/M
	return [xp,yp]
end

function computeB{T<:Integer}(N::T, M::T, loc::Array{T, 1}, dbase::Dict)::Array{Float64,1}
	B2N = setB(N, loc, M)
	if sum(loc) == 2
		return reshape(B2N)
	elseif loc[1] == 1 || loc[2] == 1
		if loc[1] > loc[2]
			setBC!(B2N, extractBC(dbase[loc-[1,0]], 1, N), 1, N)	
		else
			setBC!(B2N, extractBC(dbase[loc-[0,1]], 0, N), 0, N)
		end
	else
		setBC!(B2N, extractBC(dbase[loc-[1,0]], 1, N), 1, N)
		setBC!(B2N, extractBC(dbase[loc-[0,1]], 0, N), 0, N)
	end 
	return reshapeB(B2N)
end

function reshapeA(op4N::Array{Float64,4})::Array{Float64,2}
    N = size(op4N)[1] - 1
    op2N = reshape(op4N, ((N+1)^2, (N+1)^2))
    return op2N
end

function shapeA(op2N::Array{Float64,2})::Array{Float64,4}
    N = Int(sqrt(size(op2N)[1])) - 1
    op4N = reshape(op2N, (N+1, N+1, N+1, N+1))
    return op4N
end

function reshapeB(b2N::Array{Float64,2})::Array{Float64,1}
    N = size(b2N)[1] - 1
    b1N = reshape(b2N, (N+1)^2)
    return b1N
end

function shapeB(b1N::Array{Float64,1})::Array{Float64,2}
    N = Int(sqrt(size(b1N)[1])) - 1
    b2N = reshape(b1N, (N+1, N+1))
    return b2N
end
