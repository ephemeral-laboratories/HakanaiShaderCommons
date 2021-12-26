#ifndef EL_RAYCAST_BASE_STRUCTURES_CGINC_
#define EL_RAYCAST_BASE_STRUCTURES_CGINC_

/**
 * Vertex input structure.
 */
struct ELRaycastBaseVertexInput
{
    /**
     * The vertex position in object space.
     */
    float4 objectPos : POSITION;

    /**
     * The vertex normal in object space.
     */
    float3 objectNormal : NORMAL;

    /**
     * The vertex tangent in object space.
     */
    float4 objectTangent : TANGENT;

    /**
     * The vertex color.
     */
    float4 color : COLOR;

    /**
     * The vertex texture coordinates.
     */
    float2 texcoord : TEXCOORD0;

    /**
     * The second vertex texture coordinates, used for light mapping.
     */
    float2 texcoord1 : TEXCOORD1;
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
     * UV for light mapping.
     */    
    float4 lightMapUV : TEXCOORD4;

#if !defined(LIGHTMAP_ON) && UNITY_SHOULD_SAMPLE_SH
    /**
     * Spherical harmonics.
     */
    half3 sh : TEXCOORD5;
#endif
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