### A Pluto.jl notebook ###
# v0.17.7

using Markdown
using InteractiveUtils

# ╔═╡ 22100670-5a28-11ec-076f-9d513946f219
begin
	using Pkg
	Pkg.activate(".")
end

# ╔═╡ 251168f6-75f6-4708-b8ce-729014f389cb
begin
	using Parameters
	using LinearAlgebra
	# using DifferentialEquations
	using Distributions
	using Plots
	using XLSX
	using DataFrames
	using BenchmarkTools
end

# ╔═╡ a57b9283-f3c4-4443-9e5c-174529107d06
begin
	# Pluto is dumb; it can't import stuff properly
	# With this cell, you still need to say RocketSim.SomeFunction()
	# Outside of pluto, you can simply call SomeFunction()
	
	include("./RocketSim.jl")
	using .RocketSim
end

# ╔═╡ 24b07462-045e-428d-bc0e-fe40913cc03c
NoiseTuple = (Normal(0, 0.003), Normal(0, 0.002), Normal(0, 0.0015), Normal(0, 0));

# ╔═╡ b4e6f4d4-4604-4ded-b8e2-70f11d2e86d3
rocket = RocketSim.Rocket(s_0 = (132.68, 68.77, 81.686 * pi / 180, 0), env=RocketSim.Environment(g=9.804), SampleRate=0.07, noise=NoiseTuple)

# ╔═╡ f7c61957-e236-45b9-8ad3-c7193be08b7f
PerfectRocket = RocketSim.Rocket(s_0 = (132.68, 68.77, 81.686 * pi / 180, 0), env=RocketSim.Environment(g=9.804), SampleRate=0.07);

# ╔═╡ d6b108c6-2f79-473d-914c-8d071a467a6b
RocketSim.apogee_sim(rocket)

# ╔═╡ 90e289b5-9c36-473e-8dc8-21d1edbc5cf3
RocketSim.apogee_sim(PerfectRocket)

# ╔═╡ 439848db-74f1-4405-adeb-9de73477a52b
@benchmark (RocketSim.apogee_sim(rocket))

# ╔═╡ 3b52d01b-259c-4c99-8f35-484cbf0c3e30
@benchmark (RocketSim.apogee_sim(PerfectRocket))

# ╔═╡ 778e2da1-dea7-4ad1-a9dc-8acc07ba1163
md"""
I think distributions.jl is slowing us down by a lot. It's great for running simulations to test out the effectivness of the airbrakes and decision making, but it is completely unecessary to have on the rocket.
"""

# ╔═╡ Cell order:
# ╠═22100670-5a28-11ec-076f-9d513946f219
# ╠═251168f6-75f6-4708-b8ce-729014f389cb
# ╠═a57b9283-f3c4-4443-9e5c-174529107d06
# ╠═24b07462-045e-428d-bc0e-fe40913cc03c
# ╠═b4e6f4d4-4604-4ded-b8e2-70f11d2e86d3
# ╠═f7c61957-e236-45b9-8ad3-c7193be08b7f
# ╠═d6b108c6-2f79-473d-914c-8d071a467a6b
# ╠═90e289b5-9c36-473e-8dc8-21d1edbc5cf3
# ╠═439848db-74f1-4405-adeb-9de73477a52b
# ╠═3b52d01b-259c-4c99-8f35-484cbf0c3e30
# ╟─778e2da1-dea7-4ad1-a9dc-8acc07ba1163
