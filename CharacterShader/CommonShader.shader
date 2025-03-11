Shader "Unlit/CommonShader"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
        _ShadowSmooth ("ShadowSmooth", Range(0.0, 0.1)) = 0.001
        _ShadowColor ("ShadowColor", Color) = (0,0,0,1)
        _ShadowRange ("Shadow Range", Range(0.0, 1.0)) = 0.5
        _RampTex ("Ramp Texture", 2D) = "white" {}
        _RimPower ("Rim Power", Range(1.0, 15.0)) = 5.0
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
          
            Tags { "RenderType"="Transparent"}

            // 알파 블렌딩 설정
            // Blend SrcAlpha OneMinusSrcAlpha

            //ZWrite Off
            //ZTest LEqual


            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 texcoord : TEXCOORD0;
                float3 normal : NORMAL;
                float3 worldPos : TEXCOORD2;
            };

            struct v2f
            {
                float4 position : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : TEXCOORD1;
                float3 worldPos : TEXCOORD2;
            };

            fixed4 _OutlineColor;
            float _OutlineWidth;
            fixed4 _Color;
            float4 _SmoothedNormals[256];

            v2f vert(appdata v)
            {
                v2f o;
                v.vertex.xyz += v.normal * _OutlineWidth;
                o.position = UnityObjectToClipPos(v.vertex);
                o.uv = v.texcoord;
                o.normal = UnityObjectToWorldNormal(v.normal);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                return o;
            }

            half4 frag(v2f i) : SV_Target
            {
                /*
                float3 normal = normalize(i.normal);
                float3 viewDir = normalize(_WorldSpaceCameraPos - i.worldPos);
                float nDotV = dot(normal, viewDir);

                if(finalOutline.a < 1)
                {
                    discard;                        // discard를 쓰면 렌더링을 아예 하지 않도록 함
                }
                */

                return _OutlineColor;
            }
            ENDCG
        }

        // 2nd Pass (Character)
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
            sampler2D _RampTex;

            fixed4 _Color;
            float3 _ShadowColor;
            float _ShadowSmooth;
            float _RimPower;
            float _RimIntensity;
            fixed4 _RimColor;
            float _ShadowRange;

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

                float3 normal = normalize(i.normal);
                float3 lightDir = normalize(_WorldSpaceLightPos0);
                float nDotL = dot(normal, lightDir);

                float halfLambert = saturate(nDotL * 0.5 + 0.5);
                float shadow = smoothstep(_ShadowRange - _ShadowSmooth, _ShadowRange + _ShadowSmooth, 1 - halfLambert);

                float rampUV = saturate(nDotL) * 0.5 + 0.5;
                float4 ramp = tex2D(_RampTex, float2(rampUV, 0.5));

                float3 toonColor = RenderTex.rgb * ramp.rgb;

                float3 viewDir = normalize(_WorldSpaceCameraPos - i.worldPos);
                float nDotV = dot(normal, viewDir);
                float rim = pow(1.0 - saturate(nDotV), _RimPower) * _RimIntensity;
                float3 rimLight = _RimColor.rgb * rim;


                float3 finalColor = lerp(toonColor, _ShadowColor * toonColor, shadow) + rimLight;

                return float4(finalColor, 1);
            }
            ENDCG
        }
    }
    FallBack "Unlit/Texture"
}
