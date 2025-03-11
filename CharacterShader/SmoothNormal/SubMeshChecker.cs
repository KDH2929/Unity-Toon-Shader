using UnityEngine;

public class SubMeshChecker : MonoBehaviour
{
    void Start()
    {
        SkinnedMeshRenderer skinnedMeshRenderer = GetComponent<SkinnedMeshRenderer>();
        Mesh mesh = Instantiate(skinnedMeshRenderer.sharedMesh);

        Debug.Log("Total SubMeshes: " + mesh.subMeshCount);

        for (int i = 0; i < mesh.subMeshCount; i++)
        {
            Debug.Log("SubMesh " + i + " Triangles: " + mesh.GetTriangles(i).Length);
        }
    }
}
