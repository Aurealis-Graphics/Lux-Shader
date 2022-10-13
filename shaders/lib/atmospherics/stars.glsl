
/* 
----------------------------------------------------------------
Lux Shader by https://github.com/TechDevOnGithub/
Based on BSL Shaders v7.1.05 by Capt Tatsu https://bitslablab.com 
See AGREEMENT.txt for more information.
----------------------------------------------------------------
*/ 

/* Based on: https://github.com/Jessie-LC/open-source-utility-code/blob/main/advanced/blackbody.glsl */
vec3 PlancksLaw(in float T, in vec3 primaries) 
{
    vec3 frac1 = 2.0 * H * Pow2(C) / Pow5(primaries);
    vec3 frac2 = exp(H * C / (primaries * K * T)) - 1.0;
    return (frac1 / frac2) * Pow2(1e9);
}

vec3 RadiationBlackbody(in float T) 
{
    vec3 radiation = PlancksLaw(T, vec3(700.0, 546.1, 435.8));
    return radiation / MaxOf(radiation);
}

const float starAmount = 0.16;
void DrawStars(inout vec3 color, vec3 viewPos)
{
    float starMultiplier = 1.0 + (1.0 - Pow6(1.0 - moonHeight)) * 5.0;

    if (starMultiplier < 1e-3) return;

    float NdotU = max(dot(normalize(viewPos), normalize(upVec)), 0.0);
    float horizonMultiplier = NdotU * (2.0 - NdotU);

    if (horizonMultiplier < 1e-3) return;

    vec3 worldPos = vec3(gbufferModelViewInverse * vec4(viewPos, 1.0));
	vec3 planeCoord = worldPos / (worldPos.y + length(worldPos.xz));
	vec2 wind = vec2(frametime, 0.0);

	vec2 gridCoord = planeCoord.xz * 0.4 + cameraPosition.xz * 0.0001 + wind * 0.00125;
    vec2 gridID = gridCoord;
    
    gridID = floor(gridCoord * 1024.0) / 1024.0;
    gridCoord = fract(gridCoord * 1024.0) - 0.5;

    vec3 star = vec3(Max0(1.0 - dot(gridCoord, gridCoord) * 4.0));

    starMultiplier *= Pow2(Max0(texture2D(noisetex, gridID * 100.0).r - (1.0 - starAmount))) / starAmount * 4.0;
    starMultiplier *= Pow5(Smooth3(1.0 - rainStrength));
    
    star *= starMultiplier;
    star *= horizonMultiplier;
    star *= RadiationBlackbody(Hash21(gridID * 1258.35) * 37000.0 + 3000.0);

	color += star;
}

mat2 Rot(float _angle) 
{
    return mat2(cos(_angle),-sin(_angle), sin(_angle),cos(_angle));
}

vec3 GetShootingStarLayer(in vec3 viewPos, in float time, in float rotationAngle)
{
    float cosT = dot(normalize(viewPos), upVec);

    if(cosT > 0.3)
    {
        vec3 wpos = vec3(gbufferModelViewInverse * vec4(viewPos, 1.0));
        vec2 coord = wpos.xz + cameraPosition.xz * 0.01 / (wpos.y + length(wpos.xz));
        coord *= 0.8;
        coord = Rot(rotationAngle) * coord;

        float speedMultiplier = 0.8 + Hash11(floor((coord.x + coord.y) * 0.3 / SHOOTING_STARS_SCALE + 0.5)) * 0.5;
        time *= speedMultiplier * SHOOTING_STARS_SPEED * SHOOTING_STARS_SCALE;

        coord += vec2(-time, time);

        vec3 result = vec3(0.0);

        // Trail
        vec2 trailGridId = floor(coord * 0.3 / SHOOTING_STARS_SCALE);
        float trailIdHash = Hash21(trailGridId);
        float trailBrightness = step(trailIdHash, 0.0001 * SHOOTING_STARS_AMOUNT / float(SHOOTING_STARS_ROTATION_ITERATIONS));

        if(trailBrightness != 0.0)
        {
            vec2 trailGridUv = fract(coord * 0.3 / SHOOTING_STARS_SCALE);

            float trailLength = sqrt(distance(trailGridUv.x, 0.0) * distance(trailGridUv.y, 1.0));
            float density = distance(trailGridUv.x + trailGridUv.y, 1.0) / trailLength;
            density /= (trailIdHash * 0.5 + 0.5);

            result += smoothstep(0.04, 0.01, density) * trailLength * trailLength * trailBrightness * (trailIdHash * 0.75 + 0.25);
        }

        return result * (1. - rainStrength) * smoothstep(0.3, 1.0, cosT) * Lift(lightNight, 0.36);
    }

    return vec3(0.0);
}

vec3 DrawShootingStars(in vec3 viewPos, in float time)
{
    vec3 result;

    for (int i = 0; i < SHOOTING_STARS_ROTATION_ITERATIONS; i++)
    {
        float rotation = float(i) / float(SHOOTING_STARS_ROTATION_ITERATIONS) * PI;
        float n = Hash11(rotation);
        result += GetShootingStarLayer(viewPos, time * 0.9 + n * 320.0, rotation + n);
    }

    return result * 2.5;
}
