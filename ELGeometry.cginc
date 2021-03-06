#ifndef EL_GEOMETRY_CGINC_
#define EL_GEOMETRY_CGINC_

#include "UnityCG.cginc"
#include "ELRaycastBase.cginc"
#include "ELUnityUtilities.cginc"


[maxvertexcount(24)]
void ELGeometryCube(line ELRaycastBaseVertexInput input[2], inout TriangleStream<ELRaycastBaseFragmentInput> triStream)
{
    static const float s = 0.5;
    static const float4 cv[8] = { float4(-s, -s, -s, 1.0),
                                  float4(-s, -s,  s, 1.0),
                                  float4(-s,  s, -s, 1.0),
                                  float4(-s,  s,  s, 1.0),
                                  float4( s, -s, -s, 1.0),
                                  float4( s, -s,  s, 1.0),
                                  float4( s,  s, -s, 1.0),
                                  float4( s,  s,  s, 1.0) };
    static const float t = 0.57735026916;
    static const float4 cn[8] = { float4(-t, -t, -t, 1.0),
                                  float4(-t, -t,  t, 1.0),
                                  float4(-t,  t, -t, 1.0),
                                  float4(-t,  t,  t, 1.0),
                                  float4( t, -t, -t, 1.0),
                                  float4( t, -t,  t, 1.0),
                                  float4( t,  t, -t, 1.0),
                                  float4( t,  t,  t, 1.0) };

    static const uint cf[24] = { 0, 1, 2, 3,    // left
                                 0, 2, 4, 6,    // front  
                                 4, 6, 5, 7,    // right
                                 7, 3, 5, 1,    // back
                                 2, 3, 6, 7,    // top
                                 0, 4, 1, 5  }; // bottom

    ELRaycastBaseVertexInput output = input[0];
    for (int i = 0; i < 6; i++)
    {
        for (int j = 0; j < 4; j++)
        {
            float vi = cf[i * 4 + j];
            output.objectPos = cv[vi];
            output.objectNormal = cn[vi];
            triStream.Append(ELRaycastBaseVertex(output));
        }
        triStream.RestartStrip();
    }
}

#endif // EL_GEOMETRY_CGINC_