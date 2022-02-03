include("./RocketSim.jl")

using .RocketSim
using LinearAlgebra
using ProgressMeter
using JLD


function AnalyzeStateSpace(h_space, v_space, θ_space; env=Environment())
    println("starting sim")

    possible_states = []
    upper_bound = []
    lower_bound = []

    @showprogress for h in h_space, v in v_space, θ in θ_space
        
        rocket_none = Rocket(s_0 = (h, v, θ * pi / 180, 0), env = env)
        rocket_full = Rocket(s_0 = (h, v, θ * pi / 180, 1), env = env)
        
        s = tuple(h, v, θ)
        max_h = env.target + env.flex
        min_h = env.target - env.flex
        
        # checks that a point particle could acheive target - flex
        # would be the same for rocket_full as well, so no need to run twice
        if PointProjectileCheck(rocket_none, s)
            max_s = apogee_sim(rocket_none)
            if max_s[1] > min_h
                # max (no-airbrake) apogee is past min_h
                # need to test full-airbrake
                if max_s[1] <= min_h + 2
                    append!(lower_bound, tuple(s))
                end

                min_s = targeted_sim(rocket_full, max_h)
                if min_s[3] < 0
                    # min (full-airbrake) apogee is below max_h
                    # both conditions met
                    append!(possible_states, tuple(s))
                    
                    if min_s[1] >= max_h - 2
                        append!(upper_bound, tuple(s))
                    end
                end
            end
        end
    end

    return [possible_states, upper_bound, lower_bound]
end

h_space = 0:1:255
v_space = 0:1:80
θ_space = 0:1:90 # in degrees, but Rocket only accepts radians

analysis = AnalyzeStateSpace(h_space, v_space, θ_space; env=Environment(g = 9.804))
# save("savedvars/possible_states.jld", "possible_states", analysis[1], "upper_bound", analysis[2], "lower_bound", analysis[3])
