struct FragmentOutput {
    @location(0) fragColor: vec4<f32>,
}

struct UBOParams {
   resolution: vec2<u32>,
   cameraPosition: vec3<f32>,
   cameraRotation: vec2<f32>,
   time: f32,
}

@group(0) @binding(0) var<uniform> params: UBOParams;


// var<private> MAX_MARCHING_STEPS: i32 = 255;
var<private> MAX_MARCHING_STEPS: i32 = 512;
var<private> MIN_DIST: f32 = 0.0;
var<private> MAX_DIST: f32 = 100.0;
var<private> PRECISION: f32 = 0.001;

// signed distance functions for a sphere
// @param p: point in space
// @param r: radius of sphere
fn sdSphere(p: vec3<f32>, r: f32) -> f32 {
    return length(p) - r;
}

// signed distance functions for a box
// @param p: point in space
// @param b: box dimensions
fn sdBox(p: vec3<f32>, b: vec3<f32>) -> f32 {
    var d = abs(p) - b;
    return length(max(d, vec3(0.0))) + min(max(d.x, max(d.y, d.z)), 0.0);
}

fn sdRoundBox(p: vec3<f32>, b: vec3<f32>, r: f32) -> f32 {
    var d = abs(p) - b;
    return length(max(d, vec3(0.0))) + min(max(d.x, max(d.y, d.z)), 0.0) - r;
}

fn opSubtraction(d1: f32, d2: f32) -> f32 {
    return max(-d1, d2);
}

fn opSmoothUnion(d1: f32, d2: f32, k: f32) -> f32 {
    let h = max(k - abs(d1 - d2), 0.0);
    return min(d1, d2) - h * h * 0.25 / k;
}

fn opSmoothSubtraction(d1: f32, d2: f32, k: f32) -> f32 {
    return -opSmoothUnion(d1, -d2, k);
}

fn sdScene(p: vec3<f32>, rotation: mat3x3<f32>) -> f32 {
    var an: f32 = sin(params.time);

    // var displacement = sin(5.0 * p.x) * sin(5.0 * p.y) * sin(5.0 * p.z) * 0.25;
    
    // assume that the sphere is centered at the origin
    // and has unit radius
    var p1 = p * rotation;
    var sphere1 = sdSphere(p1, 1.0);
    var sphere2 = sdSphere(p1 - vec3<f32>(0.8, 0.4, 1.65), 1.0);

    var d1 = opSubtraction(sphere2, sphere1);

    var box1 = sdRoundBox(p1 - vec3<f32>(-1.0 + 0.1 * an, 0.0, 0.0), vec3<f32>(0.5, 0.5, 0.5), 0.05);
    var sphere3 = sdSphere(p1 - vec3<f32>(-2.0 + 0.5 * -an, 0.0, 0.0), 0.25);

    var d2 = opSmoothSubtraction(sphere3, box1, 0.25);



    var d = opSmoothUnion(d1, d2, 0.2);

    return d;
}

fn calcNormal(p: vec3<f32>, rotation: mat3x3<f32>) -> vec3<f32> {
    var e = vec2<f32>(1.0, -1.0) * 0.0005; // epsilon
    return normalize(
        e.xyy * sdScene(p + e.xyy, rotation) + e.yyx * sdScene(p + e.yyx, rotation) + e.yxy * sdScene(p + e.yxy, rotation) + e.xxx * sdScene(p + e.xxx, rotation)
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
        var dist = sdScene(p, rotation);
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
    var resolution = vec2<f32>(params.resolution);
   
    // correction of uv coordinates depending on resolutions
    // var uv = (fragCoord-.5*resolution.xy)/resolution.y;
    var uv = fragCoord / resolution.xy; // [0, 1]
    uv -= 0.5; // [-0.5, 0.5]
    uv.x *= resolution.x / resolution.y; // [-0.5 * aspectRatio, 0.5 * aspectRatio]
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
