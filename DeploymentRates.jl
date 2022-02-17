### A Pluto.jl notebook ###
# v0.17.7

using Markdown
using InteractiveUtils

# This Pluto notebook uses @bind for interactivity. When running this notebook outside of Pluto, the following 'mock version' of @bind gives bound variables a default value (instead of an error).
macro bind(def, element)
    quote
        local iv = try Base.loaded_modules[Base.PkgId(Base.UUID("6e696c72-6542-2067-7265-42206c756150"), "AbstractPlutoDingetjes")].Bonds.initial_value catch; b -> missing; end
        local el = $(esc(element))
        global $(esc(def)) = Core.applicable(Base.get, el) ? Base.get(el) : iv(el)
        el
    end
end

# ╔═╡ b1dba920-863e-11ec-1f54-0f5e59d25c44
begin
	using Pkg
	Pkg.activate(".")
end

# ╔═╡ d1ef6205-6dac-4b4e-8e7e-0f70a52e2036
begin
	include("./Arc.jl")
	using .Arc
	using Distributions
	using Plots
	using PlutoUI
end

# ╔═╡ 25dd7a58-2479-47c9-943d-fa0e8b559b69
md"""
# Deployment Rates study

The purpose of this notebook is to determine how various airbrake deployment rates affect our ARC trajectories. The main goal is to find out how high the rate needs to be so that the rocket can get close to apogee.
"""

# ╔═╡ d132a170-46aa-49ea-9487-5c6bcc4fc1d9
md"""
The main factors in determining our flight path are environmental noise and the initial state, so they are initialized in their own cells.
"""

# ╔═╡ f8c0516b-b39f-4382-8ec0-588ca58c85b4
begin
	NoiseTuple = (Normal(0, 0.0015), Normal(0, 0.001), 
					Normal(0, 0.0008), Normal(0, 0))
	SensorNoiseTuple = (Normal(0, 0.3), Normal(0, 0.5), 
						Normal(0, 0.09), Normal(0, 0))
end;

# ╔═╡ f756454b-955b-47c9-bf4b-9b0c2bfb5528
# StateTuple = (122.71, 63.671, 89.984 * pi / 180, 0)
StateTuple = (118.45, 63.457, 75.509 * pi / 180, 0)

# ╔═╡ 1da13f3c-1716-4038-b097-e97a9c64472d
md"""
## Apogee v.s. deployment rate

Graphing the ARC apogee v.s. the deployment rate can give us a good idea of the minimum deployment rate needed to reach the target, but we need to keep in mind that this doesn't account for different starting angles of the rocket which could possibly demand higher deployment rates as the pitch increases.

To test if pitch affects the deployment rate's effectiveness, we can plot the apogees over multiple intital pitches
"""

# ╔═╡ 9f8d7367-0c93-4aea-902d-264bb072caa8
begin
	DepRates = 0:0.05:1
	pitches = (75:5:85) .* pi/180
	PitchHeights = Dict()
	
	for pitch in pitches
		h = [0 0]
		
		for rate in DepRates, i in 1:5
			rocket = Arc.Rocket(s_0 = (118.45, 63.457, pitch, 0), 
				                env=Arc.Environment(g=9.804), 
				                SampleRate=0.1, 
				                noise=NoiseTuple, 
				                SensorNoise=SensorNoiseTuple, 
				                DeploymentDelay=0,
				                DeploymentRate=rate,
								mass=0.633
					)
	
			apogee = Arc.BlindApogeeSim(rocket, history=false)[1]
			h = vcat(h, [apogee rate])
		end
		
		get!(PitchHeights, pitch, h[2:end, :])
	end
end

# ╔═╡ bcf5e65a-5b58-4600-b5ce-0d9f7bc2f00e
@bind DepRate Slider(0:0.05:1, show_value=true, default=15/90)

# ╔═╡ 8b8cf7ad-d190-4990-838d-ab2700919e8e
begin
p = plot()

	for pitch in keys(PitchHeights)
		h = get(PitchHeights, pitch, 0)
		scatter!(p, h[:, 2], h[:, 1], ylabel="apogee (m)", xlabel="deployment rate (×90°/s)", label="$(round(pitch*180/pi))°", markeralpha=0.6)
	end

	hline!([254.508], label="target")
	vline!([DepRate], label="$(round(DepRate*90))°/s")
	p
end

# ╔═╡ c6b812d0-2d3e-4b99-91e0-3b12f3ff92c6
md"""
It is clear that the pitch has a very dramatic effect on the ARC apogee even without environmental noise, so we need to make sure there is enough tilt after burnout. Other than that, it seems that even an 85° pitch will bring us within a decent range of 254.5m, so 18°/s looks like a good deployment rate for us.

When environmental noise was added, 85° pitch apogees sometimes went to ~263m, but 80° stayed fairly close to the target apogee.
"""

# ╔═╡ 1e7e2338-ddd0-4273-99ba-799dabe45f00
md"""
## Deployment Logic

In the blind simulation, deployment increases if predicted apogee (no noise) is too high and decreases if apogee is too low. Below is a comparison of how the predicted apogee and deployment change throughout the flight. From this, we can see that the majority of the change in apogee occurs within the first second where the speeds are the highest, so it is important to quickly deploy airbrakes and to be able to open them quickly at the beginning.
"""

# ╔═╡ 442155aa-f904-4ec3-aec3-87a2d0de2505
RocketTest = Arc.Rocket(s_0 = StateTuple, 
		                env=Arc.Environment(g=9.804), 
		                SampleRate=0.1, 
		                noise=NoiseTuple, 
		                SensorNoise=SensorNoiseTuple, 
		                DeploymentDelay=0,
		                DeploymentRate=(15/90),
						mass=0.633
);

# ╔═╡ 5204c2a9-acc0-4144-b76e-d1ad567f6325
BlindSim = Arc.BlindApogeeSim(RocketTest);

# ╔═╡ 67178c01-d553-456f-a48f-9db30fac7190
last(BlindSim)

# ╔═╡ 6c4fe269-cb6c-4444-8a1a-c226545e6101
Arc.apogee_sim(RocketTest)

# ╔═╡ e4ab6936-93e4-4040-b708-f69b85b06670
begin
	deps = [0 0]
	apogees = [0 0]
	for (i, state) in enumerate(BlindSim)
		global deps = vcat(deps, [i*RocketTest.dt state[4]])

		if i%50 == 0
			global apogees = vcat(apogees, 
						[i*RocketTest.dt Arc.apogee_sim(RocketTest, state, noise=false)[1]])
		end
	end
	depss = deps[2:end,:]
	apogees = apogees[2:end,:]
end;

# ╔═╡ 37f5f623-b976-4fa6-bc10-646305e82cc5
@bind t Slider(0:0.001:5, show_value=true)

# ╔═╡ 8de38173-7a16-41f4-87b5-6a16190bda39
begin
	DepPlot = plot()
	plot!(DepPlot, deps[:,1], deps[:,2], ylabel="deployment")
	vline!(DepPlot, [t])

	ApoPlot = plot()
	plot!(ApoPlot, apogees[:, 1], apogees[:, 2], ylabel="predicted apogee", xlabel="time")
	vline!(ApoPlot, [t])
	# plot!(ApoPlot, (x) -> 254.508)

	plot(DepPlot, ApoPlot, layout=(2,1), legend=false)
end

# ╔═╡ Cell order:
# ╟─b1dba920-863e-11ec-1f54-0f5e59d25c44
# ╟─d1ef6205-6dac-4b4e-8e7e-0f70a52e2036
# ╟─25dd7a58-2479-47c9-943d-fa0e8b559b69
# ╟─d132a170-46aa-49ea-9487-5c6bcc4fc1d9
# ╠═f8c0516b-b39f-4382-8ec0-588ca58c85b4
# ╠═f756454b-955b-47c9-bf4b-9b0c2bfb5528
# ╟─1da13f3c-1716-4038-b097-e97a9c64472d
# ╠═9f8d7367-0c93-4aea-902d-264bb072caa8
# ╠═bcf5e65a-5b58-4600-b5ce-0d9f7bc2f00e
# ╟─8b8cf7ad-d190-4990-838d-ab2700919e8e
# ╟─c6b812d0-2d3e-4b99-91e0-3b12f3ff92c6
# ╟─1e7e2338-ddd0-4273-99ba-799dabe45f00
# ╠═442155aa-f904-4ec3-aec3-87a2d0de2505
# ╠═5204c2a9-acc0-4144-b76e-d1ad567f6325
# ╠═67178c01-d553-456f-a48f-9db30fac7190
# ╠═6c4fe269-cb6c-4444-8a1a-c226545e6101
# ╟─e4ab6936-93e4-4040-b708-f69b85b06670
# ╠═37f5f623-b976-4fa6-bc10-646305e82cc5
# ╠═8de38173-7a16-41f4-87b5-6a16190bda39
