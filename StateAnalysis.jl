module StateAnalysis

    export StateDiscrepancy
    export BestState


    """
		PolyModelOutput(model, input)
	
	Warning: Use PolyModelOutputs() instead.
	"""
    function PolyModelOutput(input, model)
        # Takes an input of [x,y]
        # Benchmarks show that it has the lower median and sometimes mean time,
        # but has a much bigger range with the maximum being ~100 μs

        sz = tuple(size(model[2])[1], 1)
        PointArray = [fill(input[1], sz) fill(input[2], sz)]

        terms = PointArray .^ model[2]
        return sum(transpose(model[1]) .* (terms[:, 1] .* terms[:, 2]))
    end


    """
		PolyModelOutputs(x, y, model)
	
	Outputs the z value of a poynomial function
	---
	## Arguments
	-	x = vector of x values
	-	y = vector of y values
	-	model = tuple (coefficients, terms) where coeffcients is a 1xn vector of polynomial coeffcients and terms is a nx2
    vector of the powers of the x and y variables in a 3d polynomial function.

	## Example
	    PolyModelOutputs([60, 50, 70], [30, 20, 40], PolyModel)
	"""
    function PolyModelOutputs(x, y, model)
        # Can take multiple inputs such as [x1, x2, x3] and [y1,y2,y3]
        # to give [z1, z2, z3]. Benchmarks show a consistent and fast
        # computation times of median ~1.180 μs

        sz = size(model[2])
        return sum(transpose(model[1])[i] .* x.^model[2][i, 1] .* y.^model[2][i, 2] for i in 1:sz[1])
    end


    """
		BestState(states, model)
	
	returns the state with the lowest discrepancy from the inputted model
	---
	## Arguments
	-	states = *vector* of state *tuples* of 4 variables
	-	model = tuple (coefficients, terms) where coeffcients is a 1xn vector of polynomial coeffcients and terms is a nx2
    vector of the powers of the x and y variables in a 3d polynomial function.

	## Example
	    BestState([(130, 65, 0.45), (130, 65, 0.55), (130, 65, 0.65)])
	"""
    function BestState(states, model)
        StatesArray = [states[i][j] for i in 1:length(states), j in 1:4]

        scores = StateDiscrepancy(StatesArray, model)
        return tuple(states[findmin(scores)[2]]...)
    end


    """
		StateDiscrepancy(s, model)
	
	Returns the discrepancy between a given state and a 3d surface which should be a best fit of the optimal states
	---
	## Arguments
	-	s = nx4 array of states such as [height velocity pitch deployment;...] 
	-	model = tuple (coefficients, terms) where coeffcients is a 1xn vector of polynomial coeffcients and terms is a nx2
    vector of the powers of the x and y variables in a 3d polynomial function.

	## Example
	    StateDiscrepancy([60 30 220; 50 20 240; 70 40 200], PolyModel)
	"""
    StateDiscrepancy(s, model) = abs.(PolyModelOutputs(s[:, 2], s[:, 3] * 180/pi, model) - s[:, 1])

    # println(PolyModelOutputs([60, 50, 70], [30, 20, 40]))
    # println(findmin(StateDiscrepancy([60 30 220; 50 20 240; 70 40 200])))
end

