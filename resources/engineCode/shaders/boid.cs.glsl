#version 430
layout( local_size_x = 16, local_size_y = 16, local_size_z = 1 ) in;
layout( binding = 1, r32ui ) uniform uimage2D currentR;
layout( binding = 2, r32ui ) uniform uimage2D currentG;
layout( binding = 3, r32ui ) uniform uimage2D currentB;

uniform ivec2 computeDimensions;
uniform float time;

uniform mat3 rotationMatrix;

// write level is in the .w's
struct boidType{
	vec4 position;
	vec4 velocity;
	vec4 binValue;
};
layout( binding = 0, std430 ) buffer agent_data {
	boidType data[];
};


mat2 rotate2D( float r ){ return mat2( cos( r ), sin( r ), -sin( r ), cos( r ) ); }
mat3 rotate3D( float angle, vec3 axis ){
	vec3 a = normalize( axis );
	float s = sin( angle );
	float c = cos( angle );
	float r = 1.0 - c;
	return mat3(
		a.x * a.x * r + c,
		a.y * a.x * r + a.z * s,
		a.z * a.x * r - a.y * s,
		a.x * a.y * r - a.z * s,
		a.y * a.y * r + c,
		a.z * a.y * r + a.x * s,
		a.x * a.z * r + a.y * s,
		a.y * a.z * r - a.x * s,
		a.z * a.z * r + c
	);
}

// this invocation's boid index in the SSBO
uint index = gl_GlobalInvocationID.x + computeDimensions.x * gl_GlobalInvocationID.y;
// random float generation
uint seed = index;
uint wangHash() {
	seed = uint( seed ^ uint( 61 ) ) ^ uint( seed >> uint( 16 ) );
	seed *= uint( 9 );
	seed = seed ^ ( seed >> 4 );
	seed *= uint( 0x27d4eb2d );
	seed = seed ^ ( seed >> 15 );
	return seed;
}
float randomFloat() { return float( wangHash() ) / 4294967296.0; }


// I think it's going to be best to accumulate all terms in a single pass, so you only walk the list once
vec3 acceleration(){
	int numBoids = computeDimensions.x * computeDimensions.y;

	vec3 totalForce = vec3( 0.0 );

	// separation term


	// alignment term - align with nearby agents
		// for all boids
			// if within perception distance, look at the velocity value for that agent, add to accumulator
				// increment a total count
			// end for
		// if total count greater than zero
			// accumulator divided by total count to get result
			// scale the result by the maximum velocity
			// subtract the current boid's velocity to get the steering force
			// limit the magnitude of this vector by the maximum force


	// cohesion term


	int countBoidsInLocalNeighborhood = 0;
	vec3 alignmentAccumulator = vec3( 0.0 );
	for( int i = 0; i < numBoids; i++ ) {
		if( i != index ) { // no self comparisons
			if( distance( data[ index ].position.xyz, data[ i ].position.xyz ) < 0.25 ) { // distance threshold
				countBoidsInLocalNeighborhood++;
				alignmentAccumulator += data[ i ].velocity.xyz;
			}
		}
	}
	if( countBoidsInLocalNeighborhood > 0 ) {
		alignmentAccumulator /= float( countBoidsInLocalNeighborhood );
		alignmentAccumulator = 0.01 * normalize( alignmentAccumulator );
		// alignmentAccumulator -= data[ index ].position.xyz;
	}

	totalForce += alignmentAccumulator;

	return totalForce;
}

void wraparoundBoundsCheck( inout float val ){
	if( val > 1.0 )
		val = -1.0;
	if( val < -1.0)
		val = 1.0;
}

void wraparoundBoundsCheck( inout vec3 val ){
	wraparoundBoundsCheck( val.x );
	wraparoundBoundsCheck( val.y );
	wraparoundBoundsCheck( val.z );
}

void update( inout boidType boidUnderConsideration ){
	boidUnderConsideration.position.xyz += 0.001 * boidUnderConsideration.velocity.xyz;
	boidUnderConsideration.velocity.xyz += acceleration();

	// clamp the magnitude of the velocity
	float mag = length( boidUnderConsideration.velocity.xyz );
	mag = clamp( mag, 0.0, 1.0 );
	boidUnderConsideration.velocity.xyz = mag * normalize( boidUnderConsideration.velocity.xyz );

	wraparoundBoundsCheck( boidUnderConsideration.position.xyz );
}

void draw( boidType boidUnderConsideration ){

	vec3 drawPosition = boidUnderConsideration.position.xyz;
	// drawPosition = rotate3D( time / 12.0, vec3( 1.0 ) ) * drawPosition;
	drawPosition = rotationMatrix * drawPosition;
	ivec2 imageSizeScalar = ivec2( min( imageSize( currentR ).x, imageSize( currentR ).y ) );
	ivec2 writeLocation = ivec2( 0.618 * ( drawPosition.xy + vec2( 1.0 ) ) * ( imageSizeScalar / 2 ) );

	// magic numbers for screen alignment
	writeLocation.x += ( 850 );
	writeLocation.y += ( 250 );

	imageAtomicAdd( currentR, writeLocation, int( 1000 * boidUnderConsideration.position.w ) );
	imageAtomicAdd( currentG, writeLocation, int( 1000 * boidUnderConsideration.velocity.w ) );
	imageAtomicAdd( currentB, writeLocation, int( 1000 * boidUnderConsideration.binValue.w ) );
}

void main() {
	if( gl_GlobalInvocationID.x < computeDimensions.x && gl_GlobalInvocationID.y < computeDimensions.y ){
		update( data[ index ] );
		draw( data[ index ] );
	}
}
