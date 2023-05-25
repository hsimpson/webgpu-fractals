/*
2 triangles for a full viewport quad
Vertices:

     0/5                        1
        *********************** 
        *  *                  *
        *     *               *
        *         *           *
        *            *        *
        *               *     *
        *                  *  *
        ***********************
      4                         2/3

*/

var<private> pos = array<vec2<f32>, 6>(
    vec2(-1.0, 1.0),
    vec2(1.0, 1.0),
    vec2(1.0, -1.0),
    vec2(1.0, -1.0),
    vec2(-1.0, -1.0),
    vec2(-1.0, 1.0),
);

/*
UVs:

     0,0  -------------------->  1,0
      |  *********************** 
      |  *  *                  *
      |  *     *               *
      |  *         *           *
      |  *            *        *
      |  *               *     *
      |  *                  *  *
      ↓  ***********************
     0,1                        1,1

*/


var<private> uv = array<vec2<f32>, 6>(
    vec2(0.0, 0.0),
    vec2(1.0, 0.0),
    vec2(1.1, 1.1),
    vec2(1.1, 1.1),
    vec2(0.0, 1.0),
    vec2(0.0, 0.0),
);


struct VertexOutput {
    @builtin(position) position: vec4<f32>,
    @location(0) uv: vec2<f32>,
}


@vertex
fn main(@builtin(vertex_index) VertexIndex: u32) -> VertexOutput {
    var output: VertexOutput;
    output.position = vec4<f32>(pos[VertexIndex], 0.0, 1.0);
    output.uv = uv[VertexIndex];
    return output;
}