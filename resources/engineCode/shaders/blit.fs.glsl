#version 430 core
layout( binding = 1, r32ui ) uniform uimage2D currentR;
layout( binding = 2, r32ui ) uniform uimage2D currentG;
layout( binding = 3, r32ui ) uniform uimage2D currentB;
uniform float outputRangeScalar;
uniform vec2 resolution;
out vec4 fragmentOutput;
void main() {
	fragmentOutput.r = imageLoad( currentR, ivec2( gl_FragCoord.xy ) ).r / outputRangeScalar;
	fragmentOutput.g = imageLoad( currentG, ivec2( gl_FragCoord.xy ) ).r / outputRangeScalar;
	fragmentOutput.b = imageLoad( currentB, ivec2( gl_FragCoord.xy ) ).r / outputRangeScalar;
	fragmentOutput.a = 1.0;
}
