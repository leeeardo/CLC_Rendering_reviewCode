Shader "Custom/MyShader"
{
    Properties
    {
        _Color("Color" , Color) = (1,1,1,1)
        _MainTex ("Albedo", 2D) = "white" {}

        _Cutoff ("Alpha Cutoff", Range(0, 1)) = 0.5

        [NoScaleOffset] _NormalMap ("Normals", 2D) = "bump" {}
        _BumpScale("BumpScale" , Float) = 1

        [NoScaleOffset] _ParallaxMap ("Parallax", 2D) = "black" {}
		_ParallaxStrength ("Parallax Strength", Range(0, 0.1)) = 0

        [Gamma]_Metallic("Metallic" , Range(0,1)) = 0.5
        [NoScaleOffset] _MetallicMap("Metallic" , 2D) = "white"{}

        _Smoothness("_Smoothness" , Range(0,1)) = 0.5

        [NoScaleOffset] _OcclusionMap ("Occlusion", 2D) = "white" {}
		_OcclusionStrength("Occlusion Strength", Range(0, 1)) = 1

        [NoScaleOffset] _EmissionMap ("Emission", 2D) = "black" {}
		_Emission ("Emission", Color) = (0, 0, 0)

        _DetailTex ("Detail Texture", 2D) = "gray" {}
		[NoScaleOffset] _DetailNormalMap ("Detail Normals", 2D) = "bump" {}
		_DetailBumpScale ("Detail Bump Scale", Float) = 1

        [NoScaleOffset] _DetailMask ("Detail Mask", 2D) = "white" {}

        [HideInInspector] _SrcBlend ("_SrcBlend", Float) = 1
		[HideInInspector] _DstBlend ("_DstBlend", Float) = 0
        [HideInInspector] _ZWrite ("_ZWrite", Float) = 1
    }
    SubShader
    {
        CGINCLUDE

	   // #define BINORMAL_PER_FRAGMENT
	   // #define FOG_DISTANCE
        
        #define PARALLAX_BIAS 0
        //#define PARALLAX_OFFSET_LIMITING
        //#define PARALLAX_RAYMARCHING_STEPS 100
        #define PARALLAX_RAYMARCHING_INTERPOLATE
        #define PARALLAX_RAYMARCHING_SEARCH_STEPS 3
        #define PARALLAX_FUNCTION ParallaxRaymarching
        #define PARALLAX_SUPPORT_SCALED_DYNAMIC_BATCHING
	    ENDCG

        Pass {
			Tags {
				"LightMode" = "ForwardBase"
			}
            Blend [_SrcBlend]  [_DstBlend] 
            ZWrite [_ZWrite]

			CGPROGRAM

			#pragma target 3.0
            #pragma multi_compile_instancing
            #pragma shader_feature _ _RENDERING_CUTOUT _RENDERING_FADE _RENDERING_TRANSPARENT

            #pragma multi_compile_fog
            #pragma multi_compile _ LOD_FADE_CROSSFADE
            #pragma instancing_options lodfade
            #pragma multi_compile_fwdbase
            #pragma shader_feature _METALLIC_MAP
            #pragma shader_feature _ _SMOOTHNESS_ALBEDO _SMOOTHNESS_METALLIC
            #pragma shader_feature _NORMAL_MAP
            #pragma shader_feature _OCCLUSION_MAP
            #pragma shader_feature _DETAIL_MASK
            #pragma shader_feature _EMISSION_MAP

            #pragma shader_feature _PARALLAX_MAP

            #pragma shader_feature _DETAIL_ALBEDO_MAP
			#pragma shader_feature _DETAIL_NORMAL_MAP

			#pragma vertex vert
			#pragma fragment frag

            #define FORWARD_BASE_PASS

			#include "MyLighting.cginc"

			ENDCG
		}

        Pass
        {
            Tags { "LightMode"="ForwardAdd" }
            Blend [_SrcBlend] One
            ZWrite Off
            CGPROGRAM

            #pragma target 3.0

            #pragma multi_compile_fwdadd_fullshadows
            #pragma multi_compile _ LOD_FADE_CROSSFADE
            #pragma instancing_options lodfade

            #pragma shader_feature _ _RENDERING_CUTOUT _RENDERING_FADE _RENDERING_TRANSPARENT

            #pragma shader_feature _METALLIC_MAP
			#pragma shader_feature _ _SMOOTHNESS_ALBEDO _SMOOTHNESS_METALLIC
			#pragma shader_feature _NORMAL_MAP
			#pragma shader_feature _DETAIL_MASK
			#pragma shader_feature _DETAIL_ALBEDO_MAP
			#pragma shader_feature _DETAIL_NORMAL_MAP
            #pragma shader_feature _PARALLAX_MAP

            #pragma vertex vert
            #pragma fragment frag


            #include "MyLighting.cginc"
            ENDCG
        }
        

        Pass {
			Tags {
				"LightMode" = "ShadowCaster"
			}

			CGPROGRAM

			#pragma target 3.0

            #pragma multi_compile_shadowcaster
            #pragma multi_compile_instancing
            #pragma instancing_options lodfade
            #pragma multi_compile _ LOD_FADE_CROSSFADE
            #pragma shader_feature _ _RENDERING_CUTOUT _RENDERING_FADE _RENDERING_TRANSPARENT
			#pragma shader_feature _SMOOTHNESS_ALBEDO
            #pragma shader_feature _SEMITRANSPARENT_SHADOWS
            #pragma shader_feature _PARALLAX_MAP
			#pragma vertex MyShadowVert
			#pragma fragment MyShadowFrag


			#include "MyShadow.cginc"

			ENDCG
		}
        Pass {
			Tags {
				"LightMode" = "Deferred"
			}

            CGPROGRAM
            #pragma target 3.0

            #pragma multi_compile_instancing
            #pragma instancing_options lodfade

            #pragma shader_feature _ _RENDERING_CUTOUT 
            #pragma multi_compile _ LOD_FADE_CROSSFADE
            //#pragma multi_compile _ UNITY_HDR_ON
            #pragma multi_compile_prepassfinal
			//#pragma multi_compile _ LIGHTMAP_ON VERTEXLIGHT_ON
            #pragma shader_feature _METALLIC_MAP
            #pragma shader_feature _ _SMOOTHNESS_ALBEDO _SMOOTHNESS_METALLIC
            #pragma shader_feature _NORMAL_MAP
            #pragma shader_feature _OCCLUSION_MAP
            #pragma shader_feature _DETAIL_MASK
            #pragma shader_feature _EMISSION_MAP
            //#pragma multi_compile _ SHADOWS_SCREEN
            #pragma shader_feature _DETAIL_ALBEDO_MAP
			#pragma shader_feature _DETAIL_NORMAL_MAP
            #pragma shader_feature _PARALLAX_MAP

			#pragma vertex vert
			#pragma fragment frag

            #define DEFERRED_PASS

			#include "MyLighting.cginc"

            ENDCG
		}

        Pass {
            Name "META"
			Tags {"LightMode" = "Meta"}

            Cull Off

			CGPROGRAM

			#pragma vertex vert_meta
			#pragma fragment frag_meta
            #pragma target 2.0
            #pragma shader_feature _METALLIC_MAP
			#pragma shader_feature _ _SMOOTHNESS_ALBEDO _SMOOTHNESS_METALLIC
			#pragma shader_feature _EMISSION_MAP 
			#pragma shader_feature _DETAIL_MASK
			#pragma shader_feature _DETAIL_ALBEDO_MAP
            #pragma shader_feature _EMISSION
            //#define _EMISSION

            //#include "UnityStandardMeta.cginc"
			#include "MyLightMapping.cginc"

			ENDCG
		}
    }
    CustomEditor "MyShaderGUI"
}
