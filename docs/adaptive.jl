# @info "Now testing parallel exection with TaskMaster"

# @everywhere f(x) = exp(-x^2)
# learner1d = AdaptiveLearner1D((0,1))
# for (i,(xi,yi)) in enumerate(Master(f,learner1d))
#     @show (xi,yi)
#     if i==10
#         # In practice this way of breaking might be udersirable because
#         # some values are still being evaluated at this point
#         break
#     end
# end

# @info "Testing parallel exection with TaskMaster but with a soft exit"

# @everywhere f(x) = exp(-x^2)
# learner1d = AdaptiveLearner1D((0,1))
# wlearner1d = WrappedLearner(learner1d,learner->learner.loss<0.1)
# for (xi,yi) in Master(f,wlearner1d)
#     @show (xi,yi)
# end

# @info "Testing evaluate method"

# @everywhere f(x) = exp(-x^2)
# learner1d = AdaptiveLearner1D((0,1))
# evaluate(f,learner1d,learner->learner.loss<0.1)

# @info "Testing evaluate method with AdaptiveLearner2D"

# @everywhere f(x) = exp(-x[1]^2 - x[2]^2)
# learner2d = AdaptiveLearner2D([(0,1),(0,1)])
# evaluate(f,learner2d,learner->learner.loss<0.1)
