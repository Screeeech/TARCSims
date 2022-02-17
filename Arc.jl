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


    """
		GetActions(rocket, state)
	
    Returns the next possible actions in the form of a 1xn vector of state tuples
	---
	## Arguments
	-	rocket::Rocket = The rocket object
	-	s::Tuple{Float64, Float64, Float64, Float64} = the state tuple

	## Example
	GetActions(Rocket(), (130, 55, 85, 0.003))
	"""
    function GetActions(rocket::Rocket, s)
        MaxChange = rocket.DeploymentRate * rocket.dt
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


    """
		OptimalGen(rocket, state, model)
	
    Makes action decisions by choosing the state with the action that has the least
    discrepancy between the next simulation step and the optimal states surface
	---
	## Arguments
	-	rocket::Rocket = The rocket object
	-	s::Tuple{Float64, Float64, Float64, Float64} = the state tuple
    -   model::Tuple = tuple of (coefficients, terms) where coeffcients is a 1xn vector of polynomial coeffcients and terms is a nx2
    vector of the powers of the x and y variables in a 3d polynomial function.

	## Example
	GetActions(Rocket(), (130, 55, 85, 0.003), PolyModel)
	"""
    function OptimalGen(rocket::Rocket, s, model)
        experimentStates_ = []
        
        for ExpState in GetActions(rocket, s)
            append!(experimentStates_, tuple(RocketSim.DragObjects.gen(rocket, ExpState)))
        end 

        experimentStates_ = convert(Array{NTuple{4, Float64}},experimentStates_)

        return BestState(experimentStates_, model)
    end


    """
		BlindGen(rocket, state)
	
    if the apogee_sim() of the current observed state is above target, it will choose the
    last available action (opening the airbrakes). If below target, it will choose
    the first returned action (closing the airbrakes).Returns tuple of next 
    simulated state and the action index it chooses
	---
	## Arguments
	-	a::Rocket = The rocket object
	-	s::Tuple{Float64, Float64, Float64, Float64} = the state tuple

	## Example
	BlindGen(Rocket(), (130, 55, 85, 0.003))
	"""
    function BlindGen(rocket::Rocket, s)
        ObservedState = s .+ rand.(rocket.SensorNoise)

        apogee = apogee_sim(rocket, ObservedState, noise=false)[1]
        actions = GetActions(rocket, s)
        
        if apogee > rocket.env.target
            return (RocketSim.DragObjects.gen(rocket, last(actions)), 3)
        elseif apogee < rocket.env.target
            return (RocketSim.DragObjects.gen(rocket, actions[1]), 1)
        else
            return (RocketSim.DragObjects.gen(rocket, actions[2]), 2)
        end
    end


    """
		OptimalApogeeSim(rocket, hist=true)
	
    Runs the optimal surface model simulation. Not updated to include sample rates
	---
	## Arguments
	-	a::Rocket = The rocket object
	-	model::Tuple = tuple of (coefficients, terms) where coeffcients is a 1xn vector of polynomial coeffcients and terms is a nx2
    vector of the powers of the x and y variables in a 3d polynomial function.

	## Example
	OptimalApogeeSim(Rocket(), PolyModel)
	"""
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


    """
		BlindApogeeSim(rocket, history=true)
	
    Runs the simple above-below simulation
	---
	## Arguments
	-	a::Rocket = The rocket object
	-	history::boolean = setting to true will return an array of all simulation steps (default=true)

	## Example
	BlindGen(Rocket(), (130, 55, 85, 0.003))
	"""
    function BlindApogeeSim(a::Rocket; history=true)
        s = a.s_0
        
        observe = true
        NextObservation = 0.0
        LastAction = 2
        t = 0.0
        
        history ? StateHistory=[] : Nothing

        while true
            if observe && t >= a.DeploymentDelay
                s, LastAction = BlindGen(a, s)
                observe = false
                NextObservation = t + a.SampleRate
            else
                s = RocketSim.DragObjects.gen(a, GetActions(a, s)[LastAction], noise=false)
            end

            history && append!(StateHistory, tuple(s))
            s[3] < 0 && break

            t += a.dt
            if t >= NextObservation
                observe = true
            end
        end

        
        history && return StateHistory
        return s
    end
end