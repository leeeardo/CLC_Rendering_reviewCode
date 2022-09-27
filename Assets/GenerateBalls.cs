using System.Collections;
using System.Collections.Generic;
using UnityEngine;


public class GenerateBalls : MonoBehaviour
{
    public Transform prefabBall;
    public int instances = 5000;
    public float radius = 50f;
    // Start is called before the first frame update
    void Start()
    {
        MaterialPropertyBlock properties = new MaterialPropertyBlock();
        for (int i = 0; i < instances; i++)
        {
            Transform t = Instantiate(prefabBall);
            t.localPosition = Random.insideUnitSphere * radius;
            t.SetParent(transform);

            //t.GetComponent<MeshRenderer>().material.color = new Color(Random.value, Random.value, Random.value);      
            properties.SetColor("_Color", new Color(Random.value, Random.value, Random.value));
            //t.GetComponent<MeshRenderer>().SetPropertyBlock(properties);

            MeshRenderer r = t.GetComponent<MeshRenderer>();
            if (r)
            {
                r.SetPropertyBlock(properties);
            }
            else
            {
                for (int ci = 0; ci < t.childCount; ci++)
                {
                    r = t.GetChild(ci).GetComponent<MeshRenderer>();
                    if (r)
                    {
                        r.SetPropertyBlock(properties);
                    }
                }
            }
        }
    }

    // Update is called once per frame
    void Update()
    {
        
    }
}
