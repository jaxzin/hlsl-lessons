# Lesson 3: Fluorescent Shader

This lesson builds on the shaded emission shader from Lesson 2. We'll modify the shader to simulate fluorescence, where the material absorbs light of one color and emits light of another. In our case, the material will absorb blue light and emit a color we choose.

## How It's Different from Lesson 2

In the previous lesson, our emission was scaled by the total amount of light hitting the surface. In this lesson, we will only consider the blue component of the light. This means the material will only glow when it is illuminated by a light that has a blue component.

*   **Surfaces lit by blue light** will glow.
*   **Surfaces lit by light with no blue component** will not glow.

This is a simple but powerful technique for creating interesting visual effects.

## The Code Change: Isolating the Blue Channel

The key change is in the fragment shader (`frag` function) inside `Fluorescent.shader`.

**Lesson 2 (Shaded Emission):**
```hlsl
half4 frag (Varyings IN) : SV_Target
{
    half3 n = normalize(IN.normalWS);
    Light mainL = GetMainLight();
    half ndotl  = saturate(dot(n, mainL.direction));
    return half4(_EmitColor.rgb * _Intensity * ndotl, 1.0);
}
```

**Lesson 3 (Fluorescent Emission):**
```hlsl
half4 frag (Varyings IN) : SV_Target
{
    half3 n = normalize(IN.normalWS);
    Light mainL = GetMainLight();
    half ndotl  = saturate(dot(n, mainL.direction));
    half blueLight = mainL.color.b;
    return half4(_EmitColor.rgb * _Intensity * ndotl * blueLight, 1.0);
}
```
We are extracting the blue component of the main light's color and using it to scale the emission.

## File Descriptions

*   `Fluorescent.shader`: The new shader file containing the fluorescent logic.
*   `FluorescentGUI.cs`: The custom editor script, renamed to match the new shader. Its functionality is identical to the one in Lesson 2.

## Installation and Use

1.  **Import Files**: Drag `Fluorescent.shader` and `FluorescentGUI.cs` into your Unity project.
2.  **Create a Material**:
    *   In the Unity `Project` window, right-click on the `Fluorescent.shader` file.
    *   Go to **`Create > Material`**.
    *   Unity will create a new material named "Fluorescent" (or similar) that already uses this shader.
3.  **Apply to an Object**: Drag the "Fluorescent" material onto a Sphere or other 3D object in your scene.
4.  **Experiment**:
    *   Make sure you have a Directional Light in your scene.
    *   Change the color of your Directional Light to blue and see the object glow.
    *   Change the light color to red or green and see the glow disappear.