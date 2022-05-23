#version 430 core
// uniform sampler2D current;
// layout( binding = 0, rgba8ui ) uniform uimage2D current;
layout( binding = 1, r32ui ) uniform uimage2D currentR;
layout( binding = 2, r32ui ) uniform uimage2D currentG;
layout( binding = 3, r32ui ) uniform uimage2D currentB;
uniform vec2 resolution;
out vec4 fragmentOutput;
uniform float outputRangeScalar;
void main() {
	// fragmentOutput = texture( current, gl_FragCoord.xy / resolution );

	fragmentOutput.r = imageLoad( currentR, ivec2( gl_FragCoord.xy ) ).r / outputRangeScalar;
	fragmentOutput.g = imageLoad( currentG, ivec2( gl_FragCoord.xy ) ).r / outputRangeScalar;
	fragmentOutput.b = imageLoad( currentB, ivec2( gl_FragCoord.xy ) ).r / outputRangeScalar;
	fragmentOutput.a = 1.0;

	// fragmentOutput = imageLoad( current, ivec2( gl_FragCoord.xy ) );
}
