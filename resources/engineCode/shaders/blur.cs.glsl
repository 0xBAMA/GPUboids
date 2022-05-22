#version 430
layout( local_size_x = 8, local_size_y = 8, local_size_z = 1 ) in;

// revisit binding locations
layout( binding = 1, r32ui ) uniform uimage2D current;
layout( binding = 2, r32ui ) uniform uimage2D previous;

precision highp int;

uniform float decay_factor;

void main() {
	ivec2 pos = ivec2( gl_GlobalInvocationID.xy );
	float g = (	// gaussian kernel - diffuses data from atomic writes outwards
		1.0 * imageLoad( previous, pos + ivec2( -1, -1 ) ).r +
		1.0 * imageLoad( previous, pos + ivec2( -1,  1 ) ).r +
		1.0 * imageLoad( previous, pos + ivec2(  1, -1 ) ).r +
		1.0 * imageLoad( previous, pos + ivec2(  1,  1 ) ).r +
		2.0 * imageLoad( previous, pos + ivec2(  0,  1 ) ).r +
		2.0 * imageLoad( previous, pos + ivec2(  0, -1 ) ).r +
		2.0 * imageLoad( previous, pos + ivec2(  1,  0 ) ).r +
		2.0 * imageLoad( previous, pos + ivec2( -1,  0 ) ).r +
		4.0 * imageLoad( previous, pos + ivec2(  0,  0 ) ).r ) / 16.0;

	imageStore( current, pos, uvec4( uint( decay_factor * g ) ) );
}
