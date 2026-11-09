//
//  BattleFieldShaders.metal
//  Xe-Ra-Ku
//
//  Created by Tufan Cakir on 09.11.26.
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
    float2 uv;
};

vertex BattleFieldVertexOut battleFieldVertex(
    uint id [[vertex_id]]
) {
    const float2 positions[3] = {
        float2(-1.0, -1.0),
        float2( 3.0, -1.0),
        float2(-1.0,  3.0)
    };

    BattleFieldVertexOut out;
    out.position = float4(positions[id], 0.0, 1.0);
    out.uv = positions[id] * 0.5 + 0.5;
    return out;
}

fragment float4 battleFieldFragment(
    BattleFieldVertexOut in [[stage_in]],
    constant BattleFieldUniforms &u [[buffer(0)]]
) {
    float2 resolution = max(u.resolution, float2(1.0));
    float2 uv = in.position.xy / resolution;

    float time = u.time;

    float3 color = float3(0.005, 0.015, 0.055);

    // Perspective coordinates
    float horizon = 0.18;
    float depth = max(uv.y - horizon, 0.001);

    float perspective = 1.0 / depth;

    float2 gridUV = float2(
        (uv.x - 0.5) * perspective,
        perspective * 0.25
    );

    // Animated grid
    float2 grid = abs(fract(gridUV * 2.0) - 0.5);

    float verticalLines =
        1.0 - smoothstep(0.015, 0.035, grid.x);

    float horizontalLines =
        1.0 - smoothstep(0.015, 0.035, grid.y);

    float gridMask = max(
        verticalLines,
        horizontalLines
    );

    // Fade toward horizon
    float fade = smoothstep(
        horizon,
        0.85,
        uv.y
    );

    color += gridMask * fade *
             float3(0.01, 0.18, 0.55);

    // Moving energy wave
    float wave = sin(
        gridUV.y * 3.0 - time * 2.0
    );

    color += pow(max(wave, 0.0), 12.0) *
             fade *
             float3(0.0, 0.12, 0.35);

    // Center light
    float center = exp(
        -abs(uv.x - 0.5) * 6.0
    );

    color += center *
             float3(0.005, 0.02, 0.08);

    // Vignette
    float2 centered = uv - 0.5;
    float vignette = 1.0 - smoothstep(
        0.3,
        0.8,
        length(centered)
    );

    color *= 0.55 + vignette * 0.45;
    color *= max(u.intensity, 0.0);

    return float4(saturate(color), 1.0);
}
