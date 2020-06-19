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
    float4 objectPos        : POSITION;

    /**
     * The vertex normal in object space.
     */
    float3 objectNormal     : NORMAL;

    /**
     * The vertex tangent in object space.
     */
    float4 objectTangent    : TANGENT;

    /**
     * The vertex color.
     */
    float4 color            : COLOR;

    /**
     * The vertex texture coordinates.
     */
    float2 texcoord         : TEXCOORD0;
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