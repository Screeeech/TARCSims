using MAT
using JLD
using DataFrames

possible_states_file = "savedvars/possible_states.jld"
optimal_states_file = "savedvars/optimal_states.jld"

possible_states = load(possible_states_file, "possible_states")
bounds = vcat(load(possible_states_file, "lower_bound"), load(states_file, "upper_bound"))
lower_bound = load(possible_states_file, "lower_bound")
upper_bound = load(possible_states_file, "upper_bound")
optimal_states = load(optimal_states_file, "optimal_states")

# Matlab can't handle tuples so this converts them into a multi-dimensional array
bounds = [[i[1], i[2], i[3]] for i in bounds]
possible_states = [[i[1], i[2], i[3]] for i in possible_states]
lower_bound = [[i[1], i[2], i[3]] for i in lower_bound]
upper_bound = [[i[1], i[2], i[3]] for i in upper_bound]
optimal_states = [[i[1], i[2], i[3]] for i in eachrow(optimal_states)]


file = matopen("savedvars/matfile.mat", "w")
write(file, "bounds", bounds)
write(file, "possible_states", possible_states)
write(file, "lower_bound", lower_bound)
write(file, "upper_bound", upper_bound)
write(file, "optimal_states", optimal_states)
close(file)
