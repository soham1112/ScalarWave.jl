#--------------------------------------------------------------------
# Spacetime Discretization methods in Julia
# Soham 01-2018
#--------------------------------------------------------------------

module ScalarWave

export Patch, Boundary
export cheb, chebx, chebd, chebw,
	   delta, coordtrans, reshapeA, reshapeB, shapeA, shapeB, vandermonde, 
       operator, getIC,
       getPB, interpolatePatch,
       distribute

include("SpecCalculus.jl")
include("Utilities.jl")
include("Physics.jl")
include("Patch.jl")
include("Grid.jl")

end 
