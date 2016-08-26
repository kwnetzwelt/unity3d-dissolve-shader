using UnityEngine;
using System.Collections;

public class GizmoLine : MonoBehaviour {

	// Use this for initialization
	void Start () {
	
	}
	
	// Update is called once per frame
	void Update () {
	
	}

    void OnDrawGizmos()
    {
        Gizmos.color = Color.magenta;
        Gizmos.DrawLine(this.transform.position, this.transform.position + Vector3.right);
    }
}
