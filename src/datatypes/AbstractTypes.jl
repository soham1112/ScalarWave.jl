#--------------------------------------------------------------------
# Spacetime Discretization methods in Julia
# Soham 08-2018
# Define the Abstract Types
#--------------------------------------------------------------------

abstract type Manifold{Tag} end
abstract type Space{Tag, N, max, min} <: Manifold{Tag} end
