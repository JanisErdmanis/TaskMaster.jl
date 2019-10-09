# TaskMaster

[![](https://img.shields.io/badge/docs-stable-blue.svg)](https://akels.github.io/TaskMaster.jl/stable)
[![](https://img.shields.io/badge/docs-dev-blue.svg)](https://akels.github.io/TaskMaster.jl/dev)
[![Build Status](https://travis-ci.org/akels/TaskMaster.jl.svg?branch=master)](https://travis-ci.org/akels/TaskMaster.jl)

A very daunting thing to program is a feedback loop with parallelism. Parallelism introduces stochasticity and thus debugging a feedback loop, or the part which learns in such a system is painful. On the other hand, we have so many different kinds of systems which implement parallelism - processes, threads, GPUs, job schedulers, GRID, etc. And so one ends up writing non-reusable code a case by a case.

A TaskMater is an abstraction for all of those issues through two critical concepts - Master and Learner. Master is a process which takes input values from a channel `Master.tasks` and evaluates in an arbitrary fashion/order and puts that in `Master.results` channel as a tuple (input, output). One makes a concrete implementation which uses processes, threads, GPUs, TPUs, job scheduler, etc. for evaluation. Or one can treat Master as some process which comes from a piece of experimental equipment, for example, from a multi-head scanning tunnelling microscope. Or one could try to find optimal parameters for plant growth where parallelism is very natural. 

The other concept is Learner which tries to learn from the Master by asking questions and receiving answers. Nature is that Master has received multiple questions, and he answers them in arbitrary order. Thus the Learner needs to be smart to optimize the objective. Again the Learner could be a computer program, animal (if you can teach them parallelism), or human pressing buttons.

Particularly in the case of a computer program, there is quite a variety. There is a class of learners where the programmer had programmed all cases of how the system should behave. My Python colleagues make a very great example in the [adaptive package](https://github.com/python-adaptive/adaptive), which allows adaptive function evaluation for reducing computational needs to make a beautiful figure (see Adaptive.jl for a wrapper). Another type of learners had been brainstormed in [this reedit](https://www.reddit.com/r/dataisbeautiful/comments/b8vv2p/i_wrote_a_python_package_to_do_adaptive_sampling/). The other class which might gain traction is a machine-learned Learner, for example, a plant state recognition algorithm with some ML to optimize the growth.
