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
varying float mat;

varying vec2 texCoord;

varying vec4 color;

// Uniforms
uniform int blockEntityId;

uniform sampler2D tex;

// Program
void main()
{
    #if MC_VERSION >= 11300
	if (blockEntityId == 10250) discard;
	#endif

    vec4 albedo = texture2D(tex, texCoord.xy);
	albedo.rgb *= color.rgb;

    float premult = float(mat > 0.98 && mat < 1.02);
	float disable = float(mat > 1.98 && mat < 2.02);
	if (disable > 0.5 || albedo.a < 0.01) discard;

    #ifdef SHADOW_COLOR
	albedo.rgb = mix(vec3(1.0), albedo.rgb, pow(albedo.a, (1.0 - albedo.a) * 0.5) * 1.05);
	albedo.rgb *= 1.0 - pow(albedo.a, 64.0);
	#else
	if ((premult > 0.5 && albedo.a < 0.98)) albedo.a = 0.0;
	#endif
	
	gl_FragData[0] = albedo;
}

#endif

// Vertex Shader
#ifdef VSH

// Varyings
varying float mat;

varying vec2 texCoord;

varying vec4 color;

// Uniforms
uniform int worldTime;

uniform float frameTimeCounter;
uniform float rainStrength;

uniform vec3 cameraPosition;

uniform mat4 gbufferModelView, gbufferModelViewInverse;
uniform mat4 shadowProjection, shadowProjectionInverse;
uniform mat4 shadowModelView, shadowModelViewInverse;

// Attributes
attribute vec4 mc_Entity;
attribute vec4 mc_midTexCoord;

// Common Variables
#ifdef WORLD_TIME_ANIMATION
float frametime = float(worldTime) * 0.05 * ANIMATION_SPEED;
#else
float frametime = frameTimeCounter * ANIMATION_SPEED;
#endif

// Includes
#include "/lib/vertex/waving.glsl"

#ifdef WORLD_CURVATURE
#include "/lib/vertex/worldCurvature.glsl"
#endif

// Program
void main()
{
	texCoord = gl_MultiTexCoord0.xy;
	color = gl_Color;	
	mat = 0;

	if (mc_Entity.x == 10301) mat = 1;
	if (mc_Entity.x == 10300 || mc_Entity.x == 10249 || mc_Entity.x == 10252) mat = 2;
	
	vec4 position = shadowModelViewInverse * shadowProjectionInverse * ftransform();
	float istopv = gl_MultiTexCoord0.t < mc_midTexCoord.t ? 1.0 : 0.0;
	position.xyz = WavingBlocks(position.xyz, istopv, 1.0, 1.0, rainStrength);

	#ifdef WORLD_CURVATURE
	position.y -= WorldCurvature(position.xz);
	#endif
	
	gl_Position = shadowProjection * shadowModelView * position;
	float dist = sqrt(gl_Position.x * gl_Position.x + gl_Position.y * gl_Position.y);
	float distortFactor = dist * shadowMapBias + (1.0 - shadowMapBias);
	gl_Position.xy *= 1.0 / distortFactor;
	gl_Position.z = gl_Position.z * 0.2;
}

#endif