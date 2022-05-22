#version 430 core
// uniform sampler2D current;
// layout( binding = 0, rgba8ui ) uniform uimage2D current;
layout( binding = 1, r32ui ) uniform uimage2D currentR;
layout( binding = 2, r32ui ) uniform uimage2D currentG;
layout( binding = 3, r32ui ) uniform uimage2D currentB;
uniform vec2 resolution;
out vec4 fragmentOutput;
void main() {
	// fragmentOutput = texture( current, gl_FragCoord.xy / resolution );

	float scalar = 1618.0;
	fragmentOutput.r = imageLoad( currentR, ivec2( gl_FragCoord.xy ) ).r / scalar;
	fragmentOutput.g = imageLoad( currentG, ivec2( gl_FragCoord.xy ) ).r / scalar;
	fragmentOutput.b = imageLoad( currentB, ivec2( gl_FragCoord.xy ) ).r / scalar;
	fragmentOutput.a = 1.0;

	// fragmentOutput = imageLoad( current, ivec2( gl_FragCoord.xy ) );
}
