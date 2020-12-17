using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class globalFlock : MonoBehaviour
{

    public GameObject fishPrefab;
    public static int tankSize = 1;
    public static float tankSizeX = 1.9f; // size = 4
    public static float tankSizeY = 1.0f; // size = 2
    public static float tankSizeY_max = 2.9f; // size = 2
    public static float tankSizeZ = 0.85f; // size = 2

    static int numFish = 10;
    public static GameObject[] allFish = new GameObject[numFish];

    public static Vector3 goalPos = Vector3.zero;



    // Start is called before the first frame update
    void Start()
    {
        
        for (int i = 0; i < numFish; i++) {

            Vector3 pos = new Vector3(Random.Range(-tankSizeX, tankSizeX), Random.Range(0.0f, tankSizeY), Random.Range(-tankSizeZ, tankSizeZ));
            allFish[i] = (GameObject)Instantiate(fishPrefab, pos, Quaternion.identity);
        }
    }

    // Update is called once per frame
    void Update()
    {
        // changes goalPos every 50 in 10k times it will reset the goalpos 
        if (Random.Range(0, 10000) < 50) {
            goalPos = new Vector3(Random.Range(-tankSizeX, tankSizeX), 
                                    Random.Range(-tankSizeY, tankSizeY_max),
                                    Random.Range(-tankSizeZ, tankSizeZ));
         
        }
    }
}
