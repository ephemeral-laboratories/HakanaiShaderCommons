using System.IO;
using UnityEngine;
using UnityEditor;

namespace HakanaiShaderCommons
{
    public static class CreationMenu
    {
        [MenuItem("Assets/Create/Shader/EL Raycast Shader", false, 100)]
        public static void CreateRaycastShader()
        {
            ProjectWindowUtil.CreateScriptAssetFromTemplateFile(
                "Packages/garden.ephemeral.shader.commons/ShaderTemplates/RaycastShader.txt",
                "New Raycast Shader.shader");
        }

        [MenuItem("Assets/Create/Shader/EL Raymarch Shader", false, 101)]
        public static void CreateRaymarchShader()
        {
            ProjectWindowUtil.CreateScriptAssetFromTemplateFile(
                "Packages/garden.ephemeral.shader.commons/ShaderTemplates/RaymarchShader.txt",
                "New Raymarch Shader.shader");
        }

        private static string GetSelectedAssetFolder()
        {
            if (Selection.assetGUIDs.Length == 0)
            {
                return "Assets";
            }
            
            // May return the folder, may return the list of files selected in the folder
            var path = AssetDatabase.GUIDToAssetPath(Selection.assetGUIDs[0]);
            return Directory.Exists(path) ? path : Path.GetDirectoryName(path);
        }
    }
}
