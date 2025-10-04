# Lesson 2: Shaded Emission

This lesson builds directly on the simple emission shader from Lesson 1. We'll modify our shader to make the emission sensitive to the main directional light in the scene, creating a "shaded" emissive effect.

## How It's Different from Lesson 1

In the previous lesson, our object glowed with a uniform color across its entire surface, regardless of the lighting. In this lesson, the emission intensity is multiplied by the amount of light hitting the surface.

*   **Surfaces facing the main light** will glow at the full intensity set in the material.
*   **Surfaces angled away from the light** will have a dimmer glow.
*   **Surfaces facing away from the light** (in shadow) will not glow at all.

This is a foundational step toward creating more complex and dynamic shaders that interact with their environment.

## The Code Change: Lambertian Shading

The key change is in the fragment shader (`frag` function) inside `EmissionShaded.shader`.

**Lesson 1 (Uniform Emission):**
```hlsl
half4 frag (Varyings IN) : SV_Target
{
    return half4(_EmitColor.rgb * _Intensity, 1.0);
}
```

**Lesson 2 (Shaded Emission):**
```hlsl
half4 frag (Varyings IN) : SV_Target
{
    // Get the normalized surface normal
    half3 n = normalize(IN.normalWS);
    // Get the main light data (direction, color, etc.)
    Light mainL = GetMainLight();
    // Calculate the dot product between normal and light direction
    half ndotl  = saturate(dot(n, mainL.direction));
    // Multiply emission by the result
    return half4(_EmitColor.rgb * _Intensity * ndotl, 1.0);
}
```
The `ndotl` variable holds the result of a **dot product**, a fundamental operation in shader math. It tells us how much the surface is facing the light. We use `saturate()` to clamp the result between 0 and 1. This technique is a simple form of **Lambertian shading**.

## File Descriptions

*   `EmissionShaded.shader`: The new shader file containing the light-sensitive emission logic.
*   `EmissionShadedGUI.cs`: The custom editor script, renamed to match the new shader. Its functionality is identical to the one in Lesson 1.

## Installation and Use

The process is very similar to Lesson 1, but since we don't provide a pre-made Material, you'll create it yourself.

1.  **Import Files**: Drag `EmissionShaded.shader` and `EmissionShadedGUI.cs` into your Unity project.
2.  **Create a Material**:
    *   In the Unity `Project` window, right-click in the folder where you put the shader.
    *   Go to **`Create > Material`**.
    *   Name the new material something like "EmissionShaded".
3.  **Assign the Shader**:
    *   Select your new "EmissionShaded" material.
    *   In the `Inspector` window at the top, click the **`Shader`** dropdown.
    *   Go to **`Custom > EmissionShaded`** to assign our new shader to the material.
4.  **Apply to an Object**: Drag the "EmissionShaded" material onto a Sphere or other 3D object in your scene.
5.  **Experiment**:
    *   Make sure you have a Directional Light in your scene.
    *   Rotate the object or the light to see how the glow changes based on the surface angle.
    *   Adjust the `Emission Color` and `Intensity` on your material in the Inspector.
