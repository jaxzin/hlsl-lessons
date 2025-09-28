# Lesson 1: Simple Emission Shader

This example contains a basic set of files to create a simple emissive material in Unity. An emissive material is one that appears to glow or give off its own light.

## File Descriptions

*   `Emission.shader`: This is the heart of the effect. It's a ShaderLab/HLSL file that tells the GPU how to draw an object to make it look like it's glowing. It defines the properties that can be customized, like the emission color and intensity.
*   `Emission.mat`: This is a Unity Material. It uses the `Emission.shader` and lets you save specific settings for it. For example, you could have one material for a red glow and another for a blue glow, both using the same shader file. You apply *this* file to your objects in the scene.
*   `EmissionGUI.cs`: This is a C# script that creates a custom user interface (UI) for our shader in Unity's Inspector window. It makes it easier and more intuitive to change the material's properties (like the color and intensity). This script is also essential for enabling realtime Global Illumination (GI) for the material, as this cannot be accomplished in pure ShaderLab/HLSL.

## Installation in Unity

1.  Open your Unity project.
2.  In the `Project` window, navigate to the `Assets` folder.
3.  Create a new folder to keep things organized (e.g., `HLSL Lessons/Lesson-01`).
4.  Drag and drop the `Emission.shader`, `Emission.mat`, and `EmissionGUI.cs` files from your computer directly into this new folder in Unity.
5.  Unity will automatically import the assets and compile the shader.

## How to Use

1.  Create a new 3D object in your scene (e.g., go to `GameObject > 3D Object > Sphere`).
2.  In the `Project` window, find the `Emission` material (it has a sphere icon).
3.  Drag the `Emission` material from the `Project` window and drop it onto your 3D object in the `Scene` view or in the `Hierarchy` window.
4.  Your object will now use the emissive material.
5.  To change the glow color or intensity, click on the `Emission.mat` file in the `Project` window and look at the `Inspector` window. You will see the custom controls created by the `EmissionGUI.cs` script.

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
