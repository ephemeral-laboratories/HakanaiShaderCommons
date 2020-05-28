#ifndef EL_GEOMETRY_CGINC_
#define EL_GEOMETRY_CGINC_

#include "UnityCG.cginc"
#include "ELRaycastBaseInputOutput.cginc"
#include "ELUnityUtilities.cginc"

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

#endif // EL_GEOMETRY_CGINC_