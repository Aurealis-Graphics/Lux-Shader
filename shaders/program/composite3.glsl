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
uniform float centerDepthSmooth;
uniform float far, near;

uniform float frameTimeCounter;

uniform mat4 gbufferProjection;

uniform sampler2D colortex0;
uniform sampler2D depthtex1;

// Bokeh Offsets
const vec2 samples[60] = vec2[60](
	vec2(  0.091287092917527,  0.0				 ),
	vec2( -0.116588221527037,  0.10680443156144  ),
	vec2(  0.017845568074858, -0.20334257391592  ),
	vec2(  0.146952134434648,  0.19167264676639  ),
	vec2( -0.269674956812826, -0.04770133822022  ),
	vec2(  0.255459412970621, -0.16250278456497  ),
	vec2( -0.085445612426385,  0.317855911775152 ),
	vec2( -0.162956110593830, -0.313759949675116 ),
	vec2(  0.353548030435050,  0.129114123325697 ),
	vec2( -0.367807086031405,  0.151826482533249 ),
	vec2(  0.177306620585901, -0.378896242124947 ),
	vec2(  0.131027437793530,  0.417730148794564 ),
	vec2( -0.394913980345896, -0.228858649521258 ),
	vec2(  0.463277611749323, -0.101852120507348 ),
	vec2( -0.282729121609296,  0.402157817853516 ),
	vec2( -0.065320206375886, -0.504050199853491 ),
	vec2(  0.400987087809077,  0.337948746721148 ),
	vec2( -0.539600427660074,  0.022316924871748 ),
	vec2(  0.393595236192145, -0.391683703235382 ),
	vec2( -0.026330445090915,  0.569479330319647 ),
	vec2( -0.374511058469316, -0.448785175502554 ),
	vec2(  0.593264228907091,  0.079817842821058 ),
	vec2( -0.502668164465695,  0.349749505264394 ),
	vec2(  0.137353742618830, -0.610574005387771 ),
	vec2(  0.317707737078962,  0.554432256577391 ),
	vec2( -0.621081233025159, -0.198136574069370 ),
	vec2(  0.603297784391486, -0.278744417011337 ),
	vec2( -0.261357574230277,  0.624520257258160 ),
	vec2( -0.233269322882491, -0.648525576212645 ),
	vec2(  0.620689074919072,  0.326208122128761 ),
	vec2( -0.689423468020080,  0.181737764585400 ),
	vec2(  0.391867690122352, -0.609458541197161 ),
	vec2(  0.124665092992741,  0.725344939498289 ),
	vec2( -0.590771852492589, -0.457517159935895 ),
	vec2(  0.755697866076172, -0.062615774433595 ),
	vec2( -0.522341294564171,  0.564647003586924 ),
	vec2(  0.003797135274027, -0.779948020766155 ),
	vec2(  0.531177566070321,  0.585534280212191 ),
	vec2( -0.797623416574259, -0.073915844032739 ),
	vec2(  0.646305721377823, -0.490532616497235 ),
	vec2( -0.147042508213731,  0.808318316493084 ),
	vec2( -0.442961235070004, -0.703883520827077 ),
	vec2(  0.811698520764094,  0.222438406581942 ),
	vec2( -0.757534184601530,  0.388769802273908 ),
	vec2(  0.299354669999888, -0.807498265147315 ),
	vec2(  0.328350599373023,  0.806547715404804 ),
	vec2( -0.795531201035876, -0.377001469729782 ),
	vec2(  0.850258519489120, -0.262158571675303 ),
	vec2( -0.454579510011485,  0.775687309688028 ),
	vec2( -0.190712552845696, -0.888047702652891 ),
	vec2(  0.747935354613123,  0.531280878619217 ),
	vec2( -0.919348818517042,  0.114590938667293 ),
	vec2(  0.606296256762005, -0.712323556423891 ),
	vec2(  0.034426781984249,  0.943653253769029 ),
	vec2( -0.668984772416123, -0.678817138564341 ),
	vec2(  0.960515559805448,  0.049090318512156 ),
	vec2( -0.748063995473516,  0.618115624574290 ),
	vec2(  0.135249387295378, -0.969557082677218 ),
	vec2(  0.560004585068621,  0.81326186723719  ),
	vec2( -0.970470185842856, -0.223280731494675 )
);

// Includes
#include "/lib/util/circleOfConfusion.glsl"
#include "/lib/util/dither.glsl"

// Common Functions
vec3 DepthOfField(vec3 color, float z)
{
	if (IsHand(z)) return texture2D(colortex0, texCoord).rgb;
	
	float coc = GetCircleOfConfusion(z, centerDepthSmooth, gbufferProjection, DOF_STRENGTH);
	
	if (coc < 1.0 / max(viewWidth, viewHeight)) return color;

	vec3 dof = vec3(0.0);
	float noise = InterleavedGradientNoise(gl_FragCoord.xy);

	#if AA == 2
	noise = fract(noise + frameTimeCounter * 38.34718);

	mat2 rotation = Rotate(noise * 2.0 * PI);
	#endif

	#ifdef DOF_SAMPLE_REJECTION
	float totalWeight = 0.0;
	#endif

	for (int i = 0; i < 60; i++)
	{
		vec2 offset = samples[i] * coc;

		#if AA == 2
		offset = rotation * offset;
		#endif

		offset.x /= aspectRatio;

		vec3 tapSample = texture2DLod(colortex0, texCoord + offset, 0.0).rgb;

		#ifdef DOF_SAMPLE_REJECTION
		float tapDepth = texture2D(depthtex1, texCoord + offset, 0.0).x;
		float tapCoc = GetCircleOfConfusion(tapDepth, centerDepthSmooth, gbufferProjection, DOF_STRENGTH);
		float tapWeight = exp2(-distance(coc, tapCoc) * DOF_SAMPLE_REJECTION_RESPONSE);
		totalWeight += tapWeight;

		tapSample *= tapWeight;
		#endif

		#if DOF_TYPE == 0
		dof += tapSample;
		#else
		dof = max(dof, tapSample);
		#endif
	}

	#if DOF_TYPE == 0
	#ifdef DOF_SAMPLE_REJECTION
	return dof / totalWeight;
	#else
	return dof / 60.0;
	#endif
	#else
	return dof;
	#endif
}

// Program
void main()
{
	vec3 color = texture2DLod(colortex0, texCoord, 0.0).rgb;
	float z = texture2D(depthtex1, texCoord.st).x;

	#ifdef DOF
	color = DepthOfField(color, z);
	#endif
	
    /* DRAWBUFFERS:0 */
	gl_FragData[0] = vec4(color,1.0);
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