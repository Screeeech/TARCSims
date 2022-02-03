### A Pluto.jl notebook ###
# v0.17.3

using Markdown
using InteractiveUtils

# ╔═╡ 1933f81e-5ddb-11ec-27d4-e162b3bae4de
begin
	using Pkg
	Pkg.activate(".")
end

# ╔═╡ 495aa676-5b0f-4cb8-8d8a-197843b0ea48
begin
	using Plots
	using JLD
	using DataFrames
end

# ╔═╡ e3071b77-f5d1-4c79-962c-4a4ef289f8f1
possible_states = load("possible_states.jld", "possible_states")

# ╔═╡ 320e0671-05c4-4c9f-b567-a6998f585019
upper_bound = load("possible_states.jld", "upper_bound");

# ╔═╡ 299f3fa3-d2d8-47fc-a44b-095b95c84f1f
lower_bound = load("possible_states.jld", "lower_bound");

# ╔═╡ 71256734-f7bf-4128-9228-c85cf3b94b19
bounds = DataFrame(vcat(upper_bound));

# ╔═╡ 120425f6-d816-430f-803d-ee88837856f4
df = DataFrame(possible_states);

# ╔═╡ 4d14ad15-16dd-4cb5-a030-00ba1ac0900a
rename!(df, ["height", "velocity", "angle"]);

# ╔═╡ ffc79373-9d36-4061-8c45-f52209e70965
rename!(bounds, ["height", "velocity", "angle"]);

# ╔═╡ f38e1904-31fb-408d-b797-5da6202f6fe0
scatter(df[!, "height"], df[!, "angle"], df[!, "velocity"], xlabel="height", ylabel="angle", zlabel="velocity", markerstrokewidth = 0.7)

# ╔═╡ d00a8fda-466d-4ae7-a5b2-3153135a243b
scatter(bounds[!, "height"], bounds[!, "angle"], bounds[!, "velocity"], xlabel="height", ylabel="angle", zlabel="velocity", markerstrokewidth = 0.7)

# ╔═╡ Cell order:
# ╠═1933f81e-5ddb-11ec-27d4-e162b3bae4de
# ╠═495aa676-5b0f-4cb8-8d8a-197843b0ea48
# ╠═e3071b77-f5d1-4c79-962c-4a4ef289f8f1
# ╠═320e0671-05c4-4c9f-b567-a6998f585019
# ╠═299f3fa3-d2d8-47fc-a44b-095b95c84f1f
# ╠═71256734-f7bf-4128-9228-c85cf3b94b19
# ╠═120425f6-d816-430f-803d-ee88837856f4
# ╠═4d14ad15-16dd-4cb5-a030-00ba1ac0900a
# ╠═ffc79373-9d36-4061-8c45-f52209e70965
# ╠═f38e1904-31fb-408d-b797-5da6202f6fe0
# ╠═d00a8fda-466d-4ae7-a5b2-3153135a243b
