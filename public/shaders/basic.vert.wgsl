// 1 triangle for a full viewport quad
// via vertex index:
// 
//       0                                1
//         ******************************
//         *             | clipped  *
//         *             |       *
//         *-------------    *
//         *             *
//         * clipped *
//         *     *
//         * *
//         *
//       2
// 
// see: https://www.saschawillems.de/blog/2016/08/13/vulkan-tutorial-on-rendering-a-fullscreen-quad-without-buffers/
 

struct VertexOutput {
    @builtin(position) position: vec4<f32>,
}


@vertex
fn main(@builtin(vertex_index) vertexIndex: u32) -> VertexOutput {
    var output: VertexOutput;
    var uv = vec2<f32>(f32((vertexIndex << 1) & 2), f32(vertexIndex & 2));
    output.position = vec4<f32>(uv * 2.0 - 1.0, 0.0, 1.0);
    return output;
}