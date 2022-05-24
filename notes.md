binning scheme
	each update, each agent computes the bin they are in, and sets a parameter for their entry in the SSBO
		iterating through the list, do a quick check on the bin before doing any distance based calculations


basis construction
	cross product of the direction vector with the up vector to give the right vector ( with check for direction==up )
		use dot product of displacements to neighbors with the direction vector, to see if it's in the view cone


checking neighbors:
	iterate through the SSBO contents
		not own index
			in neighboring bin ( early out )
				dot product of displacement falls into cone
					distance within sphere of influence
						the boid under consideration is a member of local group
					else don't
				else don't
			else don't
		else don't


simulation rules:
	separation
		force acting opposite of sum of displacement vectors with local neighbors

	alignment
		force which brings the direction towards the direction of local neighbors

	cohesion
		force attracting to the center of mass of the visible local neighbors





imgui parameters:
	rendering:
		~~output range scalar ( divisor for value kept in atomic accumulator buffers )~~
		~~decay amount~~

	simulation:
		perception distance
		perception angle - dot product thresholding
		max force applied by each term, per update
		velocity scalar - multiplier on velocity, when applied to position
		max velocity

		~~number of boids - not user settable, just need for keeping track of how many boids are in play~~
		~~separation weight~~
		~~alignment weight~~
		~~cohesion weight~~



	▄▐▐▄▐▀▐▐▀▐▀▐▐▀▐▐▐
	▐▐▄▐▐▐▐▐▐▐▐▐▐▐▀▐▐
	▐▄▐▐▐▐▐▓░▒▒▐▐▐▐▀▐
	▄▐▐▐▒▓▓░▒▒▒▒▒▐▐▐▀
	▐▐▐▒▓░▒▒▒▒▒▒▒▒▐▐▐
	▐▐▒▓░▒▒▒▒▒▒▒▒▒▒▐▐
	▐▐▒░▒▒▒▒▒▒▒▒▒▒▒▒▐
	▐▐▐▐▐▐▐▐▐▐▐▐▐▐▐▐▐


high level structure:
	boid.cs.glsl performs simulation logic, updating point locations and performing atomic writes
	blur.cs.glsl blurs the previous accumulators into the current accumulators
	// bake.cs.glsl takes current accumulators and combines 3 channels into the display texture // not working
	blit.vs/fs.glsl now samples the three accumulators to show them onscreen
