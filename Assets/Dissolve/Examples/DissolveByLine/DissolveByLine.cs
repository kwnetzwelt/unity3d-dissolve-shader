using UnityEngine;

[ExecuteInEditMode]
public class DissolveByLine : MonoBehaviour
{
    [SerializeField] private Transform origin = null;
    [SerializeField] private Transform target = null;

    [SerializeField] private float distance = 1;
    [SerializeField] private bool reverse = false;
    [SerializeField] private bool fromLine = false;
    [SerializeField] private float interpolate = 1;

    [SerializeField] private Material[] materials = null;

    [SerializeField] private string originName = "_Origin";
    [SerializeField] private string targetName = "_Target";
    [SerializeField] private string distanceName = "_Distance";
    [SerializeField] private string reverseName = "_Reverse";
    [SerializeField] private string fromLineName = "_FromLine";
    [SerializeField] private string interpolateName = "_Interpolation";

    // Update is called once per frame
    void Update ()
    {
        if (origin == null || target == null) return;

        Vector3 lineOrigin = origin.position;
        Vector3 lineTarget = target.position;

        // Need to feed these to the shader
        foreach (Material m in materials)
        {
            m.SetVector(originName, lineOrigin);
            m.SetVector(targetName, lineTarget);
            m.SetFloat(distanceName, distance);
            m.SetFloat(reverseName, reverse ? 1 : 0);
            m.SetFloat(fromLineName, fromLine ? 1 : 0);
            m.SetFloat(interpolateName, interpolate);
        }
    }
}
