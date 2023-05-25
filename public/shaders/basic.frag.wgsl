struct FragmentOutput {
    @location(0) fragColor: vec4<f32>,
}

/*
 * Signed distance functions for a sphere
 * @param p: point in space
 * @param c: center of sphere
 * @param r: radius of sphere
 */
fn sdfSphere(p: vec3<f32>, c: vec3<f32>, r: f32) -> f32 {
    return length(p - c) - r;
}

fn rayMarch(rayOrigin: vec3<f32>, rayDirection: vec3<f32>) -> vec3<f32> {
    var totalDistanceTraveled: f32 = 0.0;
    const numberOfSteps: i32 = 32;
    const minimumHitDistance: f32 = 0.001;
    const maximumDistance: f32 = 1000.0;

    for(var i = 0; i < numberOfSteps; i++) {
        // Calculate our current position along the ray
        var currentPosition = rayOrigin + totalDistanceTraveled * rayDirection;

        // assume that the sphere is centered at the origin
        // and has unit radius
        var distanceToSphere = sdfSphere(currentPosition, vec3<f32>(0.0, 0.0, 0.0), 1.0);

        if (distanceToSphere < minimumHitDistance) { // hit
            // We hit something! Return red for now
            return vec3<f32>(1.0, 0.0, 0.0);
        }

        if (totalDistanceTraveled > maximumDistance) { // miss
            break;
        }

        // accumulate the distance traveled thus far
        totalDistanceTraveled += distanceToSphere;
    }

    // If we get here, we didn't hit anything so just
    // return a background color (black)
    return vec3<f32>(0.0);
}

@fragment
fn main(@location(0) fragUV : vec2<f32>) -> FragmentOutput {
    var output : FragmentOutput;
    // convert from [0, 1] to [-1, 1]
    var uv = fragUV * 2.0 - 1.0;


    var cameraPosition = vec3<f32>(0.0, 0.0, -5.0);
    var rayOrigin = cameraPosition;
    var rayDistance = vec3<f32>(uv, 1.0);

    var color = rayMarch(rayOrigin, rayDistance);


    // output.fragColor = vec4(fragUV.x, fragUV.y, 0.0, 1.0);
    output.fragColor = vec4(color, 1.0);
    return output;
}
