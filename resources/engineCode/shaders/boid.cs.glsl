#version 430
layout( local_size_x = 16, local_size_y = 16, local_size_z = 1 ) in;
layout( binding = 1, r32ui ) uniform uimage2D current;
layout( binding = 2, r32ui ) uniform uimage2D previous;

uniform ivec2 computeDimensions;
uniform float time;

// need to pass in number? maybe vertex shader is better... index with gl_VertexID * 2
layout( binding = 0, std430 ) buffer agent_data {
	vec4 data[];	// [position0, velocity0], [position1, velocity1], ...
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

// random float generation
uint seed = 0;
uint wangHash() {
	seed = uint( seed ^ uint( 61 ) ) ^ uint( seed >> uint( 16 ) );
	seed *= uint( 9 );
	seed = seed ^ ( seed >> 4 );
	seed *= uint( 0x27d4eb2d );
	seed = seed ^ ( seed >> 15 );
	return seed;
}
float randomFloat() { return float( wangHash() ) / 4294967296.0; }

void main() {
	uint index = ( gl_GlobalInvocationID.x + computeDimensions.x * gl_GlobalInvocationID.y ) * 2;

	// construct rotation matrix on CPU and pass it in as a matrix - want to do quaternion style rotation with keyboard control

	vec3 drawPosition = data[ index ].xyz;
	ivec2 writeLocation = ivec2( ( drawPosition.xy + vec2( 1.0 ) ) * ( imageSize( current ) / 2 ) );

	imageAtomicAdd( current, writeLocation, 1000 );
}
