module RocketSim
    export Environment
    export Rocket
    export PointProjectileCheck
    
    export apogee_sim

    include("./DragObjects.jl")
    using .DragObjects
    using Parameters
    using LinearAlgebra
    using Distributions
    using ProgressMeter
    using DataFrames
    using JLD


    """
		Environment(g = 9.81, target = 254.508, flex = 7)
	
	The envrionment object defining envrionmental and competition parameters
	---
	## Parameters
	-	g::Float64 = acceleration due to gravity (default 9.81)
	-	target::Float64 = target apogee of rocket (default 254.508)
	-	flex::Float64 = allowed deviation from target (default 7)

	## Example
	Environment(g=9.804)
	"""
	@with_kw struct Environment <: Conditions
		g::Float64 = 9.81
		target::Float64 = 254.508
		flex::Float64 = 7
		# air_density = (pressure, temp) -> pressure/(287.058 * temp) 
	end


    """
		Rocket(env = Environment(g = 9.804), mass = 0.54122, dt = 0.001)
	
	The rocket object that defines the flight state as well as envrionmental conditions
	---
	## Parameters
	-	env::Conditions = current conditions (default Environment(g = 9.804))
	-	mass::Float64 = mass of rocket in kg (default 0.54122)
	-	dt::Float64 = time step (default 0.001)
    -   SampleRate::Float64 = how often the rocket can sense data in seconds
    -   SensorNoise::Tuple = Tuple of noise distributions for OBSERVATIONS which desn't affect true state tuple
    -   noise::Tuple = Tuple of noise distributions for each variable in the state tuple
    -   DeploymentDelay::Float64 = The number of seconds the rocket must wait after simulation starts to make actions
    -   DeploymentRate::Float64 = Amount it can change deployment in one second
    -   s_0::Tuple{Float64, Float64, Float64, Float64} = the intial of the state tuple of the rocket
                                                            in the form of (height-m, speed-m/s, pitch-radians, deployment∈[0,1])
                                                            

	## Example
	Rocket(s_0 = (132.68, 68.77, 81.686 * pi / 180, 0), env=Environment(g=9.804))
	"""
    @with_kw struct Rocket <: AeroProjectile
        env::Conditions = Environment(g = 9.804)
        mass::Float64 = 0.54122
        dt::Float64 = 0.001

        SampleRate::Float64 = 0.01
        SensorNoise::Tuple = (Normal(0, 0), Normal(0, 0), Normal(0, 0), Normal(0, 0))
        noise::Tuple = (Normal(0, 0), Normal(0, 0), Normal(0, 0), Normal(0, 0))

        DeploymentDelay::Float64 = 0.0
        DeploymentRate::Float64 = 1.0

        # s_0 = (height, velocity_mag, pitch, deployment)
        s_0::Tuple{Float64, Float64, Float64, Float64}
    end


    function DragObjects.drag(s)
        # Rocket C_f
        # According to OpenRocket
        # C_fr = [0.07963977623157216, -0.005528027105058144, 0.001112250881374065]
        # According to Ansys
        # C_fr = [-0.011249999999999311, 0.004624999999999964, 0.0007847222222222226]
        # Average of both
        C_fr = 0.5 * ([0.07963977623157216, -0.005528027105058144, 0.001112250881374065] + 
                 [-0.011249999999999311, 0.004624999999999964, 0.0007847222222222226])

        # Airbrake C_f when it is completely open
        # C_fb = [0.03625000000000833, -0.012125000000000469, 0.004354166666666671]
        # Airbrake C_f with the sinusoidal model
        C_fb = [0.00735901, -0.0129224]
        b_b = 0.006939280891655768

        rocket_drag = -1 * dot(C_fr, [1, s[2], s[2]^2]) # - rocket drag
        # brake_drag = -1 * dot(C_fb, [0, s[2], s[2]^2]) * s[4] # - airbrake drag when it's fully open

        # This is the brake drag function based on the sinusoidal model. The input angle must be in degrees
        # and the sin function must still be calculating in radians.
        brake_drag = -1 * dot(C_fb, [s[2]^2, s[2]]) * sin(b_b*s[4]*90)

        # returns force vector opposing velocity with magnitude of rocket and airbrake drag
        return (rocket_drag+brake_drag) * [cos(s[3]), sin(s[3])]
    end


    function DragObjects.gen(rocket::Rocket, s; noise=true)
        h, v, θ, d = s

        a = (DragObjects.drag(s)/rocket.mass) + [0,-rocket.env.g]
        
        v_ = [v*cos(θ), v*sin(θ)] + a*rocket.dt
        θ_ = atan(v_[2]/v_[1])
        h_ = v_[2] * rocket.dt + h
        d_ = d

        if noise
            h_ += rand(rocket.noise[1])
            v_ += rand(rocket.noise[2], 2)
            θ_ += rand(rocket.noise[3])
            d_ += rand(rocket.noise[4])
        end

        return (h_, norm(v_), θ_, d_)
    end


    function PointProjectileCheck(rocket::Rocket, s)
        max_height = s[1] + (s[2]*sin(s[3]))^2 / (2*rocket.env.g)

        if max_height < rocket.env.target - rocket.env.flex
            # The max height achieved by a point mass in place
            # of the rocket is less than target - flex
            return false
        else
            return true
        end
    end

    
    function SimulationTable(rocket::Rocket)
        s = rocket.s_0

        t = 0.0
        df = DataFrame(t=Float64[], h=Float64[])
        push!(df, (t, s[1]))

        while s[3] >= 0
            s = DragObjects.gen(rocket, s)
            t += rocket.dt
            push!(df, (t, s[1]))
        end

        return df
    end


    function SimulationTable(rocket::Rocket, s)
        t = 0.0
        df = DataFrame(t=Float64[], h=Float64[], v=Float64[], θ=Float64[], d=Float64[])
        push!(df, (t, s...))

        while s[3] >= 0
            s = DragObjects.gen(rocket, s)
            t += rocket.dt
            push!(df, (t, s[1]))
        end

        return df
    end


    
    #=
    NoiseTuple = (Normal(0, 0.003), Normal(0, 0.002), Normal(0, 0.0015), Normal(0, 0))
    LowNoiseTuple = (Normal(0, 0.0015), Normal(0, 0.001), Normal(0, 0.00075), Normal(0, 0))
    rocket = Rocket(s_0 = (132.68, 68.77, 81.686 * pi / 180, 0), noise=NoiseTuple, env=Environment(g=9.804))
    rocket1 = Rocket(s_0 = (118.45, 63.457, 72.509 * pi / 180, 0), env=Environment(g=9.804), mass=0.633, noise=LowNoiseTuple)
    
    for i in 1:10
        println(apogee_sim(rocket1))
    end
    =#
    
end


