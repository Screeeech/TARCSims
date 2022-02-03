### A Pluto.jl notebook ###
# v0.17.1

using Markdown
using InteractiveUtils

# ╔═╡ cce01cb5-960f-4a98-81d6-303c99293b1b
begin
	using Pkg
	Pkg.activate(".")
	Pkg.instantiate()
end

# ╔═╡ 5acc9cdb-f6d1-4d99-8e66-bb070d928476
begin
	using Plots
	using GLM
	using DataFrames
	using ForwardDiff
	using Roots
	# using DifferentialEquations
end

# ╔═╡ c40cccc8-ab37-43bf-a8d7-dd54ad1df559
# Pkg.add("DifferentialEquations")

# ╔═╡ 8a7bdbc2-bbbe-4b67-b800-ebd785a0b628
turning_point(x, ẋ, ẍ) = x - ẋ^2/ẍ + ẋ^2/(2*ẍ)

# ╔═╡ f02cedd6-2ab0-4924-af62-8ed90e2511f0
function f(x, ẋ)
    dist_reward = 1 - (abs(80-x)/80.)^0.4
	vel_discount = (1 - ẋ/28 + 0.1)^(1/max(abs(80-x)/80., 0.1))
	
	impossible_discount = 1
	target_discount = 0
	edge_bonus = 0
	
	max_distance = turning_point(x, ẋ, -2)
	min_distance = turning_point(x, ẋ, -5)

	if max_distance < 77 || min_distance > 83
		# In this case, it is impossible to end up between 83 and 77
		impossible_discount = -1
	else
		if max_distance < 78 || min_distance > 82
			# Too close to the edge of the curve
			edge_bonus = -0.5
		end
		# Discount increases as projected distance strays from 80
		target_discount = ((abs(160 - (max_distance + min_distance)))/160)^0.4
	end

	return impossible_discount + edge_bonus - target_discount
end

# ╔═╡ e99b3cdb-b7bc-4d26-a744-5e9856a24516
function g(x, ẋ)

	dist_reward = 1 - (abs(80-x)/80.)^0.4
	if 80-x < 0
		dist_reward = dist_reward*-1
	end
    
	vel_discount = (1 - max(ẋ/28, 0.1))^(1/max((80-x)/80., 0.1))

	return dist_reward * vel_discount
end

# ╔═╡ 869f2ff7-b63e-4335-b12d-a1f02e190cc9
function get_edges(x, ẋ)
	edge_points::Vector{Tuple{Float64, Float64}} = []

	for pos in x
		for vel in ẋ
			max_distance = turning_point(pos, vel, -2)
			min_distance = turning_point(pos, vel, -5)

			if !(max_distance < 77 || min_distance > 83)
				if max_distance < 78 || min_distance > 82
					# Too close to the edge of the curve
					append!(edge_points, tuple((Float64(pos), Float64(vel))))
				end
			end
		end
	end

	return edge_points
end;

# ╔═╡ 1920d746-0690-44aa-b50c-20b83d170466
function get_lower_edges(x, ẋ)
	edge_points::Vector{Tuple{Float64, Float64}} = []

	for pos in x
		for vel in ẋ
			max_distance = turning_point(pos, vel, -2)

			if !(max_distance < 77)
				if max_distance < 78
					# Too close to the edge of the curve
					append!(edge_points, tuple((Float64(pos), Float64(vel))))
				end
			end
		end
	end

	return edge_points
end;

# ╔═╡ 8e684705-e1a3-4663-aa62-3ee60f4ac588
function get_upper_edges(x, ẋ)
	edge_points::Vector{Tuple{Float64, Float64}} = []

	for pos in x
		for vel in ẋ
			min_distance = turning_point(pos, vel, -5)

			if !(min_distance > 83)
				if min_distance > 82
					# Too close to the edge of the curve
					append!(edge_points, tuple((Float64(pos), Float64(vel))))
				end
			end
		end
	end

	return edge_points
end;

# ╔═╡ 7beab493-cd10-4529-9e76-7e46639fe852
begin
	x = 0:0.1:120
	y = 0:0.1:28
	heatmap(x, y, f, c = :thermal, xlabel="position", ylabel="momentum")
end

# ╔═╡ bff2118b-4c4d-4743-b154-6887205b9fa5
get_upper_edges(x,y);

# ╔═╡ 92c03484-0976-40f9-87d2-44b77e18d1b9
begin
	upper_bound = DataFrame(get_upper_edges(x,y))
	rename!(upper_bound, Dict(:1 => "position", :2 => "velocity"))
end;

# ╔═╡ 0d6163c2-7722-40d9-a567-46c70c6a499c
begin
	lower_bound = DataFrame(get_lower_edges(x,y))
	rename!(lower_bound, Dict(:1 => "position", :2 => "velocity"))
end;

# ╔═╡ b0306639-fc00-4f6e-b6f1-b1f178ed0525
# linear regression
ols = lm(@formula(velocity^2 ~ 1 + position), lower_bound)

# ╔═╡ ce4463cd-83dd-471a-a018-c49326c2be79
function sqrt_fit(bound)
	ols = lm(@formula(velocity^2 ~ 1 + position), bound)
	y_int, m = coef(ols)
	return x -> sqrt(y_int + m*x)
end

# ╔═╡ 9daee023-b430-43ce-b7be-2e3ab05a12e2
r2(ols)

# ╔═╡ 6e5873a2-dac4-4b82-94d8-8c54ba1471c7
begin
	lower_f = sqrt_fit(lower_bound)
	upper_f = sqrt_fit(upper_bound)
end

# ╔═╡ e4067dd6-dc19-4d2b-98bd-3b7d7b466e76
find_zero(x -> upper_f(x)-15, (0, 65))

# ╔═╡ d0f3fc5b-f95f-494b-954b-7c839ad9f703
x_sample = 0:0.1:77

# ╔═╡ 04fd49c1-733c-41f4-a7ab-c0e25b777923
function tangent_line(bound_f, value)
	slope = ForwardDiff.derivative(bound_f, value)
	return x -> slope*(x-value)+bound_f(value)
end

# ╔═╡ 0ed728e4-1a8c-406f-9b5e-a5670ea747b0
function normal_line(bound_f, value)
	slope = -1/ForwardDiff.derivative(bound_f, value)
	return x -> slope*(x-value)+bound_f(value)
end

# ╔═╡ d3ddf984-9be0-4fd1-8f3f-03d25833813d
function midslope_point(lbound_f, ubound_f, value)
	x1, y1 = (value, lbound_f(value))
	
	x2 = find_zero(x ->ubound_f(x) - normal_line(lbound_f, x1)(x), (0, 82.5))
	y2 = ubound_f(x2)

	return tuple((x2+x1)/2, (y2+y1)/2)
end

# ╔═╡ 09b5b58e-3a7f-4a6c-afdd-81e9aec1883f
function midslope_point(lbound_f, ubound_f, values::AbstractArray)
	points::Vector{Tuple{Float64, Float64}} = []
	for value in values
		append!(points, tuple(midslope_point(lbound_f, ubound_f, value)))
	end
	return points
end

# ╔═╡ dcfc6e1e-13eb-43fa-83f7-5d8c793843c5
begin
	plot(lower_bound[!,"position"], lower_bound[!,"velocity"], markersize=0, xlabel="position", ylabel="velocity")
	
	plot!(upper_bound[!,"position"], upper_bound[!,"velocity"], markersize=0, xlabel="position", ylabel="velocity")

	plot!(lower_f, extrema(lower_bound[!,"position"])..., linewidth=3)
	plot!(upper_f, extrema(upper_bound[!,"position"])..., linewidth=3)
	# plot!(normal_line(upper_f, 82), 72, 79)
	scatter!(midslope_point(lower_f, upper_f, x_sample), markersize=0)
end

# ╔═╡ b90dc913-75f5-43ad-b79e-6c898692ddbb
heatmap(x, y,(x, ẋ) -> turning_point(x, ẋ, -5), c = :thermal, xlabel="position", ylabel="velocity", title="min_distance");

# ╔═╡ Cell order:
# ╠═cce01cb5-960f-4a98-81d6-303c99293b1b
# ╠═c40cccc8-ab37-43bf-a8d7-dd54ad1df559
# ╠═5acc9cdb-f6d1-4d99-8e66-bb070d928476
# ╟─8a7bdbc2-bbbe-4b67-b800-ebd785a0b628
# ╠═f02cedd6-2ab0-4924-af62-8ed90e2511f0
# ╟─e99b3cdb-b7bc-4d26-a744-5e9856a24516
# ╟─869f2ff7-b63e-4335-b12d-a1f02e190cc9
# ╟─1920d746-0690-44aa-b50c-20b83d170466
# ╟─8e684705-e1a3-4663-aa62-3ee60f4ac588
# ╠═7beab493-cd10-4529-9e76-7e46639fe852
# ╟─bff2118b-4c4d-4743-b154-6887205b9fa5
# ╠═92c03484-0976-40f9-87d2-44b77e18d1b9
# ╠═0d6163c2-7722-40d9-a567-46c70c6a499c
# ╟─b0306639-fc00-4f6e-b6f1-b1f178ed0525
# ╟─ce4463cd-83dd-471a-a018-c49326c2be79
# ╠═9daee023-b430-43ce-b7be-2e3ab05a12e2
# ╠═6e5873a2-dac4-4b82-94d8-8c54ba1471c7
# ╠═e4067dd6-dc19-4d2b-98bd-3b7d7b466e76
# ╠═d0f3fc5b-f95f-494b-954b-7c839ad9f703
# ╟─04fd49c1-733c-41f4-a7ab-c0e25b777923
# ╟─0ed728e4-1a8c-406f-9b5e-a5670ea747b0
# ╠═d3ddf984-9be0-4fd1-8f3f-03d25833813d
# ╠═09b5b58e-3a7f-4a6c-afdd-81e9aec1883f
# ╠═dcfc6e1e-13eb-43fa-83f7-5d8c793843c5
# ╟─b90dc913-75f5-43ad-b79e-6c898692ddbb
