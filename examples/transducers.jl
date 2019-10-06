using Adaptive
using Transducers

learner1d = AdaptiveLearner1D((0,1))
#simpledriver!(x->exp(-x^2),learner1d,0.1)

# mutable struct unresolve <: AbstractChannel{Any}
#     learner
#     unresolved
#     state
#     excp
# end

import Base.iterate

mutable struct Runner
    l
    unresolved
end
Runner(l) = Runner(l,0)

function iterate(r::Runner,state)

    while r.unresolved>2
        sleep(1)
    end

    r.unresolved += 1
    return (ask!(r.l),nothing)
end

tell!(r::Runner,val) = (Adaptive.tell!(r.l,val); r.unresolved -= 1)

iterate(l::AdaptiveLearner1D) = iterate(l::AdaptiveLearner1D,nothing)

r = Runner(learner1d)

# LearnerChannel(learner) = LearnerChannel(learner,0,:open,nothing)

npoints(r::Runner) = length(r.l.data)

# import Base.take!
# import Base.put!
# import Base.isopen

# isopen(lc::LearnerChannel) = true   ### This is where I could put a waiting statement

# function take!(lc::LearnerChannel)
#     while lc.unresolved>2
#         sleep(1)
#     end

#     lc.unresolved += 1
#     ask!(lc.learner)
# end

# function put!(lc::LearnerChannel,value)
#     lc.unresolved -= 1
#     tell!(lc.learner,value)
# end

# lch = LearnerChannel(learner1d)

# Channel() do chan
#     foreach(x -> put!(chan, x), xform, itr)
#     return
# end

#jobsch = Channel(TakeWhile(x->npoints(lch)<10),lch)

#jobsch = Channel(Map(identity),r)

# TakeWhile does execute after taking the value of r. Thus the state unresolved would be 1. Thus perhaps TakeWhile should wrap runner. 
jobsch = Channel(Map(identity),r)

### How to make this line parallel?
resch = Channel(Map(x->(x,x^2)),jobsch)

foreach(Map(identity),resch) do input
    @show input
    tell!(r,input)
    # This is the point where one can test validity
    npoints(r)<10 || reduced()
end


# I think the interface I need is something like Loop!(xf,stop,learner::Learner) which would give a Channel type with a take! method.

# Perhaps more important is to have a map! between two channels which could be implemented in a whatever way behind the scenes. @async map!(x->x2,resch,jobsch). This thing would exit gracefully when jobsch would be closed. The master's only task would be to 
