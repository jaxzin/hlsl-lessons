Shader "Custom/Emission"
{
    Properties
    {
        _EmitColor ("Emission Color", Color) = (0.75, 1.0, 0.0, 1.0) // yellow-green default
        _Intensity ("Emission Intensity", Range(0,10)) = 1.0
    }

    SubShader
    {
        Tags { "RenderType"="Opaque" "RenderPipeline"="UniversalPipeline" }
        LOD 100

        Pass
        {
            Name "Forward"
            Tags { "LightMode"="UniversalForward" }

            // Depth & culling defaults
            Cull Back
            ZWrite On
            ZTest LEqual

            HLSLPROGRAM
            #pragma fragment frag
            #pragma vertex vert

            // URP lighting variants (trim if your project complains)
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile_fragment _ _ADDITIONAL_LIGHTS
            #pragma multi_compile_fragment _ _SHADOWS_SOFT
            #pragma shader_feature_local_fragment _EMISSION

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float3 positionWS  : TEXCOORD0;
                float3 normalWS    : TEXCOORD1;
            };

            struct Attributes
            {
                float3 positionOS  : POSITION;
                float3 normalOS    : NORMAL;
            };

            float4 _EmitColor;
            float _Intensity;

            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                OUT.normalWS = TransformObjectToWorldNormal(IN.normalOS);
                OUT.positionWS = TransformObjectToWorld(IN.positionOS);
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS);
                return OUT;
            }

            half4 frag (Varyings IN) : SV_Target
            {
                return half4(_EmitColor.rgb * _Intensity, 1.0);
            }
            ENDHLSL
        }

        // ---- Meta (baked GI contribution) ----
        Pass
        {
            Name "Meta"
            Tags { "LightMode"="Meta" }
            Cull Off

            HLSLPROGRAM
            #pragma vertex MetaVertex
            #pragma fragment EmissionMetaFragment

            #pragma shader_feature_local_fragment _EMISSION

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/MetaInput.hlsl"

            float4 _EmitColor;
            float  _Intensity;

            struct Attributes
            {
                float4 positionOS   : POSITION;
                float2 uv           : TEXCOORD0;
                float2 uv2          : TEXCOORD1;
            };

            struct Varyings
            {
                float4 positionCS   : SV_POSITION;
                float2 uv           : TEXCOORD0;
            };

            Varyings MetaVertex(Attributes input)
            {
                Varyings output;
                output.positionCS = UnityMetaVertexPosition(input.positionOS.xyz, input.uv2, input.uv2);
                output.uv = input.uv;
                return output;
            }

            half4 EmissionMetaFragment(Varyings input) : SV_Target
            {
                UnityMetaInput metaInput = (UnityMetaInput)0;

                // Trivially "use" the input UVs to prevent an unused parameter warning.
                // This has no performance cost as it's optimized away.
                metaInput.Emission = _EmitColor.rgb * _Intensity + (input.uv.x * 0);
                return UnityMetaFragment(metaInput);
            }
            ENDHLSL
        }
        
        UsePass "Legacy Shaders/VertexLit/SHADOWCASTER"

    }
    FallBack "Diffuse"
    CustomEditor "EmissionGUI"
}