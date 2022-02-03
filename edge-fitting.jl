### A Pluto.jl notebook ###
# v0.17.3

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

# ╔═╡ b50b922e-5e03-11ec-0543-c3dd8f2bfa33
begin
	using Pkg
	Pkg.activate(".")
end

# ╔═╡ 33cb2308-5f49-40c6-a643-7101700a1b6a
begin
	using Plots
	using GLM
	using DataFrames
	using ForwardDiff
	using Roots
	using JLD
	using PlutoUI
end

# ╔═╡ f989453f-c9a5-48ef-8fcf-c4e40820e93c
begin
	lower_bound = DataFrame(load("possible_states.jld", "lower_bound"))
	upper_bound = DataFrame(load("possible_states.jld", "upper_bound"))
	rename!(lower_bound, ["height", "velocity", "angle"])
	rename!(upper_bound, ["height", "velocity", "angle"])
end;

# ╔═╡ 87fa6fe3-36dd-4332-9898-a4a166bf1b3c
upper_bound;

# ╔═╡ 3c89ba2b-bc5f-451b-92ee-3586b6224fdb
begin
	scatter(lower_bound[!, "height"], lower_bound[!, "velocity"], lower_bound[!, "angle"], xlabel="height", ylabel="velocity", zlabel="angle")
	
	scatter!(upper_bound[!, "height"], upper_bound[!, "velocity"], upper_bound[!, "angle"], xlabel="height", ylabel="velocity", zlabel="angle")
end

# ╔═╡ 8f1519c3-8305-4c8c-9aa1-8b349cc7efa2
function get_slice(df, axis, value)
	slice = []
	for i in 1:size(df)[1]
		if df[i,axis] == value
			append!(slice, tuple(tuple([df[i, j] for j in 1:3]...)))
		end
	end
	return rename(DataFrame(slice), ["height", "velocity", "angle"])
end

# ╔═╡ 3147738c-8d1b-4138-9f2d-46dc388e7f14
function normal_line(bound_f, value)
	slope = -1/ForwardDiff.derivative(bound_f, value)
	return x -> slope*(x-value)+bound_f(value)
end

# ╔═╡ d156d6ee-2f0e-44a8-bd72-bdd203ffde31
function midslope_point(lbound_f, ubound_f, value)
	x1, y1 = (value, lbound_f(value))
	
	x2 = fzero(x -> ubound_f(x) - normal_line(lbound_f, x1)(x), 200)
	y2 = ubound_f(x2)

	return tuple((x2+x1)/2, (y2+y1)/2)
end

# ╔═╡ 0a6595bd-f3c4-4c34-88f5-03dd0e35f286
function midslope_point(lbound_f, ubound_f, values::AbstractArray)
	points::Vector{Tuple{Float64, Float64}} = []
	for value in values
		append!(points, tuple(midslope_point(lbound_f, ubound_f, value)))
	end
	return points
end

# ╔═╡ 50ef6896-fca4-4b59-8d31-149c6c0c1897
@bind slice_n Slider(0:90, show_value=true, default=80)

# ╔═╡ 02e16c1f-89d8-4629-b1ab-a8023ed92d42
lower_slice =get_slice(lower_bound, 3, slice_n);

# ╔═╡ ebe92651-63c0-4573-b377-9c718688575c
upper_slice =get_slice(upper_bound, 3, slice_n);

# ╔═╡ 00fe651b-b7a4-4669-b29d-ce1d1c7457be
function d15_fit(bound)
	ols = lm(@formula(velocity^1.5 ~ 1 + height), bound)
	y_int, m = coef(ols)
	return x -> (y_int + m*x)^(2//3)
end

# ╔═╡ 57219f86-5915-49b4-9356-1c78f4d6b2c5
function logd47_fit(bound)
	ols = lm(@formula(log(velocity)^4.7 ~ 1 + height), bound)
	y_int, m = coef(ols)
	return x -> exp((y_int + m*x)^(1/4.7))
end

# ╔═╡ 52c748bd-99a4-4220-a3b6-8ab2d819da23
begin
	scatter(lower_slice[!, "height"], lower_slice[!, "velocity"], xlabel="height", ylabel="velocity")
	scatter!(upper_slice[!, "height"], upper_slice[!, "velocity"])
	
	plot!(logd47_fit(upper_slice), extrema(upper_slice[!, "height"]) .+ (0, 50) ...)
	plot!(d15_fit(lower_slice), extrema(lower_slice[!, "height"])...)

	scatter!((262, 0))

	#scatter!(midypoint(d15_fit(lower_slice), logd38_fit(upper_slice), 17:76, extrema(lower_slice[!, "height"]), extrema(upper_slice[!, "height"])))

	scatter!(midslope_point(d15_fit(lower_slice), logd47_fit(upper_slice), 130:247))
	plot!(x -> 16)
end

# ╔═╡ e11b3478-4fec-4cdf-9438-404b13a90d99
extrema(lower_slice[!, "height"])

# ╔═╡ 64313309-7a03-4b3d-9e55-6372fb5c1340
extrema(upper_slice[!, "height"])

# ╔═╡ 931ea9a7-e3f2-4044-913e-dd02423c46bc
fzero(x -> d15_fit(lower_slice)(x) - 20, 150)

# ╔═╡ afccb9a6-a4f6-46a3-8fac-90bd1988558c
fzero(x -> logd47_fit(upper_slice)(x) - 76, 150)

# ╔═╡ 7f9dcd2d-426b-408e-969c-3ec4933c9780
function midypoint(lbound_f, ubound_f, value, extremal, extremau)
	y1, y2 = (value, value)

	#x1 = find_zero(x -> lbound_f(x) - value, (100, 249))
	#x2 = find_zero(x -> ubound_f(x) - value, (180,255))
	
	#x1 = find_zero(x -> lbound_f(x) - value, extremal .* (0.9,0.99))
	#x2 = find_zero(x -> ubound_f(x) - value, extremau .* (1,0.99))

	x1 = fzero(x -> lbound_f(x) - value, 150)
	x2 = fzero(x -> ubound_f(x) - value, 200)

	return tuple((x2+x1)/2, (y2+y1)/2)
end

# ╔═╡ 43c530cb-99ad-4191-bd7a-c0ccaab93712
function midypoint(lbound_f, ubound_f, values::AbstractArray, extremal, extremau)
	points::Vector{Tuple{Float64, Float64}} = []
	for value in values
		append!(points, tuple(midypoint(lbound_f, ubound_f, value, extremal,
				extremau)))
	end
	return points
end

# ╔═╡ fd468b4b-6674-4741-8741-45e09b16a450
function good_slices(upper, lower, axis, range)
	good_slices = []
	bad_slices = []
	
	for i in range
		if size(get_slice(lower, axis, i))[1] >= 10 && size(get_slice(upper, axis, i))[1] >= 15 && abs(extrema(get_slice(lower, axis, i)[!, "height"])[2]-extrema(get_slice(lower, axis, i)[!, "height"])[1]) > 8 && abs(extrema(get_slice(upper, axis, i)[!, "height"])[2]-extrema(get_slice(upper, axis, i)[!, "height"])[1]) > 8
			
			append!(good_slices, i)
		else
			append!(bad_slices, i)
		end
	end

	return good_slices
end		

# ╔═╡ cda54ef8-4fef-4071-ad60-26c436669de6
function save_slices(upper, lower, axis, range)
	slices = good_slices(upper_bound, lower_bound, axis, range)

	for i in slices
		lower_s = get_slice(lower, axis, i)
		upper_s = get_slice(upper, axis, i)

		scatter(lower_s[!, "height"], lower_s[!, "velocity"])
		scatter!(upper_s[!, "height"], upper_s[!, "velocity"])
		
		plot!(logd47_fit(upper_s), extrema(upper_s[!, "height"]) .+ (0, 50) ...)
		plot!(d15_fit(lower_s), extrema(lower_s[!, "height"])...)

		#=
		try
			scatter!(midslope_point(d15_fit(lower_s), logd47_fit(upper_s), 130:245))
		catch end =#
	
		scatter!(midslope_point(d15_fit(lower_s), logd47_fit(upper_s), 130:249))
		plot!(x -> 16)
		
		savefig("slices/slice$i.png")
	end
end

# ╔═╡ 3f9b9959-4bbc-4389-866e-9320d903bfe2
function midslice(upper, lower, axis, range)
	slices = good_slices(upper_bound, lower_bound, axis, range)

	points = DataFrame()
	points.height = []
	points.velocity = []
	points.angle = []

	for i in slices
		lower_s = get_slice(lower, axis, i)
		upper_s = get_slice(upper, axis, i)
	
		for point in midslope_point(d15_fit(lower_s), logd47_fit(upper_s), 130:249)
			push!(points, [point..., i])
		end
	end

	return points
end

# ╔═╡ 772456cb-6e8c-4334-b102-1743a9f7692a
save_slices(upper_bound, lower_bound, 3, 10:90)

# ╔═╡ b73ec076-a0dd-41d3-b796-ed5b47e817c8
optim_slice = midslice(upper_bound, lower_bound, 3, 10:90);

# ╔═╡ 80e967b2-45dd-4cca-b1fb-a666f7fc941e
begin
	scatter(lower_bound[!, "height"], lower_bound[!, "velocity"], lower_bound[!, "angle"], xlabel="height", ylabel="velocity", zlabel="angle", markersize=1)
	
	scatter!(upper_bound[!, "height"], upper_bound[!, "velocity"], upper_bound[!, "angle"], xlabel="height", ylabel="velocity", zlabel="angle", markersize=1)

	scatter!(optim_slice[!, "height"], optim_slice[!, "velocity"], optim_slice[!, "angle"], xlabel="height", ylabel="velocity", zlabel="angle")
end

# ╔═╡ 4a5b018a-1b61-474f-a7dc-f1ebb9564359
save("optimal_states.jld", "optimal_states", optim_slice)

# ╔═╡ Cell order:
# ╟─b50b922e-5e03-11ec-0543-c3dd8f2bfa33
# ╟─33cb2308-5f49-40c6-a643-7101700a1b6a
# ╟─f989453f-c9a5-48ef-8fcf-c4e40820e93c
# ╟─87fa6fe3-36dd-4332-9898-a4a166bf1b3c
# ╠═3c89ba2b-bc5f-451b-92ee-3586b6224fdb
# ╟─8f1519c3-8305-4c8c-9aa1-8b349cc7efa2
# ╟─3147738c-8d1b-4138-9f2d-46dc388e7f14
# ╠═d156d6ee-2f0e-44a8-bd72-bdd203ffde31
# ╟─0a6595bd-f3c4-4c34-88f5-03dd0e35f286
# ╟─50ef6896-fca4-4b59-8d31-149c6c0c1897
# ╠═02e16c1f-89d8-4629-b1ab-a8023ed92d42
# ╠═ebe92651-63c0-4573-b377-9c718688575c
# ╟─00fe651b-b7a4-4669-b29d-ce1d1c7457be
# ╠═57219f86-5915-49b4-9356-1c78f4d6b2c5
# ╠═52c748bd-99a4-4220-a3b6-8ab2d819da23
# ╠═e11b3478-4fec-4cdf-9438-404b13a90d99
# ╠═64313309-7a03-4b3d-9e55-6372fb5c1340
# ╠═931ea9a7-e3f2-4044-913e-dd02423c46bc
# ╠═afccb9a6-a4f6-46a3-8fac-90bd1988558c
# ╟─7f9dcd2d-426b-408e-969c-3ec4933c9780
# ╟─43c530cb-99ad-4191-bd7a-c0ccaab93712
# ╟─fd468b4b-6674-4741-8741-45e09b16a450
# ╠═cda54ef8-4fef-4071-ad60-26c436669de6
# ╠═3f9b9959-4bbc-4389-866e-9320d903bfe2
# ╠═772456cb-6e8c-4334-b102-1743a9f7692a
# ╠═b73ec076-a0dd-41d3-b796-ed5b47e817c8
# ╠═80e967b2-45dd-4cca-b1fb-a666f7fc941e
# ╠═4a5b018a-1b61-474f-a7dc-f1ebb9564359
