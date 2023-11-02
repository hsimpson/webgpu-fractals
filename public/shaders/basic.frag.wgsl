struct FragmentOutput {
    @location(0) fragColor: vec4<f32>,
}

struct UBOParams {
   resolution: vec2<u32>,
   cameraPosition: vec3<f32>,
   cameraRotation: vec2<f32>,
}

@group(0) @binding(0) var<uniform> params: UBOParams;


var<private> MAX_MARCHING_STEPS: i32 = 255;
var<private> MIN_DIST: f32 = 0.0;
var<private> MAX_DIST: f32 = 100.0;
var<private> PRECISION: f32 = 0.001;


//
// Signed distance functions for a sphere
// @param p: point in space
// @param c: center of sphere
// @param r: radius of sphere
//
fn sdfSphere(p: vec3<f32>, c: vec3<f32>, r: f32) -> f32 {
    return length(p - c) - r;
}

fn opSubtration(d1: f32, d2: f32) -> f32 {
    return max(-d1, d2);
}

fn mapTheWorld(p: vec3<f32>, rotation: mat3x3<f32>) -> f32 {

    // var displacement = sin(5.0 * p.x) * sin(5.0 * p.y) * sin(5.0 * p.z) * 0.25;
    
    // assume that the sphere is centered at the origin
    // and has unit radius
    var p1 = p * rotation;
    var sphere1 = sdfSphere(p1, vec3<f32>(0.0, 0.0, 0.0), 1.0);
    var sphere2 = sdfSphere(p1, vec3<f32>(0.8, 0.4, 1.65), 1.0);

    return opSubtration(sphere2, sphere1);
    // return min(sphere1, sphere2);
    // return sphere1;
}

fn calcNormal(p: vec3<f32>, rotation: mat3x3<f32>) -> vec3<f32> {
    var e = vec2<f32>(1.0, -1.0) * 0.0005; // epsilon
    return normalize(
        e.xyy * mapTheWorld(p + e.xyy, rotation) + e.yyx * mapTheWorld(p + e.yyx, rotation) + e.yxy * mapTheWorld(p + e.yxy, rotation) + e.xxx * mapTheWorld(p + e.xxx, rotation)
    );
}

// Rotation matrix around the X axis.
fn rotateX(theta: f32) -> mat3x3<f32> {
    let c = cos(theta);
    let s = sin(theta);
    return mat3x3<f32>(
        vec3<f32>(1.0, 0.0, 0.0),
        vec3<f32>(0.0, c, -s),
        vec3<f32>(0.0, s, c)
    );
}

// Rotation matrix around the Y axis.
fn rotateY(theta: f32) -> mat3x3<f32> {
    let c = cos(theta);
    let s = sin(theta);
    return mat3x3<f32>(
        vec3<f32>(c, 0.0, s),
        vec3<f32>(0.0, 1.0, 0.0),
        vec3<f32>(-s, 0.0, c)
    );
}

// Rotation matrix around the Z axis.
fn rotateZ(theta: f32) -> mat3x3<f32> {
    let c = cos(theta);
    let s = sin(theta);
    return mat3x3<f32>(
        vec3<f32>(c, -s, 0.0),
        vec3<f32>(s, c, 0.0),
        vec3<f32>(0.0, 0.0, 1.0)
    );
}

fn rayMarch(rayOrigin: vec3<f32>, rayDirection: vec3<f32>, start: f32, end: f32, rotation: mat3x3<f32>) -> f32 {
    var depth = start;

    for (var i = 0; i < MAX_MARCHING_STEPS; i++) {
        var p = rayOrigin + depth * rayDirection;
        var dist = mapTheWorld(p, rotation);
        depth += dist;
        if dist < PRECISION || depth > end {
            break;
        }
    }
    return depth;
}

@fragment
fn main(@builtin(position) coord: vec4<f32>) -> FragmentOutput {
    var output: FragmentOutput;

    // see https://www.w3.org/TR/WGSL/#builtin-values
    // coord is the interpolated position of the current fragment
    // coord.xy is the pixel coordinate of the current fragment (0,0 top left and bottom right is viewport width, viewport height)
    var fragCoord = coord.xy;
    var iResolution = vec2<f32>(params.resolution);
   
    // correction of uv coordinates depending on resolutions
    // var uv = (fragCoord-.5*iResolution.xy)/iResolution.y;
    var uv = fragCoord / iResolution.xy; // [0, 1]
    uv -= 0.5; // [-0.5, 0.5]
    uv.x *= iResolution.x / iResolution.y; // [-0.5 * aspectRatio, 0.5 * aspectRatio]
    uv.y = -uv.y; // flip y axis

    // var cameraPosition = vec3<f32>(0.0, 0.0, 5.0);
    var rayOrigin = params.cameraPosition;
    var rayDirection = normalize(vec3<f32>(uv, -1.0));
    var backgroundColor = vec3<f32>(0.4);

    var color = vec3<f32>(0.0, 0.0, 0.0);

    let rotation = rotateX(params.cameraRotation.x) * rotateY(params.cameraRotation.y) * rotateZ(0.0);
    var distance = rayMarch(rayOrigin, rayDirection, MIN_DIST, MAX_DIST, rotation);
    if distance > MAX_DIST {
        // no hit
        color = backgroundColor;
    } else {
        // hit
        var hitPoint: vec3<f32> = rayOrigin + rayDirection * distance;
        var normal = calcNormal(hitPoint, rotation);
        var lightPosition = vec3<f32>(2.0, 2.0, 4.0);
        var directionToLight = normalize(lightPosition - hitPoint);

        // Calculate diffuse reflection by taking the dot product of 
        // the normal and the light direction.
        var diffuseIntensity = clamp(dot(normal, directionToLight), 0.0, 1.0);

        color = vec3<f32>(diffuseIntensity) * vec3<f32>(1.0, 0.0, 0.0);
    }

    output.fragColor = vec4(color, 1.0);
    return output;
}
