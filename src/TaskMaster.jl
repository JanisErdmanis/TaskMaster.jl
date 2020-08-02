module TaskMaster

abstract type Learner end
ask!(learner::Learner) = error("For runner learner needs to implement ask! and tell! methods")
tell!(learner::Learner,message) = error("For runner learner needs to implement ask! and tell! methods")

abstract type Master end

include("abstractions.jl")
include("workmaster.jl")
include("evaluate.jl")

export captureslave!, releaseslave!, releaseall!
export HistoryMaster, WorkMaster, Loop, IgnorantLearner, ask!, tell!, evaluate!

export play!, replay!, PlayRes

end
