using UnityEditor;
using UnityEngine;

public class FluorescentHDRPGUI : ShaderGUI
{
    enum GIMode { Baked, Realtime, Both }

    public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] props)
    {
        // Draw everything you declared in Properties{}:
        base.OnGUI(materialEditor, props);

        // Target material (works with multi-select too)
        var mats = System.Array.ConvertAll(materialEditor.targets, t => (Material)t);

        // --- GI dropdown like HDRP/Lit ---
        EditorGUILayout.Space();
        EditorGUILayout.LabelField("Global Illumination", EditorStyles.boldLabel);

        // Read current mode from first material
        var flags = mats[0].globalIlluminationFlags;
        var mode = (flags & MaterialGlobalIlluminationFlags.RealtimeEmissive) != 0
            ? ((flags & MaterialGlobalIlluminationFlags.BakedEmissive) != 0 ? GIMode.Both : GIMode.Realtime)
            : GIMode.Baked;

        EditorGUI.BeginChangeCheck();
        mode = (GIMode)EditorGUILayout.EnumPopup("Mode", mode);
        if (EditorGUI.EndChangeCheck())
        {
            foreach (var m in mats)
            {
                var newFlags = MaterialGlobalIlluminationFlags.None;
                if (mode == GIMode.Baked || mode == GIMode.Both)
                    newFlags |= MaterialGlobalIlluminationFlags.BakedEmissive;
                if (mode == GIMode.Realtime || mode == GIMode.Both)
                    newFlags |= MaterialGlobalIlluminationFlags.RealtimeEmissive;

                // If emission is effectively black, Unity skips GI unless Realtime updates it later
                var hasColor = m.HasProperty("_EmitColor") && m.GetColor("_EmitColor").maxColorComponent > 0f;
                var hasIntensity = m.HasProperty("_Intensity") && m.GetFloat("_Intensity") > 0f;
                if (!hasColor && !hasIntensity) newFlags |= MaterialGlobalIlluminationFlags.EmissiveIsBlack;

                m.globalIlluminationFlags = newFlags;

                // Keep the common _EMISSION keyword roughly in sync (optional)
                if (hasColor || hasIntensity) m.EnableKeyword("_EMISSION");
                else                           m.DisableKeyword("_EMISSION");

                EditorUtility.SetDirty(m);
            }
        }
    }
}
