/* 
----------------------------------------------------------------
Lux Shader by https://github.com/TechDevOnGithub/
Based on BSL Shaders v7.1.05 by Capt Tatsu https://bitslablab.com 
See AGREEMENT.txt for more information.
----------------------------------------------------------------
*/ 

const vec2 neighbourhoodOffsets[8] = vec2[8](
	vec2(-1.0, -1.0),
	vec2( 0.0, -1.0),
	vec2( 1.0, -1.0),
	vec2(-1.0,  0.0),
	vec2( 1.0,  0.0),
	vec2(-1.0,  1.0),
	vec2( 0.0,  1.0),
	vec2( 1.0,  1.0)
);

const mat3 RGBToYCgCo = mat3(
	vec3(  0.25  ,  0.5  ,  0.25  ),
	vec3( -0.25  ,  0.5  , -0.25  ),
	vec3(  0.5  ,  0.0  , -0.5  )
);

const mat3 YCgCoToRGB = mat3(
	vec3(  1.0  , -1.0  ,  1.0  ),
	vec3(  1.0  ,  1.0  ,  0.0  ),
	vec3(  1.0  , -1.0  , -1.0  )
);

// Previous frame reprojection from Chocapic13
vec2 Reprojection(vec3 pos)
{
	pos = pos * 2.0 - 1.0;

	vec4 viewPos = gbufferProjectionInverse * vec4(pos, 1.0);
	viewPos /= viewPos.w;
	viewPos = gbufferModelViewInverse * viewPos;

	vec3 cameraOffset = cameraPosition - previousCameraPosition;
	cameraOffset *= float(pos.z > 0.56);

	vec4 previousPosition = viewPos + vec4(cameraOffset, 0.0);
	previousPosition = gbufferPreviousModelView * previousPosition;
	previousPosition = gbufferPreviousProjection * previousPosition;
	return previousPosition.xy / previousPosition.w * 0.5 + 0.5;
}

vec3 ClipAABB(vec3 prevColor, vec3 minColor, vec3 maxColor)
{
	vec3 pClip = 0.5 * (maxColor + minColor);
	vec3 eClip = 0.5 * (maxColor - minColor);

	vec3 vClip = prevColor - pClip;
	vec3 vUnit = vClip / eClip;
	vec3 aUnit = abs(vUnit);
	float maUnit = max(aUnit.x, max(aUnit.y, aUnit.z));

	return maUnit > 1.0 ? pClip + vClip / maUnit : prevColor;
}

vec3 NeighbourhoodClamping(vec3 color, vec3 tempColor, vec2 pixelSize)
{
	vec3 minColor = color, maxColor = color;

	for (int i = 0; i < 8; i++)
	{
		vec3 sampleCol1 = RGBToYCgCo * texture2DLod(colortex1, texCoord + neighbourhoodOffsets[i] * pixelSize, 0.0).rgb;
		minColor = min(minColor, sampleCol1); 
		maxColor = max(maxColor, sampleCol1);
	}

	return ClipAABB(tempColor, minColor, maxColor);
}

void TAA(inout vec3 color, inout vec4 temp)
{
	vec3 retColor = RGBToYCgCo * color;
	vec3 coord = vec3(texCoord, texture2DLod(depthtex1, texCoord, 0.0).r);
	vec2 previousCoord = Reprojection(coord);
	vec2 pixelSize = 1.0 / vec2(viewWidth, viewHeight);

	vec3 tempColor = RGBToYCgCo * texture2DLod(colortex2, previousCoord, 0.0).gba;
	tempColor = NeighbourhoodClamping(retColor, tempColor, pixelSize);
	
	float blendFactor = float(
		previousCoord.x > 0.0 && previousCoord.x < 1.0 &&
		previousCoord.y > 0.0 && previousCoord.y < 1.0
	);
	
	blendFactor *= exp(-length(texCoord - previousCoord.xy) * 280.0) * 0.6 + 0.3;
	
	color = YCgCoToRGB * mix(retColor, tempColor, blendFactor);
	temp = vec4(temp.r, color);
}