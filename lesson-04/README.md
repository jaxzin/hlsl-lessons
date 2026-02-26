# Lesson 4: Fluorescent Shader (HDRP)

This lesson converts the URP Fluorescent shader from Lesson 3 to the **High Definition Render Pipeline (HDRP)**. The fluorescence logic is identical — the material absorbs blue light and emits a chosen color — but the shader plumbing changes significantly to target HDRP instead of URP.

## URP vs HDRP: What Changes and Why

HDRP and URP are both built on Unity's Scriptable Render Pipeline, but they have very different internals:

| Aspect | URP (Lesson 3) | HDRP (Lesson 4) |
|---|---|---|
| **RenderPipeline tag** | `UniversalPipeline` | `HDRenderPipeline` |
| **Forward pass LightMode** | `UniversalForward` | `ForwardOnly` |
| **Package path** | `com.unity.render-pipelines.universal` | `com.unity.render-pipelines.high-definition` |
| **Main light access** | `GetMainLight()` returns a `Light` struct | Read `_DirectionalLightDatas[0]` from a structured buffer |
| **Light direction convention** | Points *toward* the surface | Points *away* from the surface (negate it) |
| **Light color** | `mainL.color` | `light.color` |
| **Shadow casting** | `UsePass "Legacy Shaders/VertexLit/SHADOWCASTER"` | Dedicated `ShadowCaster` and `DepthOnly` passes |
| **Baked GI (Meta pass)** | Provided via URP helpers | Requires a manual Meta pass |

## Key Code Changes

### 1. Includes

URP's `Core.hlsl` and `Lighting.hlsl` are replaced with HDRP equivalents:

```hlsl
// URP
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

// HDRP
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"
#include "Packages/com.unity.render-pipelines.high-definition/Runtime/ShaderLibrary/ShaderVariables.hlsl"
#include "Packages/com.unity.render-pipelines.high-definition/Runtime/Lighting/LightDefinition.hlsl"
```

### 2. Reading the main directional light

URP provides a convenience function; HDRP exposes raw GPU buffers:

```hlsl
// URP
Light mainL = GetMainLight();
half ndotl   = saturate(dot(n, mainL.direction));
half blueLight = mainL.color.b;

// HDRP
DirectionalLightData light = _DirectionalLightDatas[0];
half3 lightDir  = -light.forward;   // ← see below for why the negation
half  blueLight = light.color.b;
half  ndotl     = saturate(dot(n, lightDir));
```

#### Why do we negate `light.forward`?

This is an easy gotcha. In URP, `GetMainLight().direction` gives you the vector **pointing from the surface toward the light** — which is exactly what you need for the N·L dot product.

HDRP stores `DirectionalLightData.forward` as **the direction the light is pointing** (i.e., the direction light rays travel, *away* from the source and *toward* the surface). That's the opposite convention. Negating it converts it to a surface-to-light vector, which is what N·L expects.

If you forget the negation, `ndotl` will be negative for every lit surface, `saturate()` will clamp it to zero, and the shader will appear completely dark. Keep this in mind — you'll run into the same flip with any HDRP directional light.

### 3. Shadow passes

HDRP requires explicit `ShadowCaster` and `DepthOnly` passes instead of borrowing from legacy shaders. These are straightforward depth-only passes that write only to the depth buffer (`ColorMask 0`).

### 4. Meta pass (Baked GI)

When you bake lighting in Unity, the lightmapper calls a special `Meta` pass on every material to ask: *"what albedo and emission does this surface contribute to baked indirect light?"* Without it, your fluorescent surface won't light up surrounding objects in baked scenes.

Both URP and HDRP support the `Meta` pass using the same `LightMode=Meta` tag. The key difference is how the vertex shader repositions geometry — instead of rendering in 3D space, it projects the mesh into **lightmap UV space** so the lightmapper can sample every texel:

```hlsl
// Remap lightmap UVs to clip space (manual in HDRP; URP had UnityMetaVertexPosition)
float2 uv = input.uv1 * unity_LightmapST.xy + unity_LightmapST.zw;
output.positionCS = float4(uv * 2.0 - 1.0, 0, 1);
```

In the fragment shader we output emission unconditionally at full `_EmitColor * _Intensity`. This is intentional: the bake happens once at edit time and doesn't simulate dynamic light colors, so we can't evaluate "is there any blue light?" We give the lightmapper the maximum this surface can emit; the runtime ForwardOnly pass handles the real-time blue-light condition.

## File Descriptions

*   `FluorescentHDRP.shader`: The HDRP version of the fluorescent shader, with `ForwardOnly`, `ShadowCaster`, `DepthOnly`, and `Meta` passes.
*   `FluorescentHDRPGUI.cs`: The custom editor script for the material inspector. Functionally identical to the Lesson 3 version, renamed to match the new shader.

## Installation and Use

1.  **Requires HDRP**: Your Unity project must use the High Definition Render Pipeline. You can create an HDRP project from the Unity Hub or install the `com.unity.render-pipelines.high-definition` package.
2.  **Import Files**: Drag `FluorescentHDRP.shader` and `FluorescentHDRPGUI.cs` into your Unity project.
3.  **Create a Material**:
    *   In the Unity `Project` window, right-click on the `FluorescentHDRP.shader` file.
    *   Go to **`Create > Material`**.
    *   Unity will create a new material that uses this shader.
4.  **Apply to an Object**: Drag the material onto a Sphere or other 3D object in your scene.
5.  **Experiment**:
    *   Make sure you have a Directional Light in your scene.
    *   Change the color of your Directional Light to blue and see the object glow.
    *   Change the light color to red or green and see the glow disappear.

## Homework: Multiple Lights

The current shader only reads `_DirectionalLightDatas[0]` — the first directional light. In a real scene you might have multiple directional lights (sun + moon, for example), and point or spot lights (a UV blacklight shining directly at the object). Neither of these are handled yet.

### Part 1: Multiple Directional Lights

HDRP gives you the count for free:

```hlsl
// _DirectionalLightCount is provided by ShaderVariables.hlsl
// _DirectionalLightDatas[] is the full buffer
```

Your task: loop over all directional lights, accumulate N·L × blueChannel contributions, and sum them into the final emission. The math is the same as the single-light version — you just need to sum across all lights.

**Hint:** Think about what "sum" means physically. If two directional lights both have a blue component, the surface should glow brighter than if only one did. Accumulate into a single `half` before multiplying by `_EmitColor`.

### Part 2: Point and Spot Lights (Harder)

Point and spot lights in HDRP live in a different buffer: `_LightDatas[]`, with count `_PunctualLightCount` (both from `ShaderVariables.hlsl`). The struct is `LightData` (from `LightDefinition.hlsl`), not `DirectionalLightData`.

**What's different about punctual lights:**

1. **Position, not just direction.** A point light has a world-space position (`light.positionRWS`). You need to compute a per-fragment direction: `normalize(light.positionRWS - IN.positionWS)`.

2. **Attenuation.** A directional light has infinite range and constant intensity. A point light falls off with distance. HDRP provides `light.rangeAttenuationBias` and `light.rangeAttenuationScale`, but the simplest approximation is inverse-square: `1.0 / dot(toLight, toLight)`. You can clamp/scale to taste.

3. **Spot cone.** For spotlights, `light.lightType == GPULIGHTTYPE_SPOT`. You'd check whether the fragment falls within the cone using `light.angleOffset` and `light.angleScale` — but feel free to skip spotlights and only handle `GPULIGHTTYPE_POINT` first.

**Suggested approach:** Loop over `_PunctualLightCount`, skip any light that isn't a point light, compute direction + attenuation, evaluate `blueLight * ndotl * attenuation`, and accumulate into the same emission sum as Part 1.
