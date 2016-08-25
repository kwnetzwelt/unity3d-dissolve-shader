// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

Shader "Custom/DissolveByDistance" {
	Properties{
		_Color("Color", Color) = (1,1,1,1)
		_MainTex("Albedo (RGB)", 2D) = "white" {}
		_Glossiness("Smoothness", Range(0,1)) = 0.5
		_Metallic("Metallic", Range(0,1)) = 0.0
		_Center("Dissolve Center", Vector) = (0,0,0,0)
		_Distance("Dissolve Distance", Float) = 1
		_Interpolation("Dissolve Interpolation", Range(0,5)) = 1
		_DissTexture("Dissolve Texture", 2D) = "white" {}
		
	}
		SubShader{
			Tags { "RenderType" = "Opaque" }
			LOD 200



			CGPROGRAM
		// Physically based Standard lighting model, and enable shadows on all light types
		#pragma surface surf Standard addshadow

		// Use shader model 3.0 target, to get nicer looking lighting
		#pragma target 3.0

		sampler2D _MainTex;

		struct Input {
			float2 uv_MainTex;
			float3 worldPos;
		};

		half _Glossiness;
		half _Metallic;

		half _Distance;
		half _Interpolation;

		sampler2D _DissTexture;
		float4 _Center;

		fixed4 _Color;

		void surf(Input IN, inout SurfaceOutputStandard o) {

			float l = length(_Center.xyz - IN.worldPos.xyz);
			clip(saturate(_Distance - l + (tex2D(_DissTexture, IN.uv_MainTex) * _Interpolation * saturate(_Distance))) - 0.5);

			fixed4 c = tex2D(_MainTex, IN.uv_MainTex) * _Color;
			o.Albedo = c.rgb;

			o.Metallic = _Metallic;
			o.Smoothness = _Glossiness;
			o.Alpha = c.a;
		}
		ENDCG
		}
		Fallback "Diffuse"
}
	
