
/* 
----------------------------------------------------------------
Lux Shader by https://github.com/TechDevOnGithub/
Based on BSL Shaders v7.1.05 by Capt Tatsu https://bitslablab.com 
See AGREEMENT.txt for more information.
----------------------------------------------------------------
*/ 

const float starAmount = 0.16;
void DrawStars(inout vec3 color, vec3 viewPos)
{
    vec3 wpos = vec3(gbufferModelViewInverse * vec4(viewPos, 1.0));
	vec3 planeCoord = wpos / (wpos.y + length(wpos.xz));
	vec2 wind = vec2(frametime, 0.0);

	vec2 gridCoord = planeCoord.xz * 0.4 + cameraPosition.xz * 0.0001 + wind * 0.00125;
    vec2 gridID = gridCoord;
    
    gridID = floor(gridCoord * 1024.0) / 1024.0;
    gridCoord = fract(gridCoord * 1024.0);

    vec3 star = vec3(1.0);
    star *= Max0(1.0 - dot(gridCoord - 0.5, gridCoord - 0.5) * 4.0);

    float starMultiplier = Pow2(Max0(texture2D(noisetex, gridID * 100.0).r - (1.0 - starAmount))) / starAmount * 4.0;
    star *= starMultiplier;
    star *= 1.0 + sqrt(moonHeight) * 4.0;

    float NdotU = max(dot(normalize(viewPos), normalize(upVec)), 0.0);
    float horizonMultiplier = 1.0 - Pow2(1.0 - NdotU);
    star *= horizonMultiplier;

	color += star * pow(lightNight, vec3(0.8)) / GetLuminance(pow(lightNight, vec3(0.8)));
}

mat2 Rot(float _angle) 
{
    return mat2(cos(_angle),-sin(_angle), sin(_angle),cos(_angle));
}

vec3 GetShootingStarLayer(in vec3 viewPos, in float time, in float rotationAngle)
{
    float cosT = dot(normalize(viewPos), upVec);

    if(cosT > 0.2)
    {
        vec3 wpos = vec3(gbufferModelViewInverse * vec4(viewPos, 1.0));
        vec2 coord = wpos.xz + cameraPosition.xz * 0.01 / (wpos.y + length(wpos.xz));
        coord *= 0.8;
        coord = Rot(rotationAngle) * coord;

        float speedMultiplier = 0.8 + Hash(vec2(floor((coord.x + coord.y) * 0.3 / SHOOTING_STARS_SCALE + 0.5))) * 0.5;
        time *= speedMultiplier * SHOOTING_STARS_SPEED * SHOOTING_STARS_SCALE;

        coord += vec2(-time, time);

        vec3 result = vec3(0.0);

        // Trail
        vec2 trailGridId = floor(coord * 0.3 / SHOOTING_STARS_SCALE);
        float trailIdHash = Hash(trailGridId);
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
        float glareIdHash = Hash(glareGridId);
        float glareBrightness = step(glareIdHash, 0.0001 * SHOOTING_STARS_AMOUNT / float(SHOOTING_STARS_ROTATION_ITERATIONS));

        if(glareBrightness != 0.0)
        {
            vec2 glareGridUv = fract(coord * 0.3 / SHOOTING_STARS_SCALE + 0.5) - 0.5;
            float glare = Pow2(Saturate(0.012 / length(glareGridUv) * smoothstep(0.5, 0.0, length(glareGridUv))));
            glare *= cosT * (glareIdHash * 0.75 + 0.25);

            result *= 1. - glare;
            result += glare;
        }

        return result * (1. - rainStrength) * smoothstep(0.3, 1.0, cosT) * pow(lightNight, vec3(0.8));
    }

    return vec3(0.0);
}

vec3 DrawShootingStars(in vec3 viewPos, in float time)
{
    vec3 result;

    for (int i = 0; i < SHOOTING_STARS_ROTATION_ITERATIONS; i++)
    {
        float rotation = float(i) / float(SHOOTING_STARS_ROTATION_ITERATIONS) * PI;
        float n = Hash(vec2(rotation));
        result += GetShootingStarLayer(viewPos, time * 0.9 + n * 320.0, rotation + n);
    }

    return result * 1.4;

    // float cosT = dot(normalize(viewPos), upVec);
	
    // vec3 shootingStars;
	
    // if (cosT > 0.1)
    // {
    //     vec3 wpos = vec3(gbufferModelViewInverse * vec4(viewPos, 1.0));
    //     vec2 wind = vec2(frametime, 0.0);
    //     vec2 coord = (wpos.xz / (wpos.y + length(wpos.xz) * 0.6) * 0.4 + cameraPosition.xz * 0.0001 + wind * 0.00125) * 100.0;
	
    //     vec2 ratio = vec2(0.05, 1.6);
	
    //     coord *= ratio;
	
    //     vec2 gridUv = fract(coord);
    //     vec2 gridID = floor(coord);
	
    //     float idHash = Hash(gridID);
	
    //     float time = frameTimeCounter * (step(idHash, 0.5) * 6.0 - 3.0) * 2.0;
	
    //     vec2 trailCoord = gridUv.xx + time + idHash * 123.4287;
    //     vec2 trailUv = fract(trailCoord);
    //     vec2 trailID = floor(trailCoord);
	
    //     float trailMult = trailUv.x * trailUv.x;
    //     float mult = pow(sin(gridUv.x * PI), 2.0 / ratio.y) * pow(sin(gridUv.y * PI), 2.0 / ratio.x / trailMult) * pow(sin(trailUv.x * PI), 2.0 / ratio.y);
    //     mult *= trailMult * trailMult;
	
    //     float noise = Hash(trailID * 137.33);
	
    //     shootingStars += (1.0 - step(1.0, noise * 1000.0));
    //     shootingStars *= mult;
    //     shootingStars *= (1. - rainStrength) * smoothstep(0.2, 1.0, cosT);
    // }
	
    // return shootingStars;
}
