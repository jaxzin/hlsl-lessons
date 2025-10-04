# Lesson 1: Simple Emission Shader

This example contains a basic set of files to create a simple emissive material in Unity. An emissive material is one that appears to glow or give off its own light.

## File Descriptions

*   `Emission.shader`: This is the heart of the effect. It's a ShaderLab/HLSL file that tells the GPU how to draw an object to make it look like it's glowing. It defines the properties that can be customized, like the emission color and intensity.
*   `EmissionGUI.cs`: This is a C# script that creates a custom user interface (UI) for our shader in Unity's Inspector window. It makes it easier and more intuitive to change the material's properties (like the color and intensity). This script is also essential for enabling realtime Global Illumination (GI) for the material, as this cannot be accomplished in pure ShaderLab/HLSL.

## Installation and Use

1.  **Import Files**: Drag `Emission.shader` and `EmissionGUI.cs` into your Unity project.
2.  **Create a Material**:
    *   In the Unity `Project` window, right-click on the `Emission.shader` file.
    *   Go to **`Create > Material`**.
    *   Unity will create a new material named "Emission" (or similar) that already uses this shader.
3.  **Apply to an Object**: Create a new 3D object in your scene (e.g., `GameObject > 3D Object > Sphere`) and drag the newly created "Emission" material onto it.
4.  **Adjust Settings**: Select the "Emission" material in the `Project` window. You can now change the `Emission Color` and `Intensity` in the `Inspector` window.

## Stretch Goal: Realtime Global Illumination

This emissive material can actually cast its own light onto other objects in the scene! To enable this, you need to turn on Realtime Global Illumination (GI). The setup is slightly different for objects that move (dynamic) versus objects that stay still (static).

1.  **Enable Realtime GI**:
    *   Go to `Window > Rendering > Lighting` to open the Lighting window.
    *   In the `Scene` tab, under `Realtime Lighting`, make sure the `Realtime Global Illumination` checkbox is ticked.

2.  **Configure GameObjects**:
    *   **To Cast Light (Your Emissive Object):** For an object to *cast* light into the scene, it **must** be marked as static. Select your emissive object, go to the `Inspector`, and check the `Static` box in the top right. In the dropdown that appears, ensure `Contribute GI` is selected.
    *   **To Receive Light (Other Objects):**
        *   **Static Scenery (floors, walls):** If the object receiving light is also static, mark it as `Static` just like the emissive object. The bounced light will be calculated for it directly.
        *   **Dynamic Objects (players, moving items):** If the object receiving light is dynamic, do **NOT** mark it as static. Instead, you must use `Light Probes`. Go to `GameObject > Light > Light Probe Group` to create them. Arrange the probes around the area where the dynamic object will be. The dynamic object will sample the lighting from these probes to look correct.

3.  **Generate Lighting**:
    *   At the bottom of the Lighting window, click the `Generate Lighting` button..

4.  **Observe the Effect**:
    *   Place another object (a static cube or a dynamic sphere moving through a light probe group) near your emissive object. You should see the light from your glowing object "bouncing" off and illuminating the nearby surface.
    *   Try increasing the `Intensity` on the `Emission` material to make the effect more obvious.

---

**Important Note: Regenerating Lighting**

After you move a `Static` object in the editor, Unity will not update its contribution to the Global Illumination automatically. The lighting data will be "stale" and originate from the object's old position.

To fix this, you must manually rebake the lighting:
1.  Go to `Window > Rendering > Lighting`.
2.  At the bottom of the window, click **`Generate Lighting`**.
