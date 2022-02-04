# File Structure

## Julia Files
- Arc.jl
  - Active rocket control simulation module
- DragObjects.jl
    - Defines functions and types used for the rocket simulation and analysis (well documented)
- edge-fitting.jl
    - Looks at boundary states for each slice of angle, draws best fit lines, and plots points that
    are in the middle of both lines (which are approximated to be optimal states)
    - Outputs all good slices, best fit lines, and optimal states in the slices folder
- jl-to-mat.jl
    - converts possible, boundary, and optimal states to a matlab save file for WaterspoutPlot.mlx
- notebook.jl
    - Just to mess around
- RocketSim.jl
    - Conatins rocket simulation and state space analysis code
- StateDiscrepancy.jl
    - Finds discrepancy between the optimal surface and a state to score states
- waterspout-plot.jl
    - Plots waterspout

## Matlab files
- WaterspoutStateSpace.jl
  - Plots analyzed state space of optimal sates and creates best fit polynomial model for them.

## savedvars
- matfile.mat
    - contains all possible states, boundary states, and optimal states
- optimal_states.jld
    - contains all optimal states found in edge-fitting.jl
- optimal_surface.mat
    - contains polynomial model terms and coefficients that best fit optimal states found in WaterSpout.mlx
- possible_states.jld
    - contains all states that give the possibilty of the rocket ending up at apogee

## Slices
Contains all slices found by edge-fitting.jl
