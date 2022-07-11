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
uniform float viewWidth, viewHeight, aspectRatio;

uniform sampler2D colortex1;

#if AA == 2
uniform vec3 cameraPosition, previousCameraPosition;

uniform mat4 gbufferPreviousProjection, gbufferProjectionInverse;
uniform mat4 gbufferPreviousModelView, gbufferModelViewInverse;

uniform sampler2D colortex2;
uniform sampler2D depthtex1;
#endif

// Optifine Constants
#ifdef LIGHTSHAFT
const bool colortex1MipmapEnabled = true;
#endif

// Common Functions

// Includes
#include "/lib/color/colorgrading/colorGrade.glsl"

#if AA == 1
#include "/lib/antialiasing/fxaa.glsl"
#endif

#if AA == 2
#include "/lib/antialiasing/taa.glsl"
#endif

// Program
void main()
{
    #ifndef RETRO_FILTER
    vec3 color = texture2DLod(colortex1, texCoord, 0).rgb;

    #if AA == 1
	FXAA311(color);
	#elif AA == 2
    vec4 prev = vec4(texture2DLod(colortex2, texCoord, 0.0).r, 0.0, 0.0, 0.0);
    TAA(color, prev);
    #endif
    #else
    vec2 view = vec2(viewWidth, viewHeight) * 0.5;
    vec3 color = texture2DLod(colortex1, floor(texCoord * view) / view, 0.0).rgb;
    #endif

    color = mix(color, Smooth3(color), 0.1);

    color = ColorGrade(color);

    /* DRAWBUFFERS:1 */
	gl_FragData[0] = vec4(color, 1.0);
    
	#if AA == 2 && !defined RETRO_FILTER
    /* DRAWBUFFERS:12 */
	gl_FragData[1] = vec4(prev);
	#endif
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