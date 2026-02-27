using UnityEngine;
using UnityEditor;
using UnityEditor.Rendering;
using System.Collections.Generic;

public static class ShaderValidator
{
    public static void ValidateShaders()
    {
        Debug.Log("=== Shader Validation Started ===");

        string[] guids = AssetDatabase.FindAssets("t:Shader", new[] { "Assets/Shaders" });

        if (guids.Length == 0)
        {
            Debug.LogError("No shaders found in Assets/Shaders/. Check that shader files are present.");
            EditorApplication.Exit(1);
            return;
        }

        Debug.Log($"Found {guids.Length} shader(s) to validate.\n");

        var failedShaders = new List<string>();
        int passCount = 0;

        foreach (string guid in guids)
        {
            string path = AssetDatabase.GUIDToAssetPath(guid);
            Shader shader = AssetDatabase.LoadAssetAtPath<Shader>(path);

            if (shader == null)
            {
                Debug.LogError($"FAIL: Could not load shader at {path}");
                failedShaders.Add(path);
                continue;
            }

            ShaderMessage[] messages = ShaderUtil.GetShaderMessages(shader);
            bool hasErrors = false;

            foreach (ShaderMessage msg in messages)
            {
                if (msg.severity == ShaderCompilerMessageSeverity.Error)
                {
                    Debug.LogError($"  ERROR in {path}: {msg.message} (platform: {msg.platform})");
                    hasErrors = true;
                }
                else
                {
                    // Treat warnings in lesson shaders as errors — keeps the lesson
                    // code clean and ensures Owen's shaders don't accumulate silent issues.
                    Debug.LogError($"  WARNING (treated as error) in {path}: {msg.message} (platform: {msg.platform})");
                    hasErrors = true;
                }
            }

            if (hasErrors)
            {
                Debug.LogError($"FAIL: {path}");
                failedShaders.Add(path);
            }
            else
            {
                Debug.Log($"PASS: {path}");
                passCount++;
            }
        }

        Debug.Log("\n=== Shader Validation Summary ===");
        Debug.Log($"  Passed: {passCount}");
        Debug.Log($"  Failed: {failedShaders.Count}");
        Debug.Log($"  Total:  {guids.Length}");

        if (failedShaders.Count > 0)
        {
            Debug.LogError("\nFailed shaders:");
            foreach (string s in failedShaders)
                Debug.LogError($"  - {s}");

            Debug.LogError("\n=== Shader Validation FAILED ===");
            EditorApplication.Exit(1);
        }
        else
        {
            Debug.Log("\n=== All Shaders Passed ===");
            EditorApplication.Exit(0);
        }
    }
}
