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
include("workmaster.jl")
include("evaluate.jl")

export captureslave!, releaseslave!
export HistoryMaster, WorkMaster, Loop, IgnorantLearner, ask!, tell!, evaluate!

end
