//
//  TechTunnelRenderer.metal
//  Xe-Ra-Ku
//
//  Created by Tufan Cakir on 08.11.26.
//

#include <metal_stdlib>
using namespace metal;

struct TechUniforms {
    float2 resolution;
    float time;
    float speed;
    float intensity;
    float padding;
};

struct VertexOut {
    float4 position [[position]];
};

vertex VertexOut techVertex(uint id [[vertex_id]]) {
    const float2 positions[3] = {
        float2(-1.0, -1.0),
        float2( 3.0, -1.0),
        float2(-1.0,  3.0)
    };
    VertexOut out;
    out.position = float4(positions[id], 0.0, 1.0);
    return out;
}

namespace TechDigital {
    inline float hash(float2 p) {
        return fract(sin(dot(p, float2(127.1, 311.7))) * 43758.5453);
    }

    inline float stroke(float d, float width, float aa) {
        return 1.0 - smoothstep(width, width + aa, abs(d));
    }

    inline float grid(float2 p, float width) {
        float2 footprint = max(fwidth(p), float2(0.0001));
        float2 edge = min(fract(p), 1.0 - fract(p));
        float2 lines = 1.0 - smoothstep(float2(width), float2(width) + footprint, edge);
        float fade = 1.0 - smoothstep(0.20, 0.65, max(footprint.x, footprint.y));
        return max(lines.x, lines.y) * fade;
    }

    inline float circuits(float2 p) {
        float2 cell = floor(p);
        float2 q = fract(p) - 0.5;
        float seed = hash(cell);
        float aa = max(length(fwidth(p)), 0.001);
        q.x *= seed > 0.5 ? 1.0 : -1.0;

        float vertical = stroke(q.x + 0.22, 0.008, aa)
            * (1.0 - smoothstep(0.12, 0.16, q.y));
        float horizontal = stroke(q.y - 0.24, 0.008, aa)
            * smoothstep(-0.10, -0.06, q.x);
        float elbow = stroke(q.y - q.x - 0.34, 0.012, aa)
            * smoothstep(-0.24, -0.20, q.x)
            * (1.0 - smoothstep(-0.10, -0.06, q.x));
        return max(vertical, max(horizontal, elbow)) * step(0.52, seed);
    }

    inline float panels(float2 p, float time) {
        float2 cell = floor(p);
        float2 q = fract(p) - 0.5;
        float seed = hash(cell + 19.0);
        float2 halfSize = float2(0.15 + seed * 0.14, 0.19 + seed * 0.16);
        float2 d = abs(q) - halfSize;
        float sdf = length(max(d, 0.0)) + min(max(d.x, d.y), 0.0);
        float aa = max(length(fwidth(p)), 0.001);
        float rim = stroke(sdf, 0.008, aa);
        float pulse = 0.80 + 0.20 * sin(time * 0.5 + seed * 9.0);
        return rim * pulse * step(0.62, seed);
    }
}

fragment float4 techFragment(
    VertexOut in [[stage_in]],
    constant TechUniforms &u [[buffer(0)]]
) {
    using namespace TechDigital;

    float2 res = max(u.resolution, float2(1.0));
    float2 uv = in.position.xy / res;
    float aspect = res.x / res.y;
    float y = uv.y - 0.5;
    float distanceFromHorizon = abs(y);

    // One perspective mapping for the ceiling and floor.
    // Both planes meet at the horizon; no screen-space sliding.
    float depth = 0.20 / max(distanceFromHorizon, 0.012);
    float worldX = (uv.x - 0.5) * aspect * depth;
    float travel = u.time * u.speed * 0.85;
    float worldZ = depth + travel;
    float2 plane = float2(worldX * 2.4, worldZ * 1.8);

    float nearFade = smoothstep(0.035, 0.17, distanceFromHorizon);
    float distanceFade = 1.0 - smoothstep(0.24, 0.68, max(fwidth(plane.x), fwidth(plane.y)));
    float visibility = nearFade * distanceFade;

    // Rich blue center, dark enough to keep the logo legible.
    float centerGlow = exp(-pow(distanceFromHorizon * 3.4, 2.0));
    float3 color = mix(
        float3(0.002, 0.007, 0.065),
        float3(0.006, 0.025, 0.20),
        centerGlow * 0.55
    );

    float major = grid(plane, 0.022);
    float minor = grid(plane * 3.0, 0.009);
    float broad = grid(plane, 0.075);

    color += float3(0.00, 0.09, 0.48) * broad * 0.24 * visibility;
    color += float3(0.015, 0.27, 0.95) * major * 0.82 * visibility;
    color += float3(0.00, 0.09, 0.40) * minor * 0.23 * visibility;

    // All detail uses the same forward-moving world coordinates.
    float2 detail = float2(worldX * 1.2, worldZ * 0.85);
    color += float3(0.015, 0.32, 0.85) * circuits(detail) * 0.65 * visibility;
    color += float3(0.015, 0.22, 0.90) * panels(detail * 0.75, u.time) * 0.55 * visibility;

    // Soft scan line traveling toward the viewer along both planes.
    float sweep = exp(-pow((fract(worldZ * 0.14) - 0.5) * 19.0, 2.0));
    color += float3(0.00, 0.07, 0.25) * sweep * 0.30 * visibility;

    // Quiet central area and subtle vignette; no particles.
    float centerBand = 1.0 - smoothstep(0.025, 0.12, distanceFromHorizon);
    color *= 1.0 - centerBand * 0.20;
    float vignette = 1.0 - smoothstep(0.25, 0.78, length((uv - 0.5) * float2(1.1, 0.85)));
    color *= 0.70 + 0.30 * vignette;
    color *= max(u.intensity, 0.0);
    return float4(saturate(color), 1.0);
}
