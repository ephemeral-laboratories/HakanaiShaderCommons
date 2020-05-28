#ifndef EL_MATH_UTILITIES_CGINC_
#define EL_MATH_UTILITIES_CGINC_

float4x4 ELMatrixInverse(float4x4 input)
{
    #define minor(a, b, c) determinant(float3x3(input.a, input.b, input.c))
   
    float4x4 cofactors = float4x4(
        minor(_22_23_24, _32_33_34, _42_43_44), 
       -minor(_21_23_24, _31_33_34, _41_43_44),
        minor(_21_22_24, _31_32_34, _41_42_44),
       -minor(_21_22_23, _31_32_33, _41_42_43),
       
       -minor(_12_13_14, _32_33_34, _42_43_44),
        minor(_11_13_14, _31_33_34, _41_43_44),
       -minor(_11_12_14, _31_32_34, _41_42_44),
        minor(_11_12_13, _31_32_33, _41_42_43),
       
        minor(_12_13_14, _22_23_24, _42_43_44),
       -minor(_11_13_14, _21_23_24, _41_43_44),
        minor(_11_12_14, _21_22_24, _41_42_44),
       -minor(_11_12_13, _21_22_23, _41_42_43),
       
       -minor(_12_13_14, _22_23_24, _32_33_34),
        minor(_11_13_14, _21_23_24, _31_33_34),
       -minor(_11_12_14, _21_22_24, _31_32_34),
        minor(_11_12_13, _21_22_23, _31_32_33));

   #undef minor
   return transpose(cofactors) / determinant(input);
}

float2x2 ELRotationMatrix(float radians)
{
    float sina, cosa;
    sincos(radians, sina, cosa);
    return float2x2(cosa, -sina, sina, cosa);
}

float3 ELRotateAroundYInDegrees(float3 vertex, float degrees)
{
    float2x2 m = ELRotationMatrix(radians(degrees));
    return float3(mul(m, vertex.xz), vertex.y).xzy;
}

float3 ELRotateAroundZInDegrees(float3 vertex, float degrees)
{
    float2x2 m = ELRotationMatrix(radians(degrees));
    return float3(mul(m, vertex.xy), vertex.z);
}

#endif // EL_MATH_UTILITIES_CGINC_