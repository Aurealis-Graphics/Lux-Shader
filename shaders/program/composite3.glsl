/* 
BSL Shaders v7.1.05 by Capt Tatsu 
https://bitslablab.com 
*/ 

//Settings//
#include "/lib/settings.glsl"

//Fragment Shader///////////////////////////////////////////////////////////////////////////////////
#ifdef FSH

//Varyings//
varying vec2 texCoord;

//Uniforms//
uniform float viewWidth, viewHeight, aspectRatio;
uniform float centerDepthSmooth;

uniform float frameTimeCounter;

uniform mat4 gbufferProjection;

uniform sampler2D colortex0;
uniform sampler2D depthtex1;

//Optifine Constants//

#include "/lib/util/circleOfConfusion.glsl"
#include "/lib/util/dither.glsl"

vec2 samples[60] = vec2[60](
	vec2(0.09128709291752769, 0.0),
	vec2(-0.11658822152703764, 0.10680443156144032),
	vec2(0.017845568074858303, -0.20334257391592214),
	vec2(0.14695213443464825, 0.19167264676639284),
	vec2(-0.26967495681282605, -0.04770133822022609),
	vec2(0.2554594129706215, -0.1625027845649794),
	vec2(-0.08544561242638565, 0.317855911775152),
	vec2(-0.1629561105938302, -0.31375994967511606),
	vec2(0.3535480304350502, 0.1291141233256978),
	vec2(-0.36780708603140594, 0.15182648253324987),
	vec2(0.17730662058590146, -0.37889624212494794),
	vec2(0.1310274377935309, 0.41773014879456455),
	vec2(-0.39491398034589675, -0.228858649521258),
	vec2(0.4632776117493232, -0.10185212050734804),
	vec2(-0.2827291216092968, 0.40215781785351645),
	vec2(-0.06532020637588601, -0.5040501998534919),
	vec2(0.40098708780907777, 0.33794874672114855),
	vec2(-0.5396004276600745, 0.022316924871748425),
	vec2(0.39359523619214504, -0.39168370323538204),
	vec2(-0.026330445090915453, 0.5694793303196476),
	vec2(-0.37451105846931637, -0.4487851755025549),
	vec2(0.5932642289070916, 0.07981784282105857),
	vec2(-0.5026681644656951, 0.3497495052643947),
	vec2(0.13735374261883032, -0.6105740053877717),
	vec2(0.3177077370789623, 0.5544322565773913),
	vec2(-0.6210812330251597, -0.19813657406937038),
	vec2(0.6032977843914864, -0.27874441701133706),
	vec2(-0.261357574230277, 0.6245202572581602),
	vec2(-0.23326932288249147, -0.6485255762126455),
	vec2(0.6206890749190722, 0.3262081221287615),
	vec2(-0.6894234680200805, 0.18173776458540028),
	vec2(0.39186769012235223, -0.6094585411971615),
	vec2(0.12466509299274176, 0.7253449394982898),
	vec2(-0.5907718524925895, -0.4575171599358951),
	vec2(0.7556978660761726, -0.06261577443359569),
	vec2(-0.5223412945641717, 0.564647003586924),
	vec2(0.0037971352740273556, -0.7799480207661559),
	vec2(0.5311775660703216, 0.5855342802121913),
	vec2(-0.7976234165742593, -0.07391584403273936),
	vec2(0.6463057213778237, -0.4905326164972359),
	vec2(-0.14704250821373113, 0.8083183164930847),
	vec2(-0.4429612350700046, -0.7038835208270775),
	vec2(0.8116985207640949, 0.22243840658194267),
	vec2(-0.7575341846015305, 0.38876980227390867),
	vec2(0.29935466999988836, -0.8074982651473157),
	vec2(0.32835059937302397, 0.8065477154048044),
	vec2(-0.795531201035876, -0.3770014697297828),
	vec2(0.8502585194891206, -0.26215857167530365),
	vec2(-0.45457951001148517, 0.7756873096880285),
	vec2(-0.1907125528456961, -0.888047702652891),
	vec2(0.7479353546131233, 0.5312808786192179),
	vec2(-0.9193488185170423, 0.11459093866729356),
	vec2(0.6062962567620056, -0.712323556423891),
	vec2(0.03442678198424923, 0.9436532537690291),
	vec2(-0.6689847724161234, -0.6788171385643418),
	vec2(0.9605155598054489, 0.04909031851215688),
	vec2(-0.7480639954735168, 0.6181156245742901),
	vec2(0.13524938729537853, -0.9695570826772182),
	vec2(0.5600045850686216, 0.81326186723719),
	vec2(-0.9704701858428567, -0.22328073149467595)
);

//Common Functions//
mat2 rotate(float angle) {
	return mat2(cos(angle), -sin(angle), sin(angle), cos(angle));
}

vec3 DepthOfField(vec3 color, float z){
	if(z < 0.56) return texture2D(colortex0, texCoord).rgb;
	
	float fovScale = gbufferProjection[1][1] / 1.37;
	float coc = GetCircleOfConfusion(z, centerDepthSmooth);
	
	vec3 dof = vec3(0.0);
	float noise = InterleavedGradientNoise(gl_FragCoord.xy);

	#if AA == 2
	noise = fract(noise + frameTimeCounter * 38.34718);

	mat2 rotation = rotate(noise * 2.0 * 3.1415);
	#endif

	for (int i = 0; i < 60; i++)
	{
		vec2 offset = samples[i] * coc * fovScale * 0.1;

		#if AA == 2
		offset = rotation * offset;
		#endif

		dof += texture2D(colortex0, texCoord + offset / vec2(aspectRatio, 1.0)).rgb;
	}
	
	return dof / 60.0;
}

//Includes//
#ifdef BLACK_OUTLINE
#include "/lib/outline/depthOutline.glsl"
#endif

//Program//
void main(){
	vec3 color = texture2DLod(colortex0, texCoord, 0.0).rgb;
	
	float z = texture2D(depthtex1, texCoord.st).x;

	#ifdef DOF
	color = DepthOfField(color, z);
	#endif

	#ifdef BLACK_OUTLINE
	DepthOutline(z);
	#endif
	
    /*DRAWBUFFERS:0*/
	gl_FragData[0] = vec4(color,1.0);
}

#endif

//Vertex Shader/////////////////////////////////////////////////////////////////////////////////////
#ifdef VSH

//Varyings//
varying vec2 texCoord;

//Program//
void main(){
	texCoord = gl_MultiTexCoord0.xy;
	
	gl_Position = ftransform();
}

#endif