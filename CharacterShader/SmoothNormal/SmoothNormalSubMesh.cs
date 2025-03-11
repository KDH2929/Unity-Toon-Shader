using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public class SmoothNormalSubMesh : MonoBehaviour
{

    Mesh MeshNormalAverage(Mesh mesh, int subMeshIndex)
    {
        int[] triangles = mesh.GetTriangles(subMeshIndex);

        Dictionary<Vector3, List<int>> map = new Dictionary<Vector3, List<int>>();
        for (int i = 0; i < triangles.Length; ++i)
        {
            int v = triangles[i];
            if (!map.ContainsKey(mesh.vertices[v]))
            {
                map.Add(mesh.vertices[v], new List<int>());
            }
            map[mesh.vertices[v]].Add(v);
        }

        Vector3[] normals = mesh.normals;
        Vector3 normal;

        foreach (var p in map)
        {
            normal = Vector3.zero;
            foreach (var n in p.Value)
            {
                normal += mesh.normals[n];
            }
            normal /= p.Value.Count;
            foreach (var n in p.Value)
            {
                normals[n] = normal;
            }
        }

        mesh.normals = normals;
        return mesh;
    }

    void Awake()
    {
        if (GetComponent<MeshFilter>())
        {
            Mesh tempMesh = (Mesh)Instantiate(GetComponent<MeshFilter>().sharedMesh);

            for (int i = 0; i < tempMesh.subMeshCount; i++)
            {
                if (i == 0 || i == 2)
                {
                    tempMesh = MeshNormalAverage(tempMesh, i);
                }
            }

            gameObject.GetComponent<MeshFilter>().sharedMesh = tempMesh;
        }


        if (GetComponent<SkinnedMeshRenderer>())
        {
            Mesh tempMesh = (Mesh)Instantiate(GetComponent<SkinnedMeshRenderer>().sharedMesh);

            for (int i = 0; i < tempMesh.subMeshCount; i++)
            {
                if (i == 0 || i == 2)
                {
                    tempMesh = MeshNormalAverage(tempMesh, i);
                }
            }

            gameObject.GetComponent<SkinnedMeshRenderer>().sharedMesh = tempMesh;
        }
    }
}
