Shader "Unlit/FaceShader"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
        _SDFTex ("SDF Texture", 2D) = "white" {}
        _ShadowSmooth ("ShadowSmooth", Range(0.0, 0.1)) = 0.001
        _ShadowColor ("ShadowColor", Color) = (0,0,0,1)
        _RampTex ("Ramp Texture", 2D) = "black" {}
        _RimPower ("Rim Power", Range(0.0, 15.0)) = 5.0
        _RimIntensity ("Rim Intensity", Range(0.0, 1.0)) = 1.0
        _RimColor ("Rim Color", Color) = (1, 1, 1, 1)
        _OutlineColor ("Outline Color", Color) = (0,0,0,1)
        _OutlineWidth ("Outline Width", Range(0.0, 0.03)) = 0.005
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 200

        UsePass "Legacy Shaders/VertexLit/SHADOWCASTER"

        // 1st Pass (Outline)
        Pass
        {
            Cull Front

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float2 texcoord : TEXCOORD0;
                float4 color : COLOR;
            };

            struct v2f
            {
                float4 position : SV_POSITION;
                float2 uv : TEXCOORD0;
                float4 color : COLOR;
            };

            fixed4 _OutlineColor;
            float _OutlineWidth;

            v2f vert(appdata v)
            {
                v2f o;
                v.vertex.xyz += v.normal * _OutlineWidth;
                o.position = UnityObjectToClipPos(v.vertex);
                o.uv = v.texcoord;
                o.color = v.color;
                return o;
            }

            half4 frag(v2f i) : SV_Target
            {
                return _OutlineColor;
            }
            ENDCG
        }

        // 2nd Pass
        Pass
        {

            Cull Back

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float3 normal : TEXCOORD1;
                float3 worldPos : TEXCOORD2;
            };

            sampler2D _MainTex;
            sampler2D _SDFTex;
            sampler2D _RampTex;

            fixed4 _Color;
            float3 _ShadowColor;
            float _ShadowSmooth;
            float _RimPower;
            float _RimIntensity;
            fixed4 _RimColor;

            v2f vert(appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                o.normal = UnityObjectToWorldNormal(v.normal);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                fixed4 RenderTex = tex2D(_MainTex, i.uv) * _Color;
                float SDF = tex2D(_SDFTex, i.uv).r;

                float3 mainLightDir = normalize(_WorldSpaceLightPos0);

                float2 rightVec = normalize(float3(1.0, 0.0, 0.0).xz);
                float2 frontVec = normalize(float3(0.0, 0.0, 1.0).xz);
                float2 lightVec = normalize(mainLightDir.xz);

                float threshold = dot(frontVec, lightVec) * 0.5 + 0.5;
                float SDF_direction = dot(rightVec, lightVec) > 0.0 ? SDF : 1.0 - SDF;
                
                float4 rightVecWS = mul(unity_ObjectToWorld, float4(-1, 0, 0, 0));    // 원래는 (1, 0, 0)이 맞으나 Blender와 Unity와의 좌표계차이 때문으로 보임
                float4 frontVecWS = mul(unity_ObjectToWorld, float4(0, 0, -1, 0));    // 위와 동일한 이유

                // float threshold = dot(frontVecWS.xz, mainLightDir.xz) * 0.5 + 0.5;         // nDotL
                // float SDF_direction = dot(rightVecWS.xz, mainLightDir) > 0.0 ? SDF : 1.0 - SDF;

                float SDF_range = smoothstep(threshold - _ShadowSmooth, threshold + _ShadowSmooth, SDF_direction);

                float3 normal = normalize(i.normal);
                float3 lightDir = normalize(mainLightDir);
                float nDotL = dot(normal, lightDir);

                float rampUV = saturate(nDotL) * 0.5 + 0.5;
                float4 ramp = tex2D(_RampTex, float2(rampUV, 0.5));

                float3 toonColor = RenderTex.rgb * ramp.rgb;

                float3 finalSDF = lerp(toonColor, _ShadowColor * toonColor, SDF_range);

                float3 viewDir = normalize(_WorldSpaceCameraPos - i.worldPos);
                float nDotV = dot(normal, viewDir);
                float rim = pow(1.0 - nDotV, _RimPower) * _RimIntensity;
                float3 rimLight = _RimColor.rgb * rim;

                float3 finalColor = finalSDF + rimLight;

                return float4(finalColor, 1);
            }
            ENDCG
        }
    }
    FallBack "Unlit/Texture"
}
