//
//  BattleFieldShaders.metal
//  Xe-Ra-Ku
//
//  Created by Tufan Cakir on 08.11.26.
//

#include <metal_stdlib>
using namespace metal;

struct BattleFieldUniforms {
    float2 resolution;
    float time;
    float intensity;
};

struct BattleFieldVertexOut {
    float4 position [[position]];
};

vertex BattleFieldVertexOut battleFieldVertex(uint id [[vertex_id]]) {
    const float2 positions[3] = {
        float2(-1.0, -1.0), float2(3.0, -1.0), float2(-1.0, 3.0)
    };
    BattleFieldVertexOut out;
    out.position = float4(positions[id], 0.0, 1.0);
    return out;
}

namespace BattleDigital {
    float hash(float2 p) {
        return fract(sin(dot(p, float2(127.1, 311.7))) * 43758.5453);
    }

    float boxDistance(float2 p, float2 halfSize) {
        float2 d = abs(p) - halfSize;
        return length(max(d, 0.0)) + min(max(d.x, d.y), 0.0);
    }

    float line(float distance, float width, float aa) {
        return 1.0 - smoothstep(width, width + aa, abs(distance));
    }

    // Derivatives preserve thin lines in the distance without a noisy horizon.
    float grid(float2 p, float width) {
        float2 footprint = max(fwidth(p), float2(0.0001));
        float2 d = abs(fract(p - 0.5) - 0.5);
        float2 lines = 1.0 - smoothstep(float2(width), float2(width) + footprint, d);
        float fade = 1.0 - smoothstep(0.2, 0.65, max(footprint.x, footprint.y));
        return max(lines.x, lines.y) * fade;
    }

    float circuits(float2 p) {
        float2 cell = floor(p);
        float2 q = fract(p) - 0.5;
        float seed = hash(cell);
        float aa = max(length(fwidth(p)), 0.001);
        float direction = seed > 0.5 ? 1.0 : -1.0;
        q.x *= direction;

        // Two orthogonal tracks with a short diagonal elbow.
        float vertical = line(q.x + 0.22, 0.009, aa)
            * (1.0 - smoothstep(0.12, 0.15, q.y));
        float horizontal = line(q.y - 0.24, 0.009, aa)
            * smoothstep(-0.10, -0.07, q.x);
        float elbow = line(q.y - q.x - 0.34, 0.013, aa)
            * smoothstep(-0.24, -0.21, q.x)
            * (1.0 - smoothstep(-0.10, -0.07, q.x));
        float terminal = line(length(q - float2(0.32, 0.24)) - 0.045, 0.008, aa);
        return max(max(vertical, horizontal), max(elbow, terminal))
            * step(0.32, seed);
    }

    float panels(float2 p, float time) {
        float2 cell = floor(p);
        float2 q = fract(p) - 0.5;
        float seed = hash(cell + 19.0);
        float2 size = float2(0.12 + seed * 0.18, 0.23 + seed * 0.19);
        float d = boxDistance(q, size);
        float aa = max(length(fwidth(p)), 0.001);
        float rim = line(d, 0.008, aa);
        float halo = exp(-abs(d) * 28.0) * 0.18;
        float pulse = 0.65 + 0.35 * sin(time * 0.6 + seed * 12.0);
        return (rim + halo) * pulse * step(0.48, seed);
    }
}

fragment float4 battleFieldFragment(
    BattleFieldVertexOut in [[stage_in]],
    constant BattleFieldUniforms &u [[buffer(0)]]
) {
    using namespace BattleDigital;
    float2 resolution = max(u.resolution, float2(1.0));
    float2 uv = in.position.xy / resolution;
    float aspect = resolution.x / resolution.y;
    float2 screen = float2((uv.x - 0.5) * aspect, uv.y - 0.5);

    // A tilted floor extends beyond every edge, like a continuous digital arena.
    // The positive denominator avoids the old singularity above the horizon.
    float depth = 0.34 + uv.y * 0.92;
    float2 floorUV = float2(
        (screen.x + (uv.y - 0.5) * 0.12) * 7.5 / depth,
        3.5 / depth
    );
    float time = u.time;
    float2 flow = floorUV + float2(0.0, time * 0.035);

    float centerGlow = exp(-dot(screen * float2(1.4, 0.8),
                                       screen * float2(1.4, 0.8)) * 3.0);
    float3 color = mix(float3(0.002, 0.008, 0.09),
                       float3(0.008, 0.025, 0.48), centerGlow);

    float major = grid(floorUV, 0.018);
    float minor = grid(floorUV * 4.0, 0.012);
    float broad = grid(floorUV, 0.075);
    color += float3(0.0, 0.10, 0.75) * broad * 0.32;
    color += float3(0.015, 0.27, 0.95) * major * 0.65;
    color += float3(0.0, 0.09, 0.40) * minor * 0.28;

    float tracks = circuits(flow * 1.25);
    color += float3(0.015, 0.32, 0.85) * tracks * 0.65;
    color += float3(0.015, 0.23, 0.95) * panels(flow * 0.8, time) * 0.65;

    // A second, screen-space layer gives the floating holograms depth.
    float2 hologramUV = screen * float2(8.0, 5.0);
    hologramUV.y += time * 0.025;
    color += float3(0.02, 0.22, 0.85) * panels(hologramUV, time) * 0.32;

    float sweep = exp(-pow((fract(floorUV.y * 0.13 - time * 0.045) - 0.5) * 24.0, 2.0));
    color += float3(0.0, 0.10, 0.40) * sweep * 0.4;

    // Sparse light nodes, with soft halos rather than full-screen flashing.
    float2 particleUV = screen * 13.0;
    float2 cell = floor(particleUV);
    float seed = hash(cell + 71.0);
    float2 point = float2(hash(cell + 3.0), hash(cell + 8.0)) * 0.6 + 0.2;
    float distance = length(fract(particleUV) - point);
    float sparkle = exp(-distance * distance * 950.0)
        + exp(-distance * distance * 65.0) * 0.16;
    float twinkle = 0.55 + 0.45 * sin(time * 1.2 + seed * 30.0);
    color += float3(0.35, 0.65, 1.0) * sparkle * twinkle * step(0.94, seed);

    // Darken the playable center slightly so card outlines stay readable.
    float centerBand = exp(-pow((uv.y - 0.52) * 7.0, 2.0));
    color *= 1.0 - centerBand * 0.25;
    float vignette = 1.0 - smoothstep(0.30, 0.82, length((uv - 0.5) * float2(1.1, 0.85)));
    color *= 0.65 + 0.35 * vignette;
    color *= max(u.intensity, 0.0);
    return float4(saturate(color), 1.0);
}
