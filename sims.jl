include("./Arc.jl")
using .Arc

using Distributions
using MAT


NoiseTuple = (Normal(0, 0.003), Normal(0, 0.002), Normal(0, 0.0015), Normal(0, 0))
SensorNoiseTuple = (Normal(0, 0.3), Normal(0, 0.5), Normal(0, 0.09), Normal(0, 0))

rocket = Rocket(s_0 = (132.68, 68.77, 81.686 * pi / 180, 0), 
                env=Environment(g=9.804), 
                SampleRate=0.1, 
                noise=NoiseTuple, 
                SensorNoise=SensorNoiseTuple, 
                DeploymentDelay=0.2,
                DeploymentRate=1
                )
rocketp = Rocket(s_0 = (132.68, 68.77, 81.686 * pi / 180, 0), env=Environment(g=9.804), SampleRate=0.07)
rocket2 = Rocket(s_0 = (123.06, 67.493, 61.82 * pi / 180, 0), env=Environment(g=9.804))
rocket3 = Rocket(s_0 = (120, 73.77, 75 * pi / 180, 0), env=Environment(g=9.804))

for i in 1:10
    println(BlindApogeeSim(rocket, history=false))
end


# Waterspout Analysis stuff
#=
vars = matread("savedvars/optimal_surface.mat")
Coef = get(vars, "Coefficients", 0)
ModelTerms = get(vars, "ModelTerms", 0)
PolyModel = tuple(Coef, ModelTerms)

for i in 1:10
    sim = OptimalApogeeSim(rocket, PolyModel)
    println(last(sim))
end
=#
