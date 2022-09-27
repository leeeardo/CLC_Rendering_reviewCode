Shader "Custom/DeferredFog"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        // No culling or depth
        Cull Off ZWrite Off ZTest Always

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #pragma multi_compile_fog

            #define FOG_DISTANCE

            #include "UnityCG.cginc"

            float3 _FrustumCorners[4];

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                #if defined(FOG_DISTANCE)
					float3 ray : TEXCOORD1;
				#endif
            };

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                #if defined(FOG_DISTANCE)
					o.ray = _FrustumCorners[v.uv.x + 2 * v.uv.y];
				#endif
                return o;
            }

            sampler2D _MainTex ,_CameraDepthTexture;

            

            float4 frag (v2f i) : SV_Target
            {
                float depth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture,i.uv);
                depth = Linear01Depth(depth);
                float viewDistance = depth * _ProjectionParams.z;
                #if defined(FOG_DISTANCE)
					viewDistance = length(i.ray * depth);
				#endif

                UNITY_CALC_FOG_FACTOR_RAW(viewDistance);
				unityFogFactor = saturate(unityFogFactor);
                if (depth > 0.9999) {
					unityFogFactor = 1;
				}
                #if !defined(FOG_LINEAR) && !defined(FOG_EXP) && !defined(FOG_EXP2)
					unityFogFactor = 1;
				#endif
                float3 sourceColor = tex2D(_MainTex, i.uv).rgb;
                float3 foggedColor =
					lerp(unity_FogColor.rgb, sourceColor, unityFogFactor);
				return float4(foggedColor,1);
            }
            ENDCG
        }
    }
}
