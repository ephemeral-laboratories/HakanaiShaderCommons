#ifndef EL_RAYCAST_BASE_STRUCTURES_CGINC_
#define EL_RAYCAST_BASE_STRUCTURES_CGINC_

/**
 * Vertex input structure.
 *
 * Note that the order of these matches that of `UnityStandardInput.cginc`.
 * That is deliberate, so that we can cheatily cast ours to theirs.
 */
struct ELRaycastBaseVertexInput
{
    /**
     * The vertex position in object space.
     */
    float4 objectPos        : POSITION;

    /**
     * The vertex normal in object space.
     */
    float3 objectNormal         : NORMAL;

    /**
     * The vertex texture coordinates.
     */
    float2 texcoord0            : TEXCOORD0;

    /**
     * The vertex texture coordinates.
     */
    float2 texcoord1            : TEXCOORD1;

#if defined(DYNAMICLIGHTMAP_ON) || defined(UNITY_PASS_META)
    /**
     * Not used by us but having it here mirrors VertexInput.
     */
    float2 texcoord2            : TEXCOORD2;
#endif

    /**
     * The vertex tangent in object space.
     */
    float4 objectTangent        : TANGENT;

    /**
     * The vertex color.
     */
    float4 color                : COLOR;
};

/**
 * Fragment input structure.
 */
struct ELRaycastBaseFragmentInput
{
    /**
     * The vertex position in clip space.
     */
    float4 clipPos              : SV_POSITION;
    
    /**
     * The vertex color.
     */
    float4 color                : COLOR;

    /**
     * The vertex position in grab buffer space.
     */
    float4 grabPos              : TEXCOORD0;

    /**
     * The vertex position in object space.
     */
    float4 objectPos            : TEXCOORD1;

    /**
     * The vertex normal in object space.
     */
    float3 objectNormal         : NORMAL;

    /**
     * The origin of the ray in object space.
     */
    float3 objectRayOrigin      : TEXCOORD2;

    /**
     * The direction of the ray in object space.
     */
    float3 objectRayDirection   : TEXCOORD3;

    /**
     * Contains either spherical harmonics or the lightmap UVs.
     */
    float4 ambientOrLightmapUV  : TEXCOORD4;
};

/**
 * Fragment output structure.
 */
struct ELRaycastBaseFragmentOutput
{
    /**
     * The eventual output colour with alpha.
     */
    float4 color    : SV_Target;

    /**
     * The depth into the scene to write the Z buffer, in clip space.
     */
    float clipDepth : SV_Depth;
};

#endif // EL_RAYCAST_BASE_STRUCTURES_CGINC_