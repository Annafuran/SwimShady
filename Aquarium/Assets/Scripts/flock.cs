using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class flock : MonoBehaviour
{
    public float speed = 0.001f;
    float rotationSpeed = 4.0f;         // How fast the fish will turn when they need
    Vector3 averageHeading;             // Heading direction
    Vector3 averagePosition;            // Average position of the group
    float neighbourDistance = 3.0f;    // Distance to neighbour

    bool turning = false;       // make them turn when hitting tank wall

    // Start is called before the first frame update
    void Start()
    {
        //Make movement random velocity
        speed = Random.Range(0.2f, 1);
    }

    // Update is called once per frame
    void Update()
    {
        // if fish position according to the tanks zero-pos is greater than the tank size, turn
        if (Vector3.Distance(transform.position, Vector3.zero) >= globalFlock.tankSizeX || Vector3.Distance(transform.position, Vector3.zero) >= globalFlock.tankSizeY || Vector3.Distance(transform.position, Vector3.zero) >= globalFlock.tankSizeZ)
        {

            turning = true;
        }
        else { 
            turning = false; 
        }

        // Turn fish
        if (turning)
        {
            Vector3 direction = Vector3.zero - transform.position;
            transform.rotation = Quaternion.Slerp(transform.rotation, Quaternion.LookRotation(direction), rotationSpeed * Time.deltaTime);

            speed = Random.Range(0.5f, 1);
        }
        else { 
            //Rules the rules 1 in 5 times, to get random behaviour, (increase the 5 value if flocking to much)
            if (Random.Range(0, 5) < 1) {
                ApplyRules();
            }
        }
        // Move forward
        transform.Translate(0, 0, Time.deltaTime * speed);
    }

    // our flocking behaviour
    void ApplyRules() {

        GameObject[] gos;
        // For all fish to know all the other fishes position
        gos = globalFlock.allFish;

        // center of the group
        Vector3 vcentre = new Vector3(0.0f, 1.0f, 0.0f); // points to the centre of the group
        Vector3 vavoid = new Vector3(0.0f, 1.0f, 0.0f);  // to avoid hitting the other fishes
        float gSpeed = 0.0001f;            // Group speed

        Vector3 goalPos = globalFlock.goalPos;  // Goal position

        float dist;
        int groupSize = 0;

        foreach (GameObject go in gos) {

            if (go != this.gameObject) {

                dist = Vector3.Distance(go.transform.position, this.transform.position);
                // if the fish is in the distance, group up!
                if (dist <= neighbourDistance) {

                    vcentre += go.transform.position;
                    groupSize++;

                    // move away to not collide with other fish
                    if (dist < 1.0f) {
                        vavoid = vavoid + (this.transform.position - go.transform.position);
                    }

                    // find average speed
                    flock anotherFlock = go.GetComponent<flock>();
                    gSpeed = gSpeed + anotherFlock.speed;
                }
            }
        }

        // if the fish is in a group
        if (groupSize > 0) {
            // Calculate the center of the group
            vcentre = vcentre / groupSize + (goalPos - this.transform.position);
            // calculate the average speed of the group
            speed = gSpeed / groupSize;

            // Gives the direction 
            Vector3 direction = (vcentre + vavoid) - transform.position;
            if (direction != Vector3.zero) {
                // make fish rotate
                transform.rotation = Quaternion.Slerp(transform.rotation, Quaternion.LookRotation(direction), rotationSpeed * Time.deltaTime);
            }
                
        }
    }

}
