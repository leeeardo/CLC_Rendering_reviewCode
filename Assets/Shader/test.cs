using UnityEditor;
using UnityEngine;
using UnityEngine.Rendering;

public class SetMatGIFlags
{
    // jave.lin : 根据 Project 视图中 选中的 Material 来设置为 emissive
    [MenuItem("Tools/SetMatGIFlagsFromSelected")]
    public static void SetMatGIFlagsFromSelected()
    {
        var objs = Selection.objects;
        var len = objs.Length;
        for (int i = 0; i < len; i++)
        {
            var mat = objs[i] as Material;
            if (mat == null) continue;
            if (!HasMyEmissionTagPass(mat.shader)) continue;
            // 一个 AnyEmissive = MaterialGlobalIlluminationFlags.RealtimeEmissive| MaterialGlobalIlluminationFlags.BakedEmissive;
            mat.globalIlluminationFlags = MaterialGlobalIlluminationFlags.AnyEmissive;
            Debug.Log($"material : {mat.name}, set to bake the emission flag");
        }
    }

    // jave.lin : 根据 Scene 视图下的 Hierarchy 视图中的所有带有 Renderer 的 mateiral ，如果带有 我们自己定义的 MyEmissionTag 标记的，都标记为 emissive
    [MenuItem("Tools/SetMatGIFlagsFromSceneRenderers")]
    public static void SetMatGIFlagsFromSceneRenderers()
    {
        var renderers = GameObject.FindObjectsOfType<Renderer>();
        var len = renderers.Length;
        for (int i = 0; i < len; i++)
        {
            var renderer = renderers[i] as Renderer;
            if (renderer == null) continue;
            var matCount = renderer.sharedMaterials.Length;
            for (int j = 0; j < matCount; j++)
            {
                var mat = renderer.sharedMaterials[j];
                if (HasMyEmissionTagPass(mat.shader)) continue;
                mat.globalIlluminationFlags = MaterialGlobalIlluminationFlags.AnyEmissive;
                Debug.Log($"go.name : {renderer.gameObject.name}, material: {mat.name}, set to bake the emission flag");
            }
        }
    }
    // jave.lin : 根据 Project 视图资源下所有的材质，如果带有 我们自己定义的 MyEmissionTag 标记的，都标记为 emissive
    [MenuItem("Tools/SetAllMatAssetGIFlag")]
    public static void SetAllMatGIFlag()
    {
        var matGUIDs = AssetDatabase.FindAssets("t:Material");
        foreach (var guid in matGUIDs)
        {
            var mat = AssetDatabase.LoadAssetAtPath<Material>(AssetDatabase.GUIDToAssetPath(guid));
            if (mat == null) continue;
            if (!HasMyEmissionTagPass(mat.shader)) continue;
            mat.globalIlluminationFlags = MaterialGlobalIlluminationFlags.AnyEmissive;
            Debug.Log($"material : {mat.name}, set to bake the emission flag");
        }
    }

    // jave.lin : 判断是否带有我们比较的 MyEmissionTag 的 Pass
    private static bool HasMyEmissionTagPass(Shader shader)
    {
        var passCount = shader.passCount;
        for (int k = 0; k < passCount; k++)
        {
            var pass = shader.FindPassTagValue(k, new ShaderTagId("MyEmissionTag"));
            if (pass.Equals(ShaderTagId.none)) continue;
            else
            {
                return true;
            }
        }
        return false;
    }
}