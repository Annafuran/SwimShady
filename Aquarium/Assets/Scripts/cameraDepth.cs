using System.Collections;
using System.Collections.Generic;
using UnityEngine;

//This will enable our depth texture mode on the main camera. 

[ExecuteInEditMode]
public class cameraDepth : MonoBehaviour
{
    private Camera cam;
    void Start()
    {
        cam = GetComponent<Camera>();
        cam.depthTextureMode = DepthTextureMode.Depth;

    }
}
