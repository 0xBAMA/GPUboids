#version 430
precision highp int;
layout( local_size_x = 16, local_size_y = 16, local_size_z = 1 ) in;

layout( binding = 1, r32ui ) uniform uimage2D currentR;
layout( binding = 2, r32ui ) uniform uimage2D currentG;
layout( binding = 3, r32ui ) uniform uimage2D currentB;

layout( binding = 4, r32ui ) uniform uimage2D previousR;
layout( binding = 5, r32ui ) uniform uimage2D previousG;
layout( binding = 6, r32ui ) uniform uimage2D previousB;

// amount that the result of the kernel decays each frame
// uniform float decayFactor;
const float decayFactor = 0.99;

// gaussian kernel - diffuses data from atomic writes outwards
float applyKernel( uimage2D readFrom, ivec2 position ){
	return (
		1.0 * imageLoad( readFrom, position + ivec2( -1, -1 ) ).r +
		1.0 * imageLoad( readFrom, position + ivec2( -1,  1 ) ).r +
		1.0 * imageLoad( readFrom, position + ivec2(  1, -1 ) ).r +
		1.0 * imageLoad( readFrom, position + ivec2(  1,  1 ) ).r +
		2.0 * imageLoad( readFrom, position + ivec2(  0,  1 ) ).r +
		2.0 * imageLoad( readFrom, position + ivec2(  0, -1 ) ).r +
		2.0 * imageLoad( readFrom, position + ivec2(  1,  0 ) ).r +
		2.0 * imageLoad( readFrom, position + ivec2( -1,  0 ) ).r +
		4.0 * imageLoad( readFrom, position + ivec2(  0,  0 ) ).r ) / 16.0;
}

void main() {
	ivec2 pos = ivec2( gl_GlobalInvocationID.xy );
	imageStore( currentR, pos, uvec4( uint( decayFactor * applyKernel( previousR, pos ) ) ) );
	imageStore( currentG, pos, uvec4( uint( decayFactor * applyKernel( previousG, pos ) ) ) );
	imageStore( currentB, pos, uvec4( uint( decayFactor * applyKernel( previousB, pos ) ) ) );
}
