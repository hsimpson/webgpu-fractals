struct FragmentOutput {
    @location(0) fragColor: vec4<f32>,
}

@fragment
fn main(@location(0) fragUV : vec2<f32>) -> FragmentOutput {
    var output : FragmentOutput;
    // convert from [0, 1] to [-1, 1]
    var uv = fragUV * 2.0 - 1.0;

    output.fragColor = vec4(fragUV.x, fragUV.y, 0.0, 1.0);
    return output;
}
