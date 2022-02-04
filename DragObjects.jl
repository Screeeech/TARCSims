module DragObjects
	export AeroProjectile
	export Conditions
	export apogee_sim
	export targeted_sim
	
	using Parameters
	using LinearAlgebra

	abstract type Projectile end
	abstract type AeroProjectile <: Projectile end
	
	abstract type Conditions end


	"""
		gen()
	User defined function that returns the next simulated state
	---

	## Example:
	```
	function DragObjects.gen(rocket::Rocket, s)
		h, v, θ, d = s
	
		a = (DragObjects.drag(s)/rocket.mass) + [0,-rocket.env.g]
		
		v_ = [v*cos(θ), v*sin(θ)] + a*rocket.dt
		θ_ = atan(v_[2]/v_[1])
		h_ = v_[2] * rocket.dt + h
	
		return (h_, norm(v_), θ_, d)
	end

	```
	"""
	function gen() end


	"""
		drag()
	User defined function that returns drag force vector
	---

	## Example:
	```
	function DragObjects.drag(s)
		# Rocket C_f
		C_fr = [0, 0, 0.01]
		
		# - rocket drag
		rocket_drag = -1 * dot(C_fr, [1, s[2], s[2]^2])
	
		# returns force vector opposing velocity 
		# with magnitude of rocket and airbrake drag
		return (rocket_drag+brake_drag) * [cos(s[3]), sin(s[3])]
	end

	```
	"""
	function drag() end


	"""
		apogee_sim(AeroProjectile, noise=true)
	Simulates AeroProjectile to its apogee as defined by when pitch becomes negative.
	Updates state tuple, s = (height, velocity, pitch), continuously until pitch < 0 
	by calling a user-defined gen(a, s) function starting from AeroProjectile's s_0.
	Returns the final state of the simulation. Requires a 
	DragObjects.gen(rocket, state, noise=true) function to be declared.
	---
	## Arguments:
	- 	a::AeroProjectile = `AeroProjectile` object
	-	noise::boolean = turns noise on and off in simulations (default=true)

	## Example:
	```
	apogee_sim(MyAeroProjectile) => (297, .07, -0.01)
	```
	"""
	function apogee_sim(a::AeroProjectile; noise=true)
		s = a.s_0

		while true
			s = gen(a, s, noise=noise)
			
			if s[3] < 0
				break
			end
				
		end
		
		return s
	end


	"""
		apogee_sim(AeroProjectile, s_0)
	Simulates AeroProjectile to its apogee as defined by when pitch becomes negative.
	Updates state tuple, s = (height, velocity, pitch), continuously until pitch < 0 
	by calling a user-defined gen(a, s) function starting from AeroProjectile's s_0.
	Returns the final state of the simulation.
	---
	## Arguments:
	- 	a::AeroProjectile = `AeroProjectile` object

	## Example:
	```
	apogee_sim(MyAeroProjectile, (132.68, 68.77, 81.686 * pi / 180, 0)) => (297, .07, -0.01)
	```
	"""
	function apogee_sim(a::AeroProjectile, s; noise=true)
		
		while true
			s = gen(a, s, noise=true)
			
			if s[3] < 0
				break
			end
				
		end
		
		return s
	end


	"""
		targeted_sim(a::AeroProjectile, target::Float64)

	Simulates AeroProjectile to either apogee (when pitch becomes negative) or until 
	it reaches a specified target height. Updates state tuple, `s = (height, velocity, pitch)`, 
	continuously until `pitch < 0` by calling a user-defined `gen(a, s)` function starting 
	from AeroProjectile's `s_0`. Returns the final state of the simulation.
	---
	## Arguments:
	- 	a::AeroProjectile = `AeroProjectile` object
	- 	target::Float64 = Target height

	## Example:
	```
	targeted_sim(MyAeroProjectile, 300) => (300.01, 21, 32)
	```
	"""
	function targeted_sim(a::AeroProjectile, target::Float64)
		s = a.s_0

		while true
			s = gen(a, s)
			
			# If more likely to reach apogee than to pass
			# target, flip condition orders
			if s[1] > target || s[3] <= 0
				# s[1] > target means passed target
				# s[3] < 0 means apogee reached
				break
			end
		end
		
		return s
	end
end
