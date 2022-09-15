/* 
----------------------------------------------------------------
Lux Shader by https://github.com/TechDevOnGithub/
Based on BSL Shaders v7.1.05 by Capt Tatsu https://bitslablab.com 
See AGREEMENT.txt for more information.
----------------------------------------------------------------
*/ 

// Global Include
#include "/lib/global.glsl"

// Fragment Shader
#ifdef FSH

// Varyings
varying vec2 texCoord;

// Uniforms
uniform sampler2D colortex1;

uniform float viewWidth, viewHeight;

// Optifine Constants
#include "/lib/util/framebufferFormats.glsl"

const bool shadowHardwareFiltering = true;

const int noiseTextureResolution = 512;

const float drynessHalflife = 25.0;
const float wetnessHalflife = 200.0;

// Common Functions
#if SHARPEN > 0
vec2 sharpenOffsets[4] = vec2[4](
	vec2(  1.0,  0.0 ),
	vec2(  0.0,  1.0 ),
	vec2( -1.0,  0.0 ),
	vec2(  0.0, -1.0 )
);

void SharpenFilter(inout vec3 color)
{
	vec2 view = 1.0 / vec2(viewWidth, viewHeight);
	vec3 pixelBlur = vec3(0.0);

	for(int i = 0; i < 4; i++)
	{
		vec2 offset = sharpenOffsets[i] * view;
		pixelBlur += texture2D(colortex1, texCoord + offset).rgb / 4.0;
	}

	color += (color - pixelBlur) * SHARPEN * 0.25;
}
#endif

// Program
void main()
{
	vec3 color = texture2D(colortex1, texCoord).rgb;

	#if SHARPEN > 0
	SharpenFilter(color);
	#endif
	
	gl_FragColor = vec4(color, 1.0);
}

#endif

// Vertex Shader
#ifdef VSH

// Varyings
varying vec2 texCoord;

// Program
void main()
{
	texCoord = gl_MultiTexCoord0.xy;	
	gl_Position = ftransform();
}

#endif