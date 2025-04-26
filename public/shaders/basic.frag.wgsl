struct FragmentOutput {
    @location(0) fragColor: vec4<f32>,
}

struct UBOParams {
    resolution: vec2<f32>,
    cameraPosition: vec3<f32>,
    cameraRotation: mat3x3<f32>,
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

fn mixMaterial(m1: Material, m2: Material, k: f32) -> Material {
    let color = mix(m1.baseColor, m2.baseColor, k);
    return Material(color);
}

// signed distance function for a sphere
// @param center: center of sphere
// @param radius: radius of sphere
// @param material: material of sphere
fn sdSphere(p: vec3<f32>, r: f32, material: Material) -> Surface {
    var distance = length(p) - r;
    return Surface(distance, material);
}

// signed distance function for a box
// @param p: point in space
// @param b: box dimensions
// @param material: material of sphere
fn sdBox(p: vec3<f32>, b: vec3<f32>, material: Material) -> Surface {
    var box = abs(p) - b;
    var distance = length(max(box, vec3(0.0))) + min(max(box.x, max(box.y, box.z)), 0.0);
    return Surface(distance, material);
}

// signed distance function for round box
// @param p: point in space
// @param b: box dimensions
// @param r: corner radius of the box
fn sdRoundBox(p: vec3<f32>, b: vec3<f32>, r: f32, material: Material) -> Surface {
    var box = abs(p) - b;
    var distance = length(max(box, vec3(0.0))) + min(max(box.x, max(box.y, box.z)), 0.0) - r;
    return Surface(distance, material);
}

fn sdFloor(p: vec3<f32>, material: Material) -> Surface {
    var distance = p.y + 1.0;
    return Surface(distance, material);
}

// operator subtract, subtracts object 1 from object 2
// @param s1: surface of object 1
// @param s2: surface of object 2
fn opSubtraction(s1: Surface, s2: Surface) -> Surface {
    // max(-d1,d2);
    if(-s1.distance > s2.distance) {
        return Surface(-s1.distance, s1.material);
    }
    return s2;
}

// operator smooth-subtraction, subtracts object 1 from object 2
// @param s1: surface of object 1
// @param s2: surface of object 2
// @param k: smoothness factor
fn opSmoothSubtraction(s1: Surface, s2: Surface, k: f32) -> Surface {
    // float h = clamp( 0.5 - 0.5*(d2+d1)/k, 0.0, 1.0 );
    // return mix( d2, -d1, h ) + k*h*(1.0-h);
    let h = clamp( 0.5 - 0.5 * (s2.distance + s1.distance) / k, 0.0, 1.0 );
    let distance = mix(s2.distance, -s1.distance, h) + k * h * (1.0 - h);
    return Surface(distance, mixMaterial(s2.material, s1.material, h));
}

// operator union of object 1 and object 2
// @param s1: surface of object 1
// @param s2: surface of object 2
fn opUnion(s1: Surface, s2: Surface) -> Surface {
    // return min(d1, d2);
    if(s1.distance < s2.distance) {
        return s1;
    }
    return s2;
}

// operator smooth-union of object 1 and object 2
// @param s1: surface of object 1
// @param s2: surface of object 2
// @param k: smoothness factor
fn opSmoothUnion(s1: Surface, s2: Surface, k: f32) -> Surface {
    // float h = clamp( 0.5 + 0.5*(d2-d1)/k, 0.0, 1.0 );
    // return mix( d2, d1, h ) - k*h*(1.0-h);
    let h = clamp(0.5 + 0.5 * (s2.distance - s1.distance) / k, 0.0, 1.0);
    let distance = mix(s2.distance, s1.distance, h) - k * h * (1.0 - h);
    return Surface(distance, mixMaterial(s2.material, s1.material, h));
}



fn sdScene(p: vec3<f32>, rotation: mat3x3<f32>) -> Surface {
    // let an: f32 = sin(params.time);
    // var displacement = sin(5.0 * p.x) * sin(5.0 * p.y) * sin(5.0 * p.z) * 0.25;
    
    let p1 = p * rotation;

    // create a red sphere
    let sphere1Material = Material(vec3<f32>(1.0, 0.0, 0.0));
    let sphere1Surface = sdSphere(p1, 1.0, sphere1Material);

    // create a green sphere
    let sphere2Material = Material(vec3<f32>(0.0, 1.0, 0.0));
    let sphere2Offset = p1 - vec3<f32>(1.0, 0.0, 0);
    let sphere2Surface = sdSphere(sphere2Offset, 0.5, sphere2Material);

    // subtract the green sphere from the red sphere
    let sphereSubtraction = opSubtraction(sphere2Surface, sphere1Surface);

    // create a blue round box
    let roundBoxMaterial = Material(vec3<f32>(0.0, 0.0, 1.0));
    let roundBoxOffset = p1 - vec3<f32>(-1.0, 0.0, 0.0);
    let roundBoxDimensions = vec3<f32>(0.5, 0.5, 0.5);
    let roundBoxSurface = sdRoundBox(roundBoxOffset, roundBoxDimensions, 0.05, roundBoxMaterial);
    
    // union of the red sphere and the blue round box
    let sphereBoxUnion = opSmoothUnion(sphereSubtraction, roundBoxSurface, 0.25);

    // create a yellow sphere
    let sphere3Material = Material(vec3<f32>(1.0, 1.0, 0.0));
    let sphere3Offset = p1 - vec3<f32>(-1.4, 0.0, 0.0);
    let sphere3Surface = sdSphere(sphere3Offset, 0.25, sphere3Material);

    // subtract the yellow sphere from the union of the red sphere and the blue round box
    let boxSubstration = opSmoothSubtraction(sphere3Surface, sphereBoxUnion, 0.25);

    let floorMaterial = Material(vec3<f32>(0.6));
    let floorSurface = sdFloor(p1, floorMaterial);
    
    let withFloor = opUnion(boxSubstration, floorSurface);

    return withFloor;
}

fn calcNormal(p: vec3<f32>, rotation: mat3x3<f32>) -> vec3<f32> {
    var e = vec2<f32>(1.0, -1.0) * 0.0005; // epsilon
    return normalize(
        e.xyy * sdScene(p + e.xyy, rotation).distance +
        e.yyx * sdScene(p + e.yyx, rotation).distance +
        e.yxy * sdScene(p + e.yxy, rotation).distance +
        e.xxx * sdScene(p + e.xxx, rotation).distance
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

fn rayMarch(rayOrigin: vec3<f32>, rayDirection: vec3<f32>, start: f32, end: f32, rotation: mat3x3<f32>) -> Surface {
    var depth = start;
    var closestObject: Surface;

    for (var i = 0; i < MAX_MARCHING_STEPS; i++) {
        var p = rayOrigin + depth * rayDirection;
        closestObject = sdScene(p, rotation);
        depth += closestObject.distance;
        if closestObject.distance < PRECISION || depth > end {
            break;
        }
    }
    return Surface(depth, closestObject.material);
}

@fragment
fn main(@builtin(position) coord: vec4<f32>) -> FragmentOutput {
    var output: FragmentOutput;

    // see https://www.w3.org/TR/WGSL/#builtin-values
    // coord is the interpolated position of the current fragment
    // coord.xy is the pixel coordinate of the current fragment (0,0 top left and bottom right is viewport width, viewport height)
    var fragCoord = coord.xy;
   
    // correction of uv coordinates depending on resolutions
    // var uv = (fragCoord-.5*resolution.xy)/resolution.y;
    var uv = fragCoord / params.resolution.xy; // [0, 1]
    uv -= 0.5; // [-0.5, 0.5]
    uv.x *= params.resolution.x / params.resolution.y; // [-0.5 * aspectRatio, 0.5 * aspectRatio]
    uv.y = -uv.y; // flip y axis

    // var cameraPosition = vec3<f32>(0.0, 0.0, 5.0);
    var rayOrigin = params.cameraPosition;
    var rayDirection = normalize(vec3<f32>(uv, -1.0));
    var backgroundColor = vec3<f32>(0.7);

    var color = vec3<f32>(0.0, 0.0, 0.0);

    //let rotation = rotateX(params.cameraRotation.x) * rotateY(params.cameraRotation.y) * rotateZ(0.0);
    let closestObject = rayMarch(rayOrigin, rayDirection, MIN_DIST, MAX_DIST, params.cameraRotation);
    if closestObject.distance > MAX_DIST {
        // no hit
        color = backgroundColor;
    } else {
        // hit
        var hitPoint: vec3<f32> = rayOrigin + rayDirection * closestObject.distance;
        var normal = calcNormal(hitPoint, params.cameraRotation);
        var lightPosition = vec3<f32>(2.0, 2.0, 4.0);
        var directionToLight = normalize(lightPosition - hitPoint);

        // Calculate diffuse reflection by taking the dot product of 
        // the normal and the light direction.
        var diffuseIntensity = clamp(dot(normal, directionToLight), 0.0, 1.0);

        // only use material basecolor for now
        color = closestObject.material.baseColor;
        color = vec3<f32>(diffuseIntensity) * color;
    }

    output.fragColor = vec4(color, 1.0);
    return output;
}
