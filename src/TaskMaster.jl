### ToDo
# Put TaskMaster.jl and Adaptive.jl on Travis. [1h]
# Initiate documentation building procedure [1h]
# Submit Adaptive.jl and TaskMaster.jl to the Julia package registry. [1h]

# Then
# Write documentation
# Write an anoucement
# Try to couple TaskMaster with Transducers

module TaskMaster

abstract type Learner end
ask!(learner::Learner) = error("For runner learner needs to implement ask! and tell! methods")
tell!(learner::Learner,message) = error("For runner learner needs to implement ask! and tell! methods")

abstract type Master end

include("abstractions.jl")
include("procmaster.jl")
include("evaluate.jl")

export ProcMaster, Learner, ask!, tell!, WrappedLearner, IgnorantLearner, evaluate, Loop, captureslave!, releaseslave!

### High level interface
export CachedMaster, ProcMaster, Loop, Learner, ask!, tell!, evaluate

end
