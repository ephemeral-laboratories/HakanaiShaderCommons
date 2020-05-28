#ifndef EL_RAYMARCH_BASE_CGINC
#define EL_RAYMARCH_BASE_CGINC

#include "ELRaycastBaseStructures.cginc"
#include "ELScuttledUnityLighting.cginc"

struct ELRay
{
    float3 start;
    float3 dir;
    float t;
    float3 pos;
};

ELRaycastBaseFragmentInput ELRaymarchBaseVertex(ELRaycastBaseVertexInput input)
{
    ELRaycastBaseFragmentInput output;
    UNITY_INITIALIZE_OUTPUT(ELRaycastBaseFragmentInput, output);
    output.pos = UnityObjectToClipPos(input.vertex);
    output.grabPos = ComputeGrabScreenPos(output.pos);
    output.objectPos = input.vertex;
    output.objectNormal = input.normal;
    if (UNITY_MATRIX_P[3][3] == 1.0)
    {
        output.objectRayDir = ELWorldToObjectNormal(-UNITY_MATRIX_V[2].xyz);
        output.objectRayStart = input.vertex - normalize(output.objectRayDir);
    }
    else
    {
        output.objectRayStart = ELWorldToObjectPos(UNITY_MATRIX_I_V._m03_m13_m23);
        output.objectRayDir = input.vertex - output.objectRayStart;
    }
    return output;
}

ELRaycastBaseFragmentInput ELGeometryBuildVaryings(float4 vertex)
{
    ELRaycastBaseFragmentInput output;
    UNITY_INITIALIZE_OUTPUT(ELRaycastBaseFragmentInput, output);
    output.pos = UnityObjectToClipPos(vertex);

    // Variables like `unity_OrthoParams` and `_WorldSpaceCameraPos` lie, but the
    // transform matrices don't lie, so we can just use those for everything.
    if (UNITY_MATRIX_P[3][3] == 1.0)
    {
        // Orthographic case - `-UNITY_MATRIX_V[2]` is camera forward vector
        output.objectRayDir = ELWorldToObjectNormal(-UNITY_MATRIX_V[2].xyz);
        output.objectRayStart = vertex - normalize(output.objectRayDir);
    }
    else
    {
        // Perspective case - `UNITY_MATRIX_I_V._m03_m13_m23` is camera position
        output.objectRayStart = ELWorldToObjectPos(UNITY_MATRIX_I_V._m03_m13_m23);
        output.objectRayDir = vertex - output.objectRayStart;
    }

    return output;
}

[maxvertexcount(24)]
void ELGeometryCube(line ELRaycastBaseVertexInput input[2], inout TriangleStream<ELRaycastBaseFragmentInput> triStream)
{
    // float4 v1 = min(input[0].vertex, input[1].vertex);
    // float4 v2 = max(input[0].vertex, input[1].vertex);
    // float4 cv[8] = { float4(v1.x, v1.y, v1.z, 0.0),
    //                  float4(v1.x, v1.y, v2.z, 0.0),
    //                  float4(v1.x, v2.y, v1.z, 0.0),
    //                  float4(v1.x, v2.y, v2.z, 0.0),
    //                  float4(v2.x, v1.y, v1.z, 0.0),
    //                  float4(v2.x, v1.y, v2.z, 0.0),
    //                  float4(v2.x, v2.y, v1.z, 0.0),
    //                  float4(v2.x, v2.y, v2.z, 0.0) };
     static const float4 cv[8] = { float4(-0.5, -0.5, -0.5, 1.0),
                                   float4(-0.5, -0.5,  0.5, 1.0),
                                   float4(-0.5,  0.5, -0.5, 1.0),
                                   float4(-0.5,  0.5,  0.5, 1.0),
                                   float4( 0.5, -0.5, -0.5, 1.0),
                                   float4( 0.5, -0.5,  0.5, 1.0),
                                   float4( 0.5,  0.5, -0.5, 1.0),
                                   float4( 0.5,  0.5,  0.5, 1.0) };

    static const uint cf[24] = { 0, 1, 2, 3,    // left
                                 0, 2, 4, 6,    // front  
                                 4, 6, 5, 7,    // right
                                 7, 3, 5, 1,    // back
                                 2, 3, 6, 7,    // top
                                 0, 4, 1, 5  }; // bottom

    for (int i = 0; i < 6; i++)
    {
        triStream.Append(ELGeometryBuildVaryings(cv[cf[i * 4]]));
        triStream.Append(ELGeometryBuildVaryings(cv[cf[i * 4 + 1]]));
        triStream.Append(ELGeometryBuildVaryings(cv[cf[i * 4 + 2]]));
        triStream.Append(ELGeometryBuildVaryings(cv[cf[i * 4 + 3]]));
        triStream.RestartStrip();
    }
}

ELRay ELGetRay(ELRaycastBaseFragmentInput input)
{
    ELRay ray;
    ray.start = input.objectRayStart;
    ray.dir = normalize(input.objectRayDir);
	ray.t = 0.0;
    ray.pos = ray.start;
    return ray;
}

void ELAdvanceRay(inout ELRay ray, float dt)
{
    ray.t += dt;
    ray.pos = ray.start + ray.dir * ray.t;
}

float2 ELMap(float3 objectPos);

float3 ELRaymarchNormal(in float3 objectPos)
{
    static const float2 e = fixed2(0.000001, -0.000001);
    return normalize(e.xyy * ELMap(objectPos + e.xyy).x +
                     e.yyx * ELMap(objectPos + e.yyx).x +
                     e.yxy * ELMap(objectPos + e.yxy).x +
                     e.xxx * ELMap(objectPos + e.xxx).x);
}

#define MAX_STEPS 200
// #define MAX_STEPS 80
#define MIN_DISTANCE 0.00001
#define MAX_DISTANCE 200.0

bool ELRaymarch(ELRay ray, out float3 objectPos, out float material)
{
    float2 mapResult;

    for (uint i = 0; i < MAX_STEPS; i++)
    {
        mapResult = ELMap(ray.pos);
        objectPos = ray.pos;

        if (mapResult.x > MAX_DISTANCE)
        {
            return false;
        }

        ELAdvanceRay(ray, mapResult.x);

        if (mapResult.x < MIN_DISTANCE)
        {
            material = mapResult.y;
            return true;
        }
    }

    material = mapResult.y;
    return true;
}

void ELDecodeMaterial(ELRaycastBaseFragmentInput input, float material, inout SurfaceOutputStandard output);

bool ELFragmentRaymarch(ELRaycastBaseFragmentInput input, out float3 objectPos, out float material)
{
    return ELRaymarch(ELGetRay(input), objectPos, material);
}

SurfaceOutputStandard ELRaymarchSurface(ELRaycastBaseFragmentInput input, out float3 objectPos, out float3 objectNormal)
{
    float material;
    bool hit = ELFragmentRaymarch(input, objectPos, material);

    // Save lighting calculations when not hit
    UNITY_BRANCH
    if (!hit)
    {
        clip(-1.0);
    }

    objectNormal = ELRaymarchNormal(objectPos);

    SurfaceOutputStandard output;
    UNITY_INITIALIZE_OUTPUT(SurfaceOutputStandard, output);
    output.Normal = UnityObjectToWorldNormal(objectNormal);
    output.Occlusion = 1.0;
    ELDecodeMaterial(input, material, output);

    return output;
}

ELRaycastBaseFragmentOutput ELRaymarchFragment(ELRaycastBaseFragmentInput input)
{
    float3 objectPos;
    float3 objectNormal;
    SurfaceOutputStandard surfaceOutput = ELRaymarchSurface(input, objectPos, objectNormal);

    ELRaycastBaseFragmentOutput output;
    output.color = ELSurfaceFragment(surfaceOutput, objectPos, objectNormal);

    float4 clipPos = UnityObjectToClipPos(float4(objectPos, 1.0));
    output.clipDepth = clipPos.z / clipPos.w;

    return output;
}

float4 ELRaymarchShadowCasterFragment(ELRaycastBaseFragmentInput input) : SV_Target
{
    float3 objectPos;
    float materialUnused;
    bool hit = ELFragmentRaymarch(input, objectPos, materialUnused);
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

#endif