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

uniform vec3 cameraPosition, previousCameraPosition;

uniform mat4 gbufferPreviousProjection, gbufferProjectionInverse;
uniform mat4 gbufferModelView, gbufferPreviousModelView, gbufferModelViewInverse;

uniform sampler2D colortex0;
uniform sampler2D depthtex1;

// Common Functions
vec3 MotionBlur(vec3 color, float z, float dither)
{
	if (IsHand(z)) return color;

	float mbwg = 0.0;
	vec2 doublePixel = 2.0 / vec2(viewWidth, viewHeight);
	vec3 mblur = vec3(0.0);
	
	vec4 currentPosition = vec4(texCoord, z, 1.0) * 2.0 - 1.0;
	
	vec4 viewPos = gbufferProjectionInverse * currentPosition;
	viewPos = gbufferModelViewInverse * viewPos;
	viewPos /= viewPos.w;
	
	vec3 cameraOffset = cameraPosition - previousCameraPosition;
	
	vec4 previousPosition = viewPos + vec4(cameraOffset, 0.0);
	previousPosition = gbufferPreviousModelView * previousPosition;
	previousPosition = gbufferPreviousProjection * previousPosition;
	previousPosition /= previousPosition.w;

	vec2 velocity = (currentPosition - previousPosition).xy;
	velocity = velocity / (1.0 + length(velocity)) * MOTION_BLUR_STRENGTH * 0.02;
	
	vec2 coord = texCoord.st - velocity * (1.5 + dither);
	for(int i = 0; i < 5; i++, coord += velocity)
	{
		vec2 sampleCoord = clamp(coord, doublePixel, 1.0 - doublePixel);
		float mask = float(texture2D(depthtex1, sampleCoord).r > 0.56);
		mblur += texture2DLod(colortex0, sampleCoord, 0.0).rgb * mask;
		mbwg += mask;
	}
	mblur /= max(mbwg, 1.0);

	return mblur;
}

// Includes
#include "/lib/util/dither.glsl"

// Program
void main()
{
    vec3 color = texture2DLod(colortex0, texCoord, 0.0).rgb;
	
	#ifdef MOTION_BLUR
	float z = texture2D(depthtex1, texCoord.st).x;
	float dither = Bayer64(gl_FragCoord.xy);

	color = MotionBlur(color, z, dither);
	#endif

	/* DRAWBUFFERS:0 */
	gl_FragData[0] = vec4(color, 1.0);
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