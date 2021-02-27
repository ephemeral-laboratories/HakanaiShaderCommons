#ifndef EL_RAYCAST_BASE_CGINC_
#define EL_RAYCAST_BASE_CGINC_

#include "ELRaycastBaseInputOutput.cginc"
#include "ELRaycastBaseRays.cginc"
#include "ELScuttledUnityLighting.cginc"

// Workaround for `SHADOW_COORDS` being missing for shadowcaster pass 
#if defined (SHADOWS_DEPTH) && !defined (SPOT) 
    #define SHADOW_COORDS(idx1) unityShadowCoord2 _ShadowCoord : TEXCOORD##idx1; 
#endif 

/**
 * Vertex shader.
 *
 * @param input the vertex input structure.
 * @return the structure for input to the fragment shader.
 */
ELRaycastBaseFragmentInput ELRaycastBaseVertex(ELRaycastBaseVertexInput input)
{
    ELRaycastBaseFragmentInput output;
    UNITY_INITIALIZE_OUTPUT(ELRaycastBaseFragmentInput, output);
    output.clipPos = UnityObjectToClipPos(input.objectPos);
    output.grabPos = ComputeGrabScreenPos(output.clipPos);
    output.objectPos = input.objectPos;
    output.objectNormal = input.objectNormal;
    output.color = input.color;
    float3 worldPos = mul(unity_ObjectToWorld, input.objectPos).xyz;
    float3 worldNormal = UnityObjectToWorldNormal(input.objectNormal);

    // Determining whether the projection is isometric.
    // Variables like `unity_OrthoParams` and `_WorldSpaceCameraPos` lie about
    // the position of the camera, but the transform matrices don't lie. Can't lie.
    // so we can just use those for everything.
    if (UNITY_MATRIX_P[3][3] == 1.0)
    {
        // Orthographic case - `-UNITY_MATRIX_V[2]` is camera forward vector
        output.objectRayDirection = ELWorldToObjectNormal(-UNITY_MATRIX_V[2].xyz);
        output.objectRayOrigin = input.objectPos - normalize(output.objectRayDirection);
    }
    else
    {
        // Perspective case - `UNITY_MATRIX_I_V._m03_m13_m23` is camera position
        output.objectRayOrigin = ELWorldToObjectPos(UNITY_MATRIX_I_V._m03_m13_m23);
        output.objectRayDirection = input.objectPos - output.objectRayOrigin;
    }

    #if !defined(SPHERICAL_HARMONICS_PER_PIXEL)
        #ifndef LIGHTMAP_ON
            #if UNITY_SHOULD_SAMPLE_SH
                output.sh = 0;
                #ifdef VERTEXLIGHT_ON
                    output.sh += Shade4PointLights(
                        unity_4LightPosX0, 
                        unity_4LightPosY0, 
                        unity_4LightPosZ0,
                        unity_LightColor[0].rgb, 
                        unity_LightColor[1].rgb, 
                        unity_LightColor[2].rgb, 
                        unity_LightColor[3].rgb,
                        unity_4LightAtten0, 
                        worldPos, 
                        worldNormal);
                #endif
                output.sh = ShadeSHPerVertex(worldNormal, output.sh);
            #endif
        #endif
    #endif    

    return output;
}

/**
 * _Pseudo-abstract method, to be implemented by consumers._
 *
 * This method is called to cast the ray into the scene.
 * The scene must populate the output parameters if the ray hits an object in the scene.
 *
 * @param ray the ray cast.
 * @param objectPos [out] the position in object space at which the ray hit, if it hit.
 * @param objectNormal [out] the normal of the surface at the position the ray hit, in object space, if it hit.
 * @param material [out] a floating point value in which to store differentiating material information,
 *        later used in {@link ELDecodeMaterial}.
 * @return {@code true} if the ray hit. {@code false} otherwise.
 */
bool ELRaycast(ELRay ray, out float3 objectPos, out float3 objectNormal, out float material);

/**
 * _Pseudo-abstract method, to be implemented by consumers._
 *
 * This method is called to convert a simple floating point value returned from {@link ELRaycast}
 * into a {@link SurfaceOutputStandard} structure.
 *
 * @param input the fragment input structure.
 * @param material [out] a floating point value returned from {@link ELRaycast} used to store
 *        differentiating material information.
 */
void ELDecodeMaterial(ELRaycastBaseFragmentInput input, float material, inout SurfaceOutputStandard output);

/**
 * Given a ray entering the object, figure out what it hits and where.
 *
 * @param input the fragment input structure.
 * @param objectPos [out] the position the ray hit, in object space.
 * @param objectNormal [out] the normal of the surface at the position the ray hit, in object space.
 * @param material [out] a floating point value in which to store differentiating material information,
 *        later used in {@link ELDecodeMaterial}.
 * @return {@code true} if the ray hit, {@code false} otherwise.
 */
bool ELFragmentRaycast(ELRaycastBaseFragmentInput input, out float3 objectPos, out float3 objectNormal, out float material)
{
    return ELRaycast(ELGetRay(input), objectPos, objectNormal, material);
}

/**
 * Given a ray entering the object, figure out what it hits and return the surface properties.
 *
 * This is split into two parts.
 * In the first part, we call {@link ELRaycastSurface} to get where and what the ray hit.
 * In the second part, we decode the value returned for the material and use it to set up the surface parameters.
 *
 * @param input the fragment input structure.
 * @param objectPos [out] the position the ray hit, in object space.
 * @param objectNormal [out] the normal of the surface at the position the ray hit, in object space.
 * @return a 
 */
SurfaceOutputStandard ELRaycastSurface(ELRaycastBaseFragmentInput input, out float3 objectPos, out float3 objectNormal)
{
    float material;
    bool hit = ELFragmentRaycast(input, objectPos, objectNormal, material);

    // Save lighting calculations when not hit
    UNITY_BRANCH
    if (!hit)
    {
        clip(-1.0);
        // TODO: Should be returning here!
    }

    SurfaceOutputStandard output;
    UNITY_INITIALIZE_OUTPUT(SurfaceOutputStandard, output);
    output.Normal = UnityObjectToWorldNormal(objectNormal);
    output.Occlusion = 1.0;
    ELDecodeMaterial(input, material, output);

    return output;
}

/**
 * Fragment shader.
 *
 * @param input the fragment input structure.
 * @return the fragment output structure.
 */
ELRaycastBaseFragmentOutput ELRaycastFragment(ELRaycastBaseFragmentInput input)
{
    float3 objectPos;
    float3 objectNormal;
    SurfaceOutputStandard surfaceOutput = ELRaycastSurface(input, objectPos, objectNormal);

    ELRaycastBaseFragmentOutput output;
    output.color = ELSurfaceFragment(surfaceOutput, input, objectPos, objectNormal);

    float4 clipPos = UnityObjectToClipPos(float4(objectPos, 1.0));
    output.clipDepth = clipPos.z / clipPos.w;

    return output;
}

/**
 * Fragment shader for the shadow caster pass.
 *
 * @param input the fragment input structure.
 * @return the fragment output structure.
 */
float4 ELRaycastShadowCasterFragment(ELRaycastBaseFragmentInput input) : SV_Target
{
    float3 objectPos;
    float3 objectNormalUnused;
    float materialUnused;
    bool hit = ELFragmentRaycast(input, objectPos, objectNormalUnused, materialUnused);
    clip(hit ? 1.0 : -1.0);

    // Has to be called `v` because `TRANSFER_SHADOW_CASTER` sucks
    struct
    {
        float4 vertex;
    } v;
    v.vertex = float4(objectPos, 1.0);

    struct
    {
        V2F_SHADOW_CASTER;
    } output;
    TRANSFER_SHADOW_CASTER(output);

    SHADOW_CASTER_FRAGMENT(output);
}

#endif // EL_RAYCAST_BASE_CGINC_