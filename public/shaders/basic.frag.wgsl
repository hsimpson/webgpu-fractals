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

struct Material {
    baseColor: vec3<f32>,
}

struct Surface {
    distance: f32,
    material: Material,
}

// signed distance function for a sphere
// @param center: center of sphere
// @param radius: radius of sphere
// @return distance from point to sphere
fn sdSphere(p: vec3<f32>, r: f32) -> f32 {
    return length(p) - r;
}

// signed distance function for a box
// @param p: point in space
// @param b: box dimensions
// @return distance from point to box
fn sdBox(p: vec3<f32>, b: vec3<f32>) -> f32 {
    var d = abs(p) - b;
    return length(max(d, vec3(0.0))) + min(max(d.x, max(d.y, d.z)), 0.0);
}

// signed distance function for round box
// @param p: point in space
// @param b: box dimensions
// @param r: corner radius of the box
// @return distance from point to round box
fn sdRoundBox(p: vec3<f32>, b: vec3<f32>, r: f32) -> f32 {
    var d = abs(p) - b;
    return length(max(d, vec3(0.0))) + min(max(d.x, max(d.y, d.z)), 0.0) - r;
}

fn sdFloor(p: vec3<f32>) -> f32 {
    return p.y + 0.5;
}

// boolean operator subtract
// @param d1: distance to object 1
// @param d2: distance to object 2
// @return distance to the subtracted object
fn opSubtraction(d1: f32, d2: f32) -> f32 {
    return max(-d1, d2);
}

// boolean operator smooth-subtraction
// @param d1: distance to object 1
// @param d2: distance to object 2
// @return distance to the smooth-subtracted object
fn opSmoothSubtraction(d1: f32, d2: f32, k: f32) -> f32 {
    return -opSmoothUnion(d1, -d2, k);
}

fn opUnion(d1: f32, d2: f32) -> f32 {
    return min(d1, d2);
}

// boolean operator smooth-union
// @param d1: distance to object 1
// @param d2: distance to object 2
// @return distance to the smooth-union object
fn opSmoothUnion(d1: f32, d2: f32, k: f32) -> f32 {
    let h = max(k - abs(d1 - d2), 0.0);
    return min(d1, d2) - h * h * 0.25 / k;
}



fn sdScene(p: vec3<f32>, rotation: mat3x3<f32>) -> f32 {
    var an: f32 = sin(params.time);

    // var displacement = sin(5.0 * p.x) * sin(5.0 * p.y) * sin(5.0 * p.z) * 0.25;
    
    var p1 = p * rotation;

    var sphere1Surface: Surface;
    var sphere1Material: Material;
    sphere1Material.baseColor = vec3<f32>(1.0, 0.0, 0.0);
    sphere1Surface.material = sphere1Material;
    // assume that the sphere is centered at the origin and has unit radius
    sphere1Surface.distance = sdSphere(p1, 1.0);

    var sphere2Surface: Surface;
    var sphere2Material: Material;
    sphere2Material.baseColor = vec3<f32>(0.0, 0.0, 0.0);
    sphere2Surface.material = sphere2Material;
    // assume that the sphere is centered at the origin and has unit radius
    sphere2Surface.distance = sdSphere(p1 - vec3<f32>(0.8, 0.4, 1.65), 1.0);


    let sub1 = opSubtraction(sphere1Surface.distance, sphere2Surface.distance);

    var roundBoxSurface: Surface;
    var roundBoxMaterial: Material;
    roundBoxMaterial.baseColor = vec3<f32>(0.0, 0.0, 1.0);
    roundBoxSurface.material = roundBoxMaterial;
    roundBoxSurface.distance = sdRoundBox(p1 - vec3<f32>(-1.0 + 0.1 * an, 0.0, 0.0), vec3<f32>(0.5, 0.5, 0.5), 0.05);

    var sphere3Surface: Surface;
    var sphere3Material: Material;
    sphere3Material.baseColor = vec3<f32>(0.0, 0.0, 0.0);
    sphere3Surface.material = sphere3Material;
    // assume that the sphere is centered at the origin and has unit radius
    sphere3Surface.distance = sdSphere(p1 - vec3<f32>(-2.0 + 0.5 * -an, 0.0, 0.0), 0.25);

    let smoothSub = opSmoothSubtraction(sphere3Surface.distance, roundBoxSurface.distance, 0.25);

    var smoothUnion = opSmoothUnion(sub1, smoothSub, 0.2);

    var floorSurface: Surface;
    var floorMaterial: Material;
    floorMaterial.baseColor = vec3<f32>(0.4);
    floorSurface.material = floorMaterial;
    floorSurface.distance = sdFloor(p1);
    
    var d = opUnion(smoothUnion, floorSurface.distance);

    return d;
}

fn calcNormal(p: vec3<f32>, rotation: mat3x3<f32>) -> vec3<f32> {
    var e = vec2<f32>(1.0, -1.0) * 0.0005; // epsilon
    return normalize(
        e.xyy * sdScene(p + e.xyy, rotation) + 
        e.yyx * sdScene(p + e.yyx, rotation) + 
        e.yxy * sdScene(p + e.yxy, rotation) + 
        e.xxx * sdScene(p + e.xxx, rotation)
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
    var backgroundColor = vec3<f32>(0.7);

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
