### ToDo
# Register Adaptive.jl
# Write a documentation
# Write an anoucement

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
