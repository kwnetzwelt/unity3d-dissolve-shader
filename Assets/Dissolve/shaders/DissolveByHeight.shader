// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

Shader "Custom/Dissolve/Height/Opaque" {
	Properties{
		_Color("Color", Color) = (1,1,1,1)
		_MainTex("Albedo (RGB)", 2D) = "white" {}
		_Glossiness("Smoothness", Range(0,1)) = 0.5

		[NoScaleOffset] _MetallicGlossMap("Metallic", 2D) = "white" {}
		[Gamma]  _Metallic ("Metallic", Range(0.000000,1.000000)) = 0.000000
		_Height("Dissolve Height", Float) = 1
		_Interpolation("Dissolve Interpolation", Range(0,5)) = 1
		_DissTexture("Dissolve Texture", 2D) = "black" {}
		[HDR]_DissolveColor("Dissolve Color", Color) = (0,1,0,1)
		[NoScaleOffset] _BumpMap ("Normal Map", 2D) = "bump" {}
		_BumpScale ("Normal Influence", Range(0,10)) = 0.5

		[HDR]_EmissionColor ("Color", Color) = (0.000000,0.000000,0.000000,1.000000)
		[NoScaleOffset]_EmissionMap ("Emission", 2D) = "white" { }
	}

	  CGINCLUDE
        //@TODO: should this be pulled into a shader_feature, to be able to turn it off?
        #define _GLOSSYENV 1
        #define UNITY_SETUP_BRDF_INPUT SpecularSetup
    ENDCG
 

		SubShader{
			Tags { "RenderType" = "Opaque" }
			LOD 200

			// Extracts information for lightmapping, GI (emission, albedo, ...)
			// This pass is not used during regular rendering.
			Pass
			{
				Name "META" 
				Tags { "LightMode"="Meta" }

				Cull Off

				CGPROGRAM
				#pragma vertex vert_meta
				#pragma fragment frag_meta

				#pragma shader_feature _EMISSION
				#pragma shader_feature _METALLICGLOSSMAP

				#include "UnityStandardMeta.cginc"
				ENDCG
			}

			CGPROGRAM

		#include "UnityPBSLighting.cginc"
		// Physically based Standard lighting model, and enable shadows on all light types
		#pragma surface surf Standard addshadow

		// Use shader model 3.0 target, to get nicer looking lighting
		#pragma target 3.0

		sampler2D _MainTex;

		struct Input {
			float2 uv_MainTex;
			float2 uv_BumpMap;
			float2 uv_DissTexture;
			float3 worldPos;
		};

		half _Metallic;
		half _Glossiness;
		sampler2D _MetallicGlossMap;

		sampler2D _EmissionMap;
		float4 _EmissionColor; 
		float4 _DissolveColor;

		sampler2D _BumpMap;

		fixed _Height;
		half _Interpolation;
		half _BumpScale;

		sampler2D _DissTexture;


		fixed4 _Color;

		void surf(Input IN, inout SurfaceOutputStandard o) {

			float l = _Height - IN.worldPos.y;
			clip( sign(IN.worldPos.y) * sign(IN.worldPos.y) * (l + (tex2D(_DissTexture, IN.uv_DissTexture) * _Interpolation)) );

			fixed4 c = tex2D(_MetallicGlossMap, IN.uv_MainTex);
			o.Metallic = c.rgb * _Metallic ;
			o.Smoothness = _Glossiness * c.a;


			c = tex2D(_MainTex, IN.uv_MainTex);
			o.Albedo = c.rgb * _Color;

			o.Normal = normalize(UnpackScaleNormal (tex2D (_BumpMap, IN.uv_BumpMap) , _BumpScale));
			
			o.Emission = tex2D(_EmissionMap, IN.uv_MainTex) * _EmissionColor + saturate(-l ) *_DissolveColor.rgb * tex2D(_DissTexture, IN.uv_DissTexture);
			o.Alpha = c.a;
		}
		ENDCG
		}
		Fallback "Diffuse"
}
	
