Shader "Custom/Dissolve/Distance/Transparent" {
	Properties{
		_Color("Color", Color) = (1,1,1,1)
		_MainTex("Albedo (RGB)", 2D) = "white" {}
	_Glossiness("Smoothness", Range(0,1)) = 0.5

		[NoScaleOffset] _MetallicGlossMap("Metallic", 2D) = "white" {}
	[Gamma]  _Metallic("Metallic", Range(0.000000,1.000000)) = 0.000000
		_Center("Dissolve Center", Vector) = (0,0,0,0)
		_Distance("Dissolve Distance", Float) = 1
		_Interpolation("Dissolve Interpolation", Range(0,5)) = 1
		_DissTexture("Dissolve Texture", 2D) = "white" {}
	[HDR]_DissolveColor("Dissolve Color", Color) = (0,1,0,1)

		[NoScaleOffset] _BumpMap("Normal Map", 2D) = "bump" {}
	_BumpScale("Normal Influence", Range(0,10)) = 0.5

		[HDR]_EmissionColor("Color", Color) = (0.000000,0.000000,0.000000,1.000000)
		[NoScaleOffset]_EmissionMap("Emission", 2D) = "white" { }
	}

		CGINCLUDE
#define _GLOSSYENV 1
#define UNITY_SETUP_BRDF_INPUT SpecularSetup
		ENDCG


		SubShader{
		Tags{ "RenderType" = "Transparent" "Queue" = "Transparent" }
		LOD 200

		// Shadow caster pass to allow for clipped shadows on a transparent shader
		Pass{
		Name "ShadowCaster"
		Tags{ "LightMode" = "ShadowCaster" }

		Fog{ Mode Off }
		ZWrite On ZTest Less Cull Off
		Offset 1, 1

		CGPROGRAM
#pragma vertex vert
#pragma fragment frag
#pragma fragmentoption ARB_precision_hint_fastest
#pragma multi_compile_shadowcaster

#include "UnityCG.cginc"

		float4 _Color;
	sampler2D _MainTex;

	float _Distance;
	float4 _Center;
	half _Interpolation;
	sampler2D _DissTexture;



	struct v2f {
		V2F_SHADOW_CASTER;
		float2 uv : TEXCOORD1;
		float3 worldPos : TEXCOORD2;
	};


	v2f vert(appdata_full v)
	{
		v2f o;
		UNITY_INITIALIZE_OUTPUT(v2f,o);
		o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
		TRANSFER_SHADOW_CASTER(o)

			return o;
	}

	float4 frag(v2f i) : COLOR
	{
		float l = length(_Center.xyz - i.worldPos.xyz);
		clip(saturate(_Distance - l + (tex2D(_DissTexture, i.uv) * _Interpolation * saturate(_Distance))) - 0.5);

	SHADOW_CASTER_FRAGMENT(i)
	}
		ENDCG
	}


		// Extracts information for lightmapping, GI (emission, albedo, ...)
		// This pass is not used during regular rendering.
		Pass
	{
		Name "META"
		Tags{ "LightMode" = "Meta" }

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
#pragma surface surf Standard alpha 

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

	half _Distance;
	half _Interpolation;
	half _BumpScale;

	sampler2D _DissTexture;
	float4 _Center;

	fixed4 _Color;

	void surf(Input IN, inout SurfaceOutputStandard o) {

		float l = length(_Center.xyz - IN.worldPos.xyz);

		clip(saturate(_Distance - l + (tex2D(_DissTexture, IN.uv_DissTexture) * _Interpolation * saturate(_Distance))) - 0.5);


		fixed4 c = tex2D(_MetallicGlossMap, IN.uv_MainTex);
		o.Metallic = c.rgb * _Metallic;
		o.Smoothness = _Glossiness * c.a;


		c = tex2D(_MainTex, IN.uv_MainTex);
		o.Albedo = c.rgb * _Color;

		o.Normal = normalize(UnpackScaleNormal (tex2D (_BumpMap, IN.uv_BumpMap) , _BumpScale));

		o.Emission = tex2D(_EmissionMap, IN.uv_MainTex) * _EmissionColor + saturate(1 - (_Distance - l + 0.5)) *_DissolveColor.rgb * tex2D(_DissTexture, IN.uv_DissTexture);

		o.Alpha = c.a * _Color.a;
	}
	ENDCG
	}
		Fallback "Diffuse"
}

