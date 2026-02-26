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
| **Light direction** | `mainL.direction` (already points toward surface) | `-light.forward` (stored as the light's forward vector) |
| **Light color** | `mainL.color` | `light.color` |
| **Shadow casting** | `UsePass "Legacy Shaders/VertexLit/SHADOWCASTER"` | Dedicated `ShadowCaster` and `DepthOnly` passes |

### Key Code Changes

**1. Includes** — URP's `Core.hlsl` and `Lighting.hlsl` are replaced with HDRP equivalents:
```hlsl
// URP
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

// HDRP
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"
#include "Packages/com.unity.render-pipelines.high-definition/Runtime/ShaderLibrary/ShaderVariables.hlsl"
#include "Packages/com.unity.render-pipelines.high-definition/Runtime/Lighting/LightDefinition.hlsl"
```

**2. Reading the main directional light** — URP provides a convenience function; HDRP exposes a raw buffer:
```hlsl
// URP
Light mainL = GetMainLight();
half ndotl  = saturate(dot(n, mainL.direction));
half blueLight = mainL.color.b;

// HDRP
DirectionalLightData light = _DirectionalLightDatas[0];
half3 lightDir  = -light.forward;
half  blueLight = light.color.b;
half  ndotl     = saturate(dot(n, lightDir));
```

**3. Shadow passes** — HDRP requires explicit `ShadowCaster` and `DepthOnly` passes instead of borrowing from legacy shaders.

## File Descriptions

*   `FluorescentHDRP.shader`: The HDRP version of the fluorescent shader with `ForwardOnly`, `ShadowCaster`, and `DepthOnly` passes.
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
