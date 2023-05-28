struct FragmentOutput {
    @location(0) fragColor: vec4<f32>,
}

struct UBOParams {
   resolution: vec2<u32>,
}

@group(0) @binding(0) var<uniform> params: UBOParams;

/*
 * Signed distance functions for a sphere
 * @param p: point in space
 * @param c: center of sphere
 * @param r: radius of sphere
 */
fn sdfSphere(p: vec3<f32>, c: vec3<f32>, r: f32) -> f32 {
    return length(p - c) - r;
}

fn opSubtration(d1: f32, d2: f32) -> f32 {
    return max(-d1, d2);
}

fn mapTheWorld(p: vec3<f32>) -> f32 {

    // var displacement = sin(5.0 * p.x) * sin(5.0 * p.y) * sin(5.0 * p.z) * 0.25;
    
    // assume that the sphere is centered at the origin
    // and has unit radius
    var sphere1 = sdfSphere(p, vec3<f32>(0.0, 0.0, 0.0), 1.0);
    var sphere2 = sdfSphere(p, vec3<f32>(-0.8, 0.4, -1.65), 1.0);

    return opSubtration(sphere2, sphere1);
    // return min(sphere1, sphere2);
    // return sphere1;
}

fn calculateNormal(p: vec3<f32>) -> vec3<f32> {
    const smallStep = vec3<f32>(0.001, 0.0, 0.0);
    var normal = vec3<f32>(
        mapTheWorld(p + smallStep.xyy) - mapTheWorld(p - smallStep.xyy),
        mapTheWorld(p + smallStep.yxy) - mapTheWorld(p - smallStep.yxy),
        mapTheWorld(p + smallStep.yyx) - mapTheWorld(p - smallStep.yyx)
    );

    return normalize(normal);
}

fn rayMarch(rayOrigin: vec3<f32>, rayDirection: vec3<f32>) -> vec3<f32> {
    var totalDistanceTraveled: f32 = 0.0;
    const numberOfSteps: i32 = 32;
    const minimumHitDistance: f32 = 0.001;
    const maximumDistance: f32 = 1000.0;

    // For now, hard-code the light's position in our scene
    const lightPosition = vec3<f32>(2.0, -5.0, 3.0);

    for(var i = 0; i < numberOfSteps; i++) {
        // Calculate our current position along the ray
        var currentPosition = rayOrigin + totalDistanceTraveled * rayDirection;

        var distanceToSphere = mapTheWorld(currentPosition);

        if (distanceToSphere < minimumHitDistance) { // hit
            var normal = calculateNormal(currentPosition);

            // Calculate the unit direction vector that points from
            // the point of intersection to the light source
            var directionToLight = normalize(currentPosition - lightPosition);

            var diffuseIntensity = max(0.2, dot(normal, directionToLight));
            
            // Remember, each component of the normal will be in
            // the range -1..1, so for the purposes of visualizing
            // it as an RGB color, let's remap it to the range
            // 0..1
            //return normal * 0.5 + 0.5;

            return vec3<f32>(1.0, 0.1, 0.1) * diffuseIntensity;
            // return vec3<f32>(1.0, 0.1, 0.1);
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
fn main(@builtin(position) coord: vec4<f32> ) -> FragmentOutput {
    var output : FragmentOutput;

    // see https://www.w3.org/TR/WGSL/#builtin-values
    // coord is the interpolated position of the current fragment
    // coord.xy is the pixel coordinate of the current fragment (0,0 top left and bottom right is viewport width, viewport height)
    var fragCoord = coord.xy;
    var iResolution = vec2<f32>(params.resolution);
   
    // correction of uv coordinates depending on resolutions
    var uv = (fragCoord-.5*iResolution.xy)/iResolution.y;

    var cameraPosition = vec3<f32>(0.0, 0.0, -5.0);
    var rayOrigin = cameraPosition;
    var rayDirection = normalize(vec3<f32>(uv, 1.0));

    var color = rayMarch(rayOrigin, rayDirection);

    output.fragColor = vec4(color, 1.0);
    return output;
}
