#version 430
layout( local_size_x = 16, local_size_y = 16, local_size_z = 1 ) in;

layout( rgba8ui ) uniform uimage2D outputRGB;
layout( binding = 1, r32ui ) uniform uimage2D currentR;
layout( binding = 2, r32ui ) uniform uimage2D currentG;
layout( binding = 3, r32ui ) uniform uimage2D currentB;

void main() {
	// combine current atomic accumulator buffer textures to write to the display texture
	ivec2 pos = ivec2( gl_GlobalInvocationID.xy );

	// read the three channels
	uvec3 read;
	read.r = clamp( imageLoad( currentR, pos ).r, 0, 255 );
	read.g = clamp( imageLoad( currentG, pos ).r, 0, 255 );
	read.b = clamp( imageLoad( currentB, pos ).r, 0, 255 );

	// write to display texture
	imageStore( outputRGB, pos, uvec4( read, 255 ) );
}
