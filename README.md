# Hakanai Shader Commons

This repo contains common code that I keep using over and over in Unity shaders.

It is designed to be pulled into other projects as a git submodule.

[Examples of usage can be found here.](https://github.com/ephemeral-laboratories/HakanaiShaderCommonsExamples)

## Getting Started

From Unity's Package Manager pane, click the plus sign and choose
"Add package from git URL..."

Enter the following URL:

**https<span>:</span>//github.com/ephemeral-laboratories/HakanaiShaderCommons.git#v<var>X.Y.Z</var>**

Replace _X.Y.Z_ with the version you want to use, hopefully the latest.

Usage in Unity:

* **Assets→Create→Shader→EL Raycast Shader**, **Assets→Create→Shader→EL Raymarch Shader**
  menu items will create a new shader of the respective type from a basic
  template.
* Right-click your new shader, **Create→Material**
* **File→New Scene**
* **GameObject→3D Object→Cube**
* Assign your material to the cube
* You should now see a sphere. Edit your shader to make something more interesting. :)

## A Quick Tour

Functions are generally prefixed with `EL` to avoid any future clashes
with Unity function names or other people's utilities.

Functions have been grouped into files roughly by theme.

Filling in utility methods which could be provided by Unity but seemingly
weren't, or just generally enhancing quality of life:

* `ELMathUtilities.cginc` - general matrix utilities.
* `ELUnityUtilities.cginc` - utilities using Unity transforms.
* `ELScuttledUnityLighting.cginc` - Wrappers around annoying Unity macros
  and generated surface shader code to allow them to be used as normal
  functions.

Libraries of generally useful stuff:

* `ELDistanceFunctions.cginc` - distance functions scuttled from various places
  where if you do any shader stuff at all you can probably guess.
* `ELIntersectionFunctions.cginc` - exact ray intersection functions.

Framework for writing raycast shaders without duplicating code:

* `ELRaycastBase.cginc` - **defines** vertex shader `ELRaycastBaseVertex`,
  and fragment shaders `ELFragmentRaycast` and `ELRaycastShadowCasterFragment`;
  **declares** functions `ELRaycast` and `ELDecodeMaterial` which the user
  implements to define how the ray hits the surface, and the properties of the
  material where it hit.
* `ELRaycastBaseInputOutput.cginc` - input and output structures for the
  raycaster.
* `ELRaycastBaseRays.cginc` - ray structure and common functions thereon.

Framework for writing raymarch shaders without duplicating code:

* `ELRaymarchCommon.cginc` - **declares** functions `ELMap` and `ELBoundingBox`
  which the user implements to define a raymarched object.
* `ELRaymarchBase.cginc` - **defines** function `ELRaycast` to perform a
  raymarch.

And this outlier:

* `ELGeometry.cginc` - not much at present, just a geometry shader for making a
  cube from two verts. (How to get an avatar down to zero polygons.)
