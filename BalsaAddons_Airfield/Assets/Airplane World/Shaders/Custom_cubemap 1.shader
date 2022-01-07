// Made with Amplify Shader Editor
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "Custom/Custom_cubemap_airport"
{
	Properties
	{
		[HideInInspector] __dirty( "", Int ) = 1
		_Albedocolor("Albedo color", Color) = (1,1,1,0)
		_Albedo("Albedo", 2D) = "white" {}
		_MetalnessMask("MetalnessMask", 2D) = "white" {}
		_Cubemapcolor("Cubemap color", Color) = (0.6544118,0.9141988,1,0)
		_Cubemap("Cubemap", CUBE) = "white" {}
		_Fresnelcolor("Fresnel color", Color) = (0.6544118,0.9141988,1,0)
		_Fresnelintensity("Fresnel intensity", Range( 0 , 5)) = 0
		[HideInInspector] _texcoord( "", 2D ) = "white" {}
	}

	SubShader
	{
		Tags{ "RenderType" = "Opaque"  "Queue" = "Geometry-5" "IsEmissive" = "true"  }
		Cull Back
		CGINCLUDE
		#include "UnityPBSLighting.cginc"
		#include "Lighting.cginc"
		#pragma target 3.0
		#ifdef UNITY_PASS_SHADOWCASTER
			#undef INTERNAL_DATA
			#undef WorldReflectionVector
			#undef WorldNormalVector
			#define INTERNAL_DATA half3 internalSurfaceTtoW0; half3 internalSurfaceTtoW1; half3 internalSurfaceTtoW2;
			#define WorldReflectionVector(data,normal) reflect (data.worldRefl, half3(dot(data.internalSurfaceTtoW0,normal), dot(data.internalSurfaceTtoW1,normal), dot(data.internalSurfaceTtoW2,normal)))
			#define WorldNormalVector(data,normal) fixed3(dot(data.internalSurfaceTtoW0,normal), dot(data.internalSurfaceTtoW1,normal), dot(data.internalSurfaceTtoW2,normal))
		#endif
		struct Input
		{
			float2 uv_texcoord;
			float3 worldRefl;
			INTERNAL_DATA
			float3 worldPos;
			float3 worldNormal;
		};

		uniform float4 _Albedocolor;
		uniform sampler2D _Albedo;
		uniform float4 _Albedo_ST;
		uniform float4 _Cubemapcolor;
		uniform samplerCUBE _Cubemap;
		uniform float4 _Fresnelcolor;
		uniform float _Fresnelintensity;
		uniform sampler2D _MetalnessMask;
		uniform float4 _MetalnessMask_ST;

		void surf( Input i , inout SurfaceOutputStandard o )
		{
			o.Normal = float3(0,0,1);
			float2 uv_Albedo = i.uv_texcoord * _Albedo_ST.xy + _Albedo_ST.zw;
			float4 tex2DNode7 = tex2D( _Albedo,uv_Albedo);
			float4 temp_output_9_0 = ( _Albedocolor * tex2DNode7 );
			float3 worldrefVec15 = i.worldRefl;
			float3 worldViewDir = normalize( UnityWorldSpaceViewDir( i.worldPos ) );
			float3 worldNormal = WorldNormalVector( i, float3( 0, 0, 1 ) );
			float fresnelFinalVal17 = (0.0 + _Fresnelintensity*pow( 1.0 - dot( worldNormal, worldViewDir ) , 2.0));
			float4 temp_output_20_0 = ( _Fresnelcolor * fresnelFinalVal17 );
			float2 uv_MetalnessMask = i.uv_texcoord * _MetalnessMask_ST.xy + _MetalnessMask_ST.zw;
			float4 tex2DNode8 = tex2D( _MetalnessMask,uv_MetalnessMask);
			o.Albedo = lerp( temp_output_9_0 , ( saturate( ( ( ( _Cubemapcolor * texCUBE( _Cubemap,worldrefVec15) ) + temp_output_20_0 ) > 0.5 ? ( 1.0 - ( 1.0 - 2.0 * ( ( ( _Cubemapcolor * texCUBE( _Cubemap,worldrefVec15) ) + temp_output_20_0 ) - 0.5 ) ) * ( 1.0 - temp_output_9_0 ) ) : ( 2.0 * ( ( _Cubemapcolor * texCUBE( _Cubemap,worldrefVec15) ) + temp_output_20_0 ) * temp_output_9_0 ) ) )) , tex2DNode8.x ).rgb;
			o.Emission = ( ( _Fresnelcolor * fresnelFinalVal17 ) * tex2DNode8 ).xyz;
			o.Smoothness = 1.0;
			o.Alpha = 1;
		}

		ENDCG
		CGPROGRAM
		#pragma surface surf Standard keepalpha 

		ENDCG
		Pass
		{
			Name "ShadowCaster"
			Tags{ "LightMode" = "ShadowCaster" }
			ZWrite On
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma target 3.0
			#pragma multi_compile_shadowcaster
			#pragma multi_compile UNITY_PASS_SHADOWCASTER
			#pragma skip_variants FOG_LINEAR FOG_EXP FOG_EXP2
			# include "HLSLSupport.cginc"
			#if ( SHADER_API_D3D11 || SHADER_API_GLCORE || SHADER_API_GLES3 )
				#define CAN_SKIP_VPOS
			#endif
			#include "UnityCG.cginc"
			#include "Lighting.cginc"
			#include "UnityPBSLighting.cginc"
			sampler3D _DitherMaskLOD;
			struct v2f
			{
				V2F_SHADOW_CASTER;
				float3 worldPos : TEXCOORD6;
				float4 tSpace0 : TEXCOORD1;
				float4 tSpace1 : TEXCOORD2;
				float4 tSpace2 : TEXCOORD3;
				float4 texcoords01 : TEXCOORD4;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};
			v2f vert( appdata_full v )
			{
				v2f o;
				UNITY_SETUP_INSTANCE_ID( v );
				UNITY_INITIALIZE_OUTPUT( v2f, o );
				UNITY_TRANSFER_INSTANCE_ID( v, o );
				float3 worldPos = mul( unity_ObjectToWorld, v.vertex ).xyz;
				half3 worldNormal = UnityObjectToWorldNormal( v.normal );
				fixed3 worldTangent = UnityObjectToWorldDir( v.tangent.xyz );
				fixed tangentSign = v.tangent.w * unity_WorldTransformParams.w;
				fixed3 worldBinormal = cross( worldNormal, worldTangent ) * tangentSign;
				o.tSpace0 = float4( worldTangent.x, worldBinormal.x, worldNormal.x, worldPos.x );
				o.tSpace1 = float4( worldTangent.y, worldBinormal.y, worldNormal.y, worldPos.y );
				o.tSpace2 = float4( worldTangent.z, worldBinormal.z, worldNormal.z, worldPos.z );
				o.texcoords01 = float4( v.texcoord.xy, v.texcoord1.xy );
				o.worldPos = worldPos;
				TRANSFER_SHADOW_CASTER_NORMALOFFSET( o )
				return o;
			}
			fixed4 frag( v2f IN
			#if !defined( CAN_SKIP_VPOS )
			, UNITY_VPOS_TYPE vpos : VPOS
			#endif
			) : SV_Target
			{
				UNITY_SETUP_INSTANCE_ID( IN );
				Input surfIN;
				UNITY_INITIALIZE_OUTPUT( Input, surfIN );
				surfIN.uv_texcoord = IN.texcoords01.xy;
				float3 worldPos = float3( IN.tSpace0.w, IN.tSpace1.w, IN.tSpace2.w );
				fixed3 worldViewDir = normalize( UnityWorldSpaceViewDir( worldPos ) );
				surfIN.worldPos = worldPos;
				surfIN.worldNormal = float3( IN.tSpace0.z, IN.tSpace1.z, IN.tSpace2.z );
				surfIN.worldRefl = -worldViewDir;
				surfIN.internalSurfaceTtoW0 = IN.tSpace0.xyz;
				surfIN.internalSurfaceTtoW1 = IN.tSpace1.xyz;
				surfIN.internalSurfaceTtoW2 = IN.tSpace2.xyz;
				SurfaceOutputStandard o;
				UNITY_INITIALIZE_OUTPUT( SurfaceOutputStandard, o )
				surf( surfIN, o );
				#if defined( CAN_SKIP_VPOS )
				float2 vpos = IN.pos;
				#endif
				SHADOW_CASTER_FRAGMENT( IN )
			}
			ENDCG
		}
	}
	Fallback "Diffuse"
	CustomEditor "ASEMaterialInspector"
}
/*ASEBEGIN
Version=6001
2567;29;1666;974;921.4023;425.7007;1.1;True;True
Node;AmplifyShaderEditor.RangedFloatNode;19;-811.8004,452.999;Float;False;Property;_Fresnelintensity;Fresnel intensity;6;0;0;0;5;FLOAT
Node;AmplifyShaderEditor.WorldReflectionVector;15;-797.6003,44.19952;Float;False;0;FLOAT3;0,0,0;False;FLOAT3;FLOAT;FLOAT;FLOAT
Node;AmplifyShaderEditor.ColorNode;21;-571.4003,646.7488;Float;False;Property;_Fresnelcolor;Fresnel color;5;0;0.6544118,0.9141988,1,0;COLOR;FLOAT;FLOAT;FLOAT;FLOAT
Node;AmplifyShaderEditor.SamplerNode;6;-553.4009,5.599871;Float;True;Property;_Cubemap;Cubemap;4;0;None;True;0;False;white;Auto;False;Object;-1;Auto;Cube;0;SAMPLER2D;;False;1;FLOAT3;0,0,0;False;2;FLOAT;1.0;False;3;FLOAT3;0,0,0;False;4;FLOAT3;0,0,0;False;5;FLOAT;1.0;False;FLOAT4;FLOAT;FLOAT;FLOAT;FLOAT
Node;AmplifyShaderEditor.ColorNode;16;-479.0001,220.2997;Float;False;Property;_Cubemapcolor;Cubemap color;3;0;0.6544118,0.9141988,1,0;COLOR;FLOAT;FLOAT;FLOAT;FLOAT
Node;AmplifyShaderEditor.FresnelNode;17;-486.8007,436.0994;Float;False;0;FLOAT3;0,0,0;False;1;FLOAT;0.0;False;2;FLOAT;1.0;False;3;FLOAT;2.0;False;FLOAT
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;20;-212.4014,438.6494;Float;False;0;COLOR;0,0,0,0;False;1;FLOAT;0,0,0,0;False;COLOR
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;13;-226.701,38.59992;Float;False;0;COLOR;0,0,0,0;False;1;FLOAT4;0,0,0,0;False;FLOAT4
Node;AmplifyShaderEditor.SamplerNode;7;-456.6005,-211.1001;Float;True;Property;_Albedo;Albedo;1;0;Assets/ControlTower_albedo.tga;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;1.0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1.0;False;FLOAT4;FLOAT;FLOAT;FLOAT;FLOAT
Node;AmplifyShaderEditor.ColorNode;10;-381.8004,-391.5005;Float;False;Property;_Albedocolor;Albedo color;0;0;1,1,1,0;COLOR;FLOAT;FLOAT;FLOAT;FLOAT
Node;AmplifyShaderEditor.SimpleAddOpNode;18;-70.8009,54.39942;Float;False;0;FLOAT4;0.0;False;1;COLOR;0.0,0,0,0;False;COLOR
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;9;-128.8002,-249.6001;Float;False;0;COLOR;0.0;False;1;FLOAT4;0,0,0,0;False;FLOAT4
Node;AmplifyShaderEditor.SamplerNode;8;-386.3004,694.2991;Float;True;Property;_MetalnessMask;MetalnessMask;2;0;Assets/ControlTower_metalnessMask.tga;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;1.0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1.0;False;FLOAT4;FLOAT;FLOAT;FLOAT;FLOAT
Node;AmplifyShaderEditor.BlendOpsNode;24;49.89777,10.99927;Float;False;Overlay;True;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;COLOR
Node;AmplifyShaderEditor.LerpOp;12;220.3994,-40.60015;Float;False;0;FLOAT4;0,0,0,0;False;1;COLOR;0.0,0,0,0;False;2;FLOAT4;0.0;False;COLOR
Node;AmplifyShaderEditor.RangedFloatNode;23;54.798,235.7995;Float;False;Constant;_Float0;Float 0;7;0;1;0;0;FLOAT
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;22;-1.80144,524.4991;Float;False;0;COLOR;0.0;False;1;FLOAT4;0,0,0,0;False;FLOAT4
Node;AmplifyShaderEditor.StandardSurfaceOutputNode;0;537.3,-25.89999;Float;False;True;2;Float;ASEMaterialInspector;Standard;Custom/Custom_cubemap_airport;False;False;False;False;False;False;False;False;False;False;False;False;Back;0;0;False;0;0;Opaque;0.5;True;True;-5;False;Opaque;Geometry;All;True;True;True;True;True;True;True;True;True;True;True;True;True;True;True;True;True;False;0;255;255;0;0;0;0;False;0;4;10;25;False;0.5;True;0;Zero;Zero;0;Zero;Zero;Add;Add;0;False;0;0,0,0,0;VertexOffset;False;Cylindrical;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT3;0,0,0;False;3;FLOAT;0.0;False;4;FLOAT;0.0;False;5;FLOAT;0.0;False;6;FLOAT3;0,0,0;False;7;FLOAT3;0,0,0;False;8;FLOAT;0.0;False;9;FLOAT;0.0;False;10;OBJECT;0.0;False;11;FLOAT3;0,0,0;False;12;FLOAT3;0,0,0;False;13;OBJECT;0.0;False;14;FLOAT4;0,0,0,0;False;15;FLOAT3;0,0,0;False
WireConnection;6;1;15;0
WireConnection;17;2;19;0
WireConnection;20;0;21;0
WireConnection;20;1;17;0
WireConnection;13;0;16;0
WireConnection;13;1;6;0
WireConnection;18;0;13;0
WireConnection;18;1;20;0
WireConnection;9;0;10;0
WireConnection;9;1;7;0
WireConnection;24;0;9;0
WireConnection;24;1;18;0
WireConnection;12;0;9;0
WireConnection;12;1;24;0
WireConnection;12;2;8;0
WireConnection;22;0;20;0
WireConnection;22;1;8;0
WireConnection;0;0;12;0
WireConnection;0;2;22;0
WireConnection;0;4;23;0
ASEEND*/
//CHKSM=F8C472C6FCA35D73C640159B2042E05E108D5E54