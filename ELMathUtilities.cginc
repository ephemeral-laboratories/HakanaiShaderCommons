#ifndef EL_MATH_UTILITIES_CGINC_
#define EL_MATH_UTILITIES_CGINC_

#define EL_PHI (sqrt(5.0) * 0.5 + 0.5)

/**
 * Performs a matrix inverse.
 *
 * @param input the input matrix.
 * @return the inverted matrix. If the matrix is not invertible the behaviour is undefined.
 */
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

/**
 * Creates a 2D rotation matrix rotating around the origin by the specified amount.
 *
 * @param angle the angle in radians.
 * @return the matrix.
 */
float2x2 ELRotationMatrix(float angle)
{
    float sina, cosa;
    sincos(angle, sina, cosa);
    return float2x2(cosa, -sina, sina, cosa);
}

/**
 * Creates a 3D rotation matrix rotating around the X axis by the specified amount.
 *
 * @param angle the angle in radians.
 * @return the matrix.
 */
float3 ELRotateAroundXInDegrees(float3 vertex, float angle)
{
    float2x2 m = ELRotationMatrix(radians(angle));
    return float3(vertex.x, mul(m, vertex.yz));
}

/**
 * Creates a 3D rotation matrix rotating around the Y axis by the specified amount.
 *
 * @param angle the angle in radians.
 * @return the matrix.
 */
float3 ELRotateAroundYInDegrees(float3 vertex, float angle)
{
    float2x2 m = ELRotationMatrix(radians(angle));
    return float3(mul(m, vertex.xz), vertex.y).xzy;
}

/**
 * Creates a 3D rotation matrix rotating around the Z axis by the specified amount.
 *
 * @param angle the angle in radians.
 * @return the matrix.
 */
float3 ELRotateAroundZInDegrees(float3 vertex, float angle)
{
    float2x2 m = ELRotationMatrix(radians(angle));
    return float3(mul(m, vertex.xy), vertex.z);
}

/**
 * Converts polar coordinates to Cartesian coordinates.
 *
 * @param radius the radius.
 * @param angle the angle.
 * @return the X-Y coordinates.
 */
float2 ELPolarToCartesian(float radius, float angle)
{
    float2 sin_cos;
    sincos(angle, sin_cos[1], sin_cos[0]);
    return sin_cos * radius;
}

/**
 * Corrected modulus operator.
 *
 * @param dividend the dividend.
 * @param divisor the divisor.
 * @return the non-negative remainder `<` the divisor.
 */
float ELMod(float dividend, float divisor)
{
    return dividend - divisor * floor(dividend / divisor);
}
float2 ELMod(float2 dividend, float2 divisor)
{
    return dividend - divisor * floor(dividend / divisor);
}
float3 ELMod(float3 dividend, float3 divisor)
{
    return dividend - divisor * floor(dividend / divisor);
}

// https://en.wikipedia.org/wiki/Smoothstep#Variations
float ELSmootherStep(float edge0, float edge1, float x) {
    x = clamp((x - edge0) / (edge1 - edge0), 0.0, 1.0);
    return x * x * x * (x * (x * 6. - 15.) + 10.);
}

#endif // EL_MATH_UTILITIES_CGINC_