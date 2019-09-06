#--------------------------------------------------------------------
# Spacetime Discretization methods in Julia
# Soham 07-2019
# Test functions inside functions
#--------------------------------------------------------------------

using NLsolve

function nonlinearsolver(PS::ProductSpace{S1, S2})::NTuple{5, Field{ProductSpace{S1, S2}}} where {S1, S2}

    # Compute constraints
    function C(f::Field{S}, r::Field{S}, ϕ::Field{S})::NTuple{2, Field{S}} where {S}
        E1 = 2*(DU*DU*r - (1/f)*(DU*f)*(DU*r)) + r*(DU*ϕ)^2
        E2 = 2*(DV*DV*r - (1/f)*(DV*f)*(DV*r)) + r*(DV*ϕ)^2
        return (E1, E2)
    end

    # Compute residuals
    function F(f::Field{S}, r::Field{S}, ϕ::Field{S})::NTuple{3, Field{S}} where {S}
        resf = DU*DV*log(abs(f)) + (2/r)*(DU*DV*r) + 2*(DU*ϕ)*(DV*ϕ)
        resr = 2*DU*(DV*r) +  (2/r)*(DU*r)*(DV*r) + (f/r)
        resϕ = DU*DV*ϕ + (1/r)*(DU*r)*(DV*ϕ) + (1/r)*(DV*r)*(DU*ϕ)
        finalresf = (I-B)*resf + B*(f - bndf)
        finalresr = (I-B)*resr + B*(r - bndr)
        finalresϕ = (I-B)*resϕ + B*(ϕ - bndϕ)
        return (finalresf, finalresr, finalresϕ)
    end
    
    # Wrapper for nlsolve
    function f!(fvec::Array{T,1}, x::Array{T,1}) where {T}
        fvec[:] = reshapeFromTuple(F(reshapeToTuple(PS, x)...))
    end

    # Compute common operators
    DU, DV = derivative(PS)
    B = incomingboundary(PS)
    I = identity(PS)

    # Set up free variables
    ϕ0 = Field(PS, (u,v)->exp(-(v-4)^2))  # Incoming wave travelling in the u-direction
    r0 = Field(PS, (u,v)->v-u)
    f0 = Field(PS, (u,v)->1)

    # Schwarzschild spacetime 
    M = Double64(1.0)
    r0 = Field(PS, (u,v)->find_r_of_UV(u,v,M))
    f0 = ((16*M^3)/r0)*exp(-r0/2M)
    ϕ0 = Field(PS, (u,v)->0)
    E1, E2 = C(f0, r0, ϕ0)
    
    # Solve constraints at the incoming boundary and set boundary conditions
    f0, rs, ϕ0 = initialdatasolver(f0, r0, ϕ0)
    bndf = B*f0
    bndr = B*rs
    bndϕ = B*ϕ0

    # Compute constraints before solve
    E1, E2 = C(f0, rs, ϕ0)
    @show L2(E1), L2(E2)

    # Start solve
    fsolved, rsolved, ϕsolved = reshapeToTuple(PS, nlsolve(f!, reshapeFromTuple((sin(f0) + f0, sin(r0) + r0, sin(ϕ0) + ϕ0)); 
                                                           autodiff=:forward, show_trace=false, ftol=1e-9).zero)
    # Compute constraints after solve
    E1, E2 = C(fsolved, rsolved, ϕsolved)
    @show L2(E1), L2(E2)
   
    return (fsolved, rsolved, ϕsolved, E1, E2)
end


#--------------------------------------------------------------------
# Solve for an arbitrary spacetime
# Do a convergence test
#--------------------------------------------------------------------

NT = 20
L2CU = zeros(NT)
L2CV = zeros(NT)
NVEC = zeros(NT)

struct U end
struct V end

import DoubleFloats.Double64

for N in 4:NT
    @show N
    PS = ProductSpace(ChebyshevGL{U, N, Double64}(-8, -6), 
                      ChebyshevGL{V, N, Double64}( 3,  5))
    f, r, ϕ, cu, cv = nonlinearsolver(PS)
    L2CU[N] = L2(cu)
    L2CV[N] = L2(cv)
    NVEC[N] = N
end

using PyPlot
plot(NVEC, log10.(L2CU), "-o")
plot(NVEC, log10.(L2CV), "-o")
show()
