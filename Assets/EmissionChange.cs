using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class EmissionChange : MonoBehaviour
{
    MeshRenderer emissiveRenderer;
    Material material;
    // Start is called before the first frame update
    void Start()
    {
        emissiveRenderer = GetComponent<MeshRenderer>();
        material = GetComponent<MeshRenderer>().material;
    }

    // Update is called once per frame
    void Update()
    {
        Color c = Color.Lerp(Color.white, Color.black, Mathf.Sin(Time.time * Mathf.PI) * 0.5f + 0.5f);
        if (material)
        {
            material.SetColor("_Emission", c);
            //Debug.Log("11");
        }
        
        emissiveRenderer.UpdateGIMaterials();
    }
}
