/*
2 triangles for a full viewport quad
Vertices:

      5                        0/3
        **********************
        *                 *  *
        *              *     *
        *           *        *
        *        *           *
        *     *              *
        *  *                 *
        **********************
    2/4                        1

*/

var<private> pos = array<vec2<f32>, 6>(
    vec2( 1.0,  1.0), // top right
    vec2( 1.0, -1.0), // bottom right
    vec2(-1.0, -1.0), // bottom left
    vec2( 1.0,  1.0), // top right
    vec2(-1.0, -1.0), // bottom left
    vec2(-1.0,  1.0), // top left
);

/*
UVs:

     0,0 --------------------->  1,0
      |  **********************
      |  *                 *  *
      |  *              *     *
      |  *           *        *
      |  *        *           *
      |  *     *              *
      |  *  *                 *
      ↓  **********************
     0,1                        1,1

*/
// var<private> uv = array<vec2<f32>, 6>(
//     vec2(1.0, 0.0), // top right
//     vec2(1.0, 1.0), // bottom right
//     vec2(0.0, 1.0), // bottom left
//     vec2(1.0, 0.0), // top right
//     vec2(0.0, 1.0), // bottom left
//     vec2(0.0, 0.0), // top left
// );


/*
UVs:

     0,1 --------------------->  1,1
      |  **********************
      |  *                 *  *
      |  *              *     *
      |  *           *        *
      |  *        *           *
      |  *     *              *
      |  *  *                 *
      ↓  **********************
     0,0                        1,0

*/
var<private> uv = array<vec2<f32>, 6>(
    vec2(1.0, 1.0), // top right
    vec2(1.0, 0.0), // bottom right
    vec2(0.0, 0.0), // bottom left
    vec2(1.0, 1.0), // top right
    vec2(0.0, 0.0), // bottom left
    vec2(0.0, 1.0), // top left
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