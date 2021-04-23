float GetNoise(vec2 pos){
	return fract(sin(dot(pos, vec2(12.9898, 100.1414))) * 43758.5453);
}

void DrawStars(inout vec3 color, vec3 viewPos)
{
    vec3 wpos = vec3(gbufferModelViewInverse * vec4(viewPos, 1.0));
	vec3 planeCoord = wpos / (wpos.y + length(wpos.xz));
	vec2 wind = vec2(frametime, 0.0);
	vec2 coord = planeCoord.xz * 0.4 + cameraPosition.xz * 0.0001 + wind * 0.00125;
	coord = floor(coord * 1024.0) / 1024.0;

	float NdotU = max(dot(normalize(viewPos), normalize(upVec)), 0.0);
	float multiplier = sqrt(sqrt(NdotU)) * 5.0 * (1.0 - rainStrength) * moonVisibility;

	float star = 1.1;
	if (NdotU > 0.0){
		star *= pow(texture2D(noisetex, coord.xy * 100.0).r, 2.0);
	}
	star = clamp(star - 0.8125, 0.0, 1.0) * multiplier;
    star *= sin(frameTimeCounter * 0.5 + (coord.x + coord.y * 1000.0));

	color += star * star * pow(lightNight, vec3(0.8));
}

float hash12(vec2 p)
{
	vec3 p3  = fract(vec3(p.xyx) * .1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

mat2 Rot(float _angle) {
    return mat2(cos(_angle),-sin(_angle),
                sin(_angle),cos(_angle));
}

float saturate(float x) { return clamp(x, 0.0, 1.0); }

#define PI 3.14159265359

vec3 GetShootingStarLayer(in vec3 viewPos, in float time, in float rotationAngle)
{
    float cosT = dot(normalize(viewPos), upVec);

    if(cosT > 0.3) 
    {
        vec3 wpos = vec3(gbufferModelViewInverse * vec4(viewPos, 1.0));
        vec2 coord = wpos.xz + cameraPosition.xz * 0.01 / (wpos.y + length(wpos.xz));
        coord = Rot(rotationAngle) * coord;

        float speedMultiplier = 0.8 + hash12(vec2(floor((coord.x + coord.y) * 0.3 / SHOOTING_STARS_SCALE + 0.5))) * 0.5;
        time *= speedMultiplier * SHOOTING_STARS_SPEED;
        
        coord += vec2(-time, time);

        vec3 result = vec3(0.0);

        // Trail
        vec2 trailGridId = floor(coord * 0.3 / SHOOTING_STARS_SCALE);
        float trailIdHash = hash12(trailGridId);
        float trailBrightness = step(trailIdHash, 0.0001 * SHOOTING_STARS_AMOUNT / float(SHOOTING_STARS_ROTATION_ITERATIONS));

        if(trailBrightness != 0.0) 
        {
            vec2 trailGridUv = fract(coord * 0.3 / SHOOTING_STARS_SCALE);

            float trailLength = sqrt(distance(trailGridUv.x, 0.0) * distance(trailGridUv.y, 1.0));
            float density = distance(trailGridUv.x + trailGridUv.y, 1.0) / trailLength;
            density /= (trailIdHash * 0.5 + 0.5);

            result += smoothstep(0.04, 0.01, density) * trailLength * trailLength * trailBrightness * (trailIdHash * 0.75 + 0.25);   
        }

        // Glare
        vec2 glareGridId = floor(coord * 0.3 / SHOOTING_STARS_SCALE + vec2(-0.5, 0.5));
        float glareIdHash = hash12(glareGridId);
        float glareBrightness = step(glareIdHash, 0.0001 * SHOOTING_STARS_AMOUNT / float(SHOOTING_STARS_ROTATION_ITERATIONS));

        if(glareBrightness != 0.0) 
        {
            vec2 glareGridUv = fract(coord * 0.3 / SHOOTING_STARS_SCALE + 0.5) - 0.5;
            float glare = pow(saturate(0.012 / length(glareGridUv) * smoothstep(0.5, 0.0, length(glareGridUv))), 2.0);
            glare *= cosT * (glareIdHash * 0.75 + 0.25);

            result *= 1. - glare;
            result += glare;
        }

        return result * pow(distance(cosT, 0.3), 2.0);
    }
    
    return vec3(0.0);
}

vec3 DrawShootingStars(in vec3 viewPos, in float time) 
{
    vec3 result;

    for (int i = 0; i < SHOOTING_STARS_ROTATION_ITERATIONS; i++)
    {
        float rotation = float(i) / float(SHOOTING_STARS_ROTATION_ITERATIONS) * PI;
        float n = hash12(vec2(rotation));
        result += GetShootingStarLayer(viewPos, time + n * 320.0, rotation + n);
    }

    return result;
}