module Arc
    export OptimalApogeeSim
    export BlindApogeeSim

    # From RocketSim
    export Environment
    export Rocket
    export PointProjectileCheck
    # From RocketSim.DragObjects
    export apogee_sim

    include("./StateAnalysis.jl")
    include("./RocketSim.jl")
    using .StateAnalysis
    using .RocketSim


    # Returns the next possible actions in the form of a 1xn array of state tuples
    function GetActions(rocket::Rocket, s)
        MaxChange = 0.1 * rocket.dt / 0.01
        actions = [s[4] - MaxChange, s[4], s[4] + MaxChange]

        for (index, value) in enumerate(actions)
            if value < 0.0
                actions[index] = 0.0
            end
            if value > 1.0
                actions[index] = 1.0
            end
        end
        
        return [(s[1],s[2],s[3], actions[i]) for i in 1:length(actions)]
    end


    # Makes action decisions by choosing the state with the action that has the least
    # discrepancy between the next simulation step and the optimal states surface
    function OptimalGen(rocket::Rocket, s, model)
        experimentStates_ = []
        
        for ExpState in GetActions(rocket, s)
            append!(experimentStates_, tuple(RocketSim.DragObjects.gen(rocket, ExpState)))
        end 

        experimentStates_ = convert(Array{NTuple{4, Float64}},experimentStates_)

        return BestState(experimentStates_, model)
    end


    # if the apogee_sim() of the current state is above target, it will choose the
    # last available action (opening the airbrakes). If below target, it will choose
    # the first returned action (closing the airbrakes).
    # Returns tuple of next simulated state and the action index it chooses
    function BlindGen(a::Rocket, s)
        rocket = Rocket(env=a.env, mass=a.mass, dt=a.dt, SampleRate=a.SampleRate, s_0=a.s_0)

        apogee = apogee_sim(rocket, s)[1]
        actions = GetActions(rocket, s)
        
        if apogee > rocket.env.target
            return (RocketSim.DragObjects.gen(rocket, last(actions)), 3)
        elseif apogee < rocket.env.target
            return (RocketSim.DragObjects.gen(rocket, actions[1]), 1)
        else
            return (RocketSim.DragObjects.gen(rocket, actions[2]), 2)
        end
    end


    # Runs the optimal surface model simulation. Not updated to include sample rates
    function OptimalApogeeSim(a::Rocket, model)
        s = a.s_0
        StateHistory = []

        while true
            s = OptimalGen(a, s, model)
            append!(StateHistory, tuple(s))
            if s[3] < 0
                break
            end
                
        end
        
        return StateHistory
    end


    # runs the simple above-below simulation
    function BlindApogeeSim(a::Rocket; history=true)
        s = a.s_0
        
        observe = true
        NextObservation = 0.0
        LastAction = 2
        t = 0.0

        if history
            StateHistory = []
        end

        while true
            if observe
                s, LastAction = BlindGen(a, s)
                
                if history
                    append!(StateHistory, tuple(s))
                end
                if s[3] < 0
                    break
                end
                
                observe = false
                NextObservation = t + a.SampleRate
            else
                s = RocketSim.DragObjects.gen(a, GetActions(a, s)[LastAction])

                if history
                    append!(StateHistory, tuple(s))
                end

                if s[3] < 0
                    break
                end
            end

            t += a.dt
            if t >= NextObservation
                observe = true
            end
        end

        if history
            return StateHistory
        else
            return s
        end
    end
end