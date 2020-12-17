using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class AquariumPlant : MonoBehaviour
{
    public Transform[] bones;
    public float swayAngle = 15;
    public float swaySpeed = 1;

    Quaternion[] initial;
    float[] rand;

    void Start ()
    {
        initial = new Quaternion[bones.Length];
        rand = new float[bones.Length];
        for (int i = 0; i < bones.Length; i++)
        {
            initial[i] = bones[i].localRotation;
            rand[i] = Random.value;
        }
    }

    void Update ()
    {
        float offset = 0;
        for (int i = 0; i < bones.Length; i++)
        {
            float freq = swaySpeed;
            float amp = swayAngle * Mathf.Pow((float)(i+1) / bones.Length, 0.5f);
            bones[i].localRotation = initial[i] * Quaternion.AngleAxis(Mathf.Sin(Time.time * freq + offset) * amp, Vector3.forward);
            offset += rand[i] * 2 * Mathf.PI;
        }
    }
}
