Shader "Custom/FluorescentHDRP"
{
    Properties
    {
        _EmitColor ("Emission Color", Color) = (1.0, 0.0, 1.0, 1.0) // Fuschia default
        _Intensity ("Emission Intensity", Range(0,10)) = 1.0
    }

    SubShader
    {
        Tags { "RenderType"="Opaque" "RenderPipeline"="HDRenderPipeline" }
        LOD 100

        Pass
        {
            Name "ForwardOnly"
            Tags { "LightMode"="ForwardOnly" }

            Cull Back
            ZWrite On
            ZTest LEqual

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #pragma multi_compile _ PUNCTUAL_SHADOW_LOW PUNCTUAL_SHADOW_MEDIUM PUNCTUAL_SHADOW_HIGH
            #pragma multi_compile _ DIRECTIONAL_SHADOW_LOW DIRECTIONAL_SHADOW_MEDIUM DIRECTIONAL_SHADOW_HIGH
            #pragma shader_feature_local_fragment _EMISSION

            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/ShaderLibrary/ShaderVariables.hlsl"
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Lighting/LightDefinition.hlsl"

            struct Attributes
            {
                float3 positionOS : POSITION;
                float3 normalOS   : NORMAL;
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float3 positionWS  : TEXCOORD0;
                float3 normalWS    : TEXCOORD1;
            };

            float4 _EmitColor;
            float  _Intensity;

            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                OUT.positionWS  = TransformObjectToWorld(IN.positionOS);
                OUT.normalWS    = TransformObjectToWorldNormal(IN.normalOS);
                OUT.positionHCS = TransformWorldToHClip(OUT.positionWS);
                return OUT;
            }

            half4 frag(Varyings IN) : SV_Target
            {
                half3 n = normalize(IN.normalWS);

                // HDRP stores directional lights in a structured buffer.
                // We read the first directional light, equivalent to URP's GetMainLight().
                half3 lightDir   = half3(0, 1, 0);
                half  blueLight  = 0;

                if (_DirectionalLightCount > 0)
                {
                    DirectionalLightData light = _DirectionalLightDatas[0];
                    lightDir  = -light.forward;
                    blueLight = light.color.b;
                }

                half ndotl = saturate(dot(n, lightDir));
                return half4(_EmitColor.rgb * _Intensity * ndotl * blueLight, 1.0);
            }
            ENDHLSL
        }

        // ---- ShadowCaster (HDRP DepthOnly pass) ----
        Pass
        {
            Name "ShadowCaster"
            Tags { "LightMode"="ShadowCaster" }

            Cull Back
            ZWrite On
            ZTest LEqual
            ColorMask 0

            HLSLPROGRAM
            #pragma vertex vertDepth
            #pragma fragment fragDepth

            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/ShaderLibrary/ShaderVariables.hlsl"

            struct Attributes
            {
                float3 positionOS : POSITION;
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
            };

            Varyings vertDepth(Attributes IN)
            {
                Varyings OUT;
                float3 posWS = TransformObjectToWorld(IN.positionOS);
                OUT.positionHCS = TransformWorldToHClip(posWS);
                return OUT;
            }

            half4 fragDepth(Varyings IN) : SV_Target
            {
                return 0;
            }
            ENDHLSL
        }

        // ---- DepthOnly (used by HDRP depth pre-pass) ----
        Pass
        {
            Name "DepthOnly"
            Tags { "LightMode"="DepthOnly" }

            Cull Back
            ZWrite On
            ZTest LEqual
            ColorMask 0

            HLSLPROGRAM
            #pragma vertex vertDepth
            #pragma fragment fragDepth

            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/ShaderLibrary/ShaderVariables.hlsl"

            struct Attributes
            {
                float3 positionOS : POSITION;
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
            };

            Varyings vertDepth(Attributes IN)
            {
                Varyings OUT;
                float3 posWS = TransformObjectToWorld(IN.positionOS);
                OUT.positionHCS = TransformWorldToHClip(posWS);
                return OUT;
            }

            half4 fragDepth(Varyings IN) : SV_Target
            {
                return 0;
            }
            ENDHLSL
        }
    }
        // ---- Meta (Baked GI) ----
        // Unity calls this pass when baking lighting. It renders the mesh "unfolded"
        // into lightmap UV space so the lightmapper can sample albedo and emission
        // per lightmap texel. LightMode=Meta is the same tag in both URP and HDRP.
        Pass
        {
            Name "META"
            Tags { "LightMode"="Meta" }
            Cull Off

            HLSLPROGRAM
            #pragma vertex MetaVertex
            #pragma fragment MetaFragment
            #pragma shader_feature_local_fragment _EMISSION

            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/ShaderLibrary/ShaderVariables.hlsl"

            float4 _EmitColor;
            float  _Intensity;

            // Unity sets these to tell the Meta fragment what to output:
            //   .x == 1  →  output albedo
            //   .y == 1  →  output emission
            // (may already be declared in ShaderVariables.hlsl; remove this
            //  line if you get an "already defined" compile error)
            float4 unity_MetaFragmentControl;

            struct Attributes
            {
                float4 positionOS : POSITION;
                float2 uv0        : TEXCOORD0;
                float2 uv1        : TEXCOORD1; // lightmap UV channel
                float3 normalOS   : NORMAL;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float3 normalWS   : TEXCOORD0;
            };

            Varyings MetaVertex(Attributes input)
            {
                Varyings output;
                // Remap lightmap UVs to clip space so the lightmapper can
                // "see" each texel of the mesh. HDRP has no helper for this
                // (URP had UnityMetaVertexPosition); we do it manually.
                float2 uv = input.uv1 * unity_LightmapST.xy + unity_LightmapST.zw;
                output.positionCS = float4(uv * 2.0 - 1.0, 0, 1);
                #if UNITY_UV_STARTS_AT_TOP
                output.positionCS.y = -output.positionCS.y;
                #endif
                output.normalWS = TransformObjectToWorldNormal(input.normalOS);
                return output;
            }

            half4 MetaFragment(Varyings input) : SV_Target
            {
                // If the lightmapper isn't asking for emission, output nothing.
                if (!unity_MetaFragmentControl.y)
                    return 0;

                // We output full _EmitColor * _Intensity — the maximum this surface
                // could ever emit. At bake time the lightmapper doesn't simulate
                // dynamic light colors, so we can't evaluate the "is there any
                // blue light?" condition. This gives baked GI a conservative upper
                // bound; the runtime ForwardOnly pass modulates the result correctly.
                return half4(_EmitColor.rgb * _Intensity, 1.0);
            }
            ENDHLSL
        }

    }
    FallBack "Diffuse"
    CustomEditor "FluorescentHDRPGUI"
}
