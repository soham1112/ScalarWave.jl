#--------------------------------------------------------------------
# Spacetime Discretization methods in Julia
# Soham 01-2018
#--------------------------------------------------------------------

module ScalarWave

include("./Types/AbstractTypes.jl")
include("./Spectral/Basis/BasisTypes.jl")
include("./Spectral/Basis/ChebyshevGL.jl")
include("./Spectral/Spaces/1Dspace.jl")
include("./Spectral/Spaces/2Dspace.jl")
include("./Spectral/Spaces/AnySpace.jl")
include("./Visualization/PyPlot.jl")
include("./Utilities/AxiSymmetry.jl")
include("./Utilities/BoundaryUtils.jl")
include("./Utilities/NLsolverUtils.jl")
include("./Utilities/BasisTransformationUtils.jl")
include("./Utilities/MultiPatchUtils.jl")
include("./Physics/Residuals.jl")

end 
