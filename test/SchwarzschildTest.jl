#--------------------------------------------------------------------
# Spacetime Discretization methods in Julia
# Soham 04-2018
# Wave equation on Schwarzschild
#--------------------------------------------------------------------

using Einsum

#--------------------------------------------------------------------
# Define boundary and the product space
#--------------------------------------------------------------------
M = 1.0
ω = 1.0
PV, PU = 4, 4
Umax, Umin = -4M, -8M
Vmin, Vmax =  4M,  8M
SUV = ProductSpace{GaussLobatto(V,PV, Vmax, Vmin), 
                   GaussLobatto(U,PU, Umax, Umin)}

#--------------------------------------------------------------------
# Define coordinates and their associated derivatives
#--------------------------------------------------------------------
𝕌 = Field(SUV, (U,V)->U)
𝕍 = Field(SUV, (U,V)->V)
θ = Field(SUV, (U,V)->π/2)
ϕ = Field(SUV, (U,V)->0)

ø = zero(SUV) 
Ø = zero(Null, SUV) 

t = Field(SUV, (U,V)->find_t_of_UV(U, V, M), 𝕌, 𝕍)
r = Field(SUV, (U,V)->find_r_of_UV(U, V, M), 𝕌, 𝕍)
𝒓 = r + 2M*log(-1 + r/2M)

#--------------------------------------------------------------------
# Define derivative and boundary operators
#--------------------------------------------------------------------
𝔹 = boundary(Null, SUV)
𝔻𝕌, 𝔻𝕍 = derivative(SUV) 
𝔻r, 𝔻t = derivativetransform(SUV, t, r) 
𝔻θ, 𝔻ϕ = Ø, Ø

#--------------------------------------------------------------------
# Set boundary conditions 
# Note that you'd need to start with a set of boundary conditions
# that satisfy the operator.
#--------------------------------------------------------------------
ρ = 0 
𝕤 = exp(-(-6M + 𝕍)^2)
𝕓 = boundary(SUV, Null, :R)*𝕤

#--------------------------------------------------------------------
# Now construct the operator according to 
# Carsten Gundlach and Jorge Pullin 1997 Class. Quantum Grav. 14 991
#--------------------------------------------------------------------
𝕃 = 𝔻𝕌*𝔻𝕍 + ((𝔻𝕌*r)/r)*𝔻𝕍 + ((𝔻𝕍*r)/r)*𝔻𝕌

#--------------------------------------------------------------------
# Solve the system [also check the condition number and eigen values]
#--------------------------------------------------------------------
𝕨 = solve(𝕃 + 𝔹, ρ + 𝕓) 
𝕔 = basistransform(𝕨)

#--------------------------------------------------------------------
# Draw solutions 
#--------------------------------------------------------------------
drawpatch(𝕓, "../output/scattering/boundary")
drawpatch(𝕌, "../output/scattering/U")
drawpatch(𝕍, "../output/scattering/V")
drawpatch(t, "../output/scattering/t")
drawpatch(r, "../output/scattering/r")
drawpatch(𝕨, "../output/scattering/wave")

using Plots
pyplot()
heatmap(𝕔.value)
savefig("../output/scattering/coefficents")
close()
