#ifndef EL_SCUTTLED_UNITY_LIGHTING_CGINC_
#define EL_SCUTTLED_UNITY_LIGHTING_CGINC_

#include "UnityCG.cginc"
#include "Lighting.cginc"
#include "UnityPBSLighting.cginc"
#include "AutoLight.cginc"              // must be after `UnityPBSLighting` because Unity forgot to include it.
#include "UnityLightingCommon.cginc"
#include "UnityStandardCore.cginc"
#include "ELUnityUtilities.cginc"
#include "ELRaycastBaseInputOutput.cginc"


// Wraps `UNITY_TRANSFER_SHADOW` and `UNITY_LIGHT_ATTENUATION` for abusing to use in fragment shader.
float ELCalculateLightAttenuation(float3 objectPos, float3 worldPos, float4 clipPos)
{
    // Has to be called `v` because `UNITY_TRANSFER_SHADOW` sucks
    struct
    {
        float3 vertex;
    } v;
    v.vertex = objectPos;

    struct
    {
        float4 pos;
        UNITY_SHADOW_COORDS(0)
    } o;
    o.pos = clipPos;
    UNITY_TRANSFER_SHADOW(o, float2(0.0, 0.0));

    UNITY_LIGHT_ATTENUATION(attenuation, o, worldPos);
    return attenuation;
}

// Wraps `UNITY_TRANSFER_FOG` and `UNITY_APPLY_FOG` for abusing to use in fragment shader.
float4 ELCalculateFog(float3 objectPos, float4 clipPos, float4 c)
{
    struct
    {
        float4 pos;
        UNITY_FOG_COORDS(0)
    } o;
    o.pos = clipPos;
    UNITY_TRANSFER_FOG(o, o.pos);

    UNITY_APPLY_FOG(o.fogCoord, c);
    return c;
}

SurfaceOutputStandard ELInitSurfaceOutput(float3 objectNormal)
{
    SurfaceOutputStandard surfaceOutput;
    UNITY_INITIALIZE_OUTPUT(SurfaceOutputStandard, surfaceOutput);
    surfaceOutput.Normal = UnityObjectToWorldNormal(objectNormal);
    surfaceOutput.Occlusion = 1.0;
    return surfaceOutput;
}

// I wanted to write a surface shader, but it turns out you can't write to depth
// from a surface shader. So here we're using as much as possible of the actual surface
// shader / standard lighting code.
float4 ELSurfaceFragment(SurfaceOutputStandard surfaceOutput, ELRaycastBaseFragmentInput input, float3 objectPos, float3 objectNormal)
{
    float3 worldPos = ELObjectToWorldPos(objectPos);
    float3 worldNormal = UnityObjectToWorldNormal(objectNormal);

    //No need to normalize if it's already a directional light.
#ifdef USING_DIRECTIONAL_LIGHT
    float3 worldLightDir = _WorldSpaceLightPos0.xyz;
#else
    float3 worldLightDir = normalize(UnityWorldSpaceLightDir(worldPos));
#endif
    float3 worldViewDir = normalize(UnityWorldSpaceViewDir(worldPos));

    float4 clipPos = UnityObjectToClipPos(float4(objectPos, 1.0));

    float attenuation = ELCalculateLightAttenuation(objectPos, worldPos, clipPos);
    surfaceOutput.Normal = worldNormal;
    UnityGI gi;
    UNITY_INITIALIZE_OUTPUT(UnityGI, gi);
    gi.indirect.diffuse = 0;
    gi.indirect.specular = 0;
    
    //Lighting doesn't look correct when multiplied with attenuation.
    gi.light.color = _LightColor0.rgb;// * attenuation;
    gi.light.dir = worldLightDir;

#ifdef UNITY_PASS_FORWARDBASE

    UnityGIInput giInput;
    UNITY_INITIALIZE_OUTPUT(UnityGIInput, giInput);
    giInput.light = gi.light;
    giInput.worldPos = worldPos;
    giInput.worldViewDir = worldViewDir;
    giInput.atten = attenuation;

    #if defined(LIGHTMAP_ON) || defined(DYNAMICLIGHTMAP_ON)
        giInput.lightmapUV = input.lmap;
    #else
        giInput.lightmapUV = 0.0;
    #endif

    #if UNITY_SHOULD_SAMPLE_SH && !UNITY_SAMPLE_FULL_SH_PER_PIXEL
        #ifdef SPHERICAL_HARMONICS_PER_PIXEL
        giInput.ambient = ShadeSHPerPixel(worldNormal, 0.0, worldPos);
        #else
        giInput.ambient.rgb = input.sh;
        #endif
    #else
        giInput.ambient.rgb = 0.0;
    #endif

    giInput.probeHDR[0] = unity_SpecCube0_HDR;
    giInput.probeHDR[1] = unity_SpecCube1_HDR;
    #if defined(UNITY_SPECCUBE_BLENDING) || defined(UNITY_SPECCUBE_BOX_PROJECTION)
        giInput.boxMin[0] = unity_SpecCube0_BoxMin;
    #endif
    #ifdef UNITY_SPECCUBE_BOX_PROJECTION
        giInput.boxMax[0] = unity_SpecCube0_BoxMax;
        giInput.probePosition[0] = unity_SpecCube0_ProbePosition;
        giInput.boxMax[1] = unity_SpecCube1_BoxMax;
        giInput.boxMin[1] = unity_SpecCube1_BoxMin;
        giInput.probePosition[1] = unity_SpecCube1_ProbePosition;
    #endif
    LightingStandard_GI(surfaceOutput, giInput, gi);

#endif // UNITY_PASS_FORWARDBASE

    float4 colour = LightingStandard(surfaceOutput, worldViewDir, gi);

    #ifdef UNITY_PASS_FORWARDBASE
        colour.rgb += surfaceOutput.Emission;
    #endif

    colour = ELCalculateFog(objectPos, clipPos, colour);
    return colour;
}

#endif // EL_SCUTTLED_UNITY_LIGHTING_CGINC_