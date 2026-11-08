//
//  TechTunnelShaders.metal
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
    float2 uv;
};

// MARK: - Vertex

vertex VertexOut techVertex(uint id [[vertex_id]]) {
    const float2 positions[3] = {
        float2(-1.0, -1.0),
        float2( 3.0, -1.0),
        float2(-1.0,  3.0)
    };

    VertexOut out;
    out.position = float4(positions[id], 0.0, 1.0);
    out.uv = positions[id] * 0.5 + 0.5;
    return out;
}

// MARK: - Helpers

inline float hash11(float x) {
    return fract(sin(x * 127.1) * 43758.5453);
}

inline float squareDistance(float2 p, float size) {
    float2 q = abs(p) - size;
    return length(max(q, 0.0)) +
           min(max(q.x, q.y), 0.0);
}

inline float segmentDistance(
    float2 p,
    float2 a,
    float2 b
) {
    float2 ab = b - a;
    float denominator = max(dot(ab, ab), 1e-6);
    float t = clamp(dot(p - a, ab) / denominator, 0.0, 1.0);
    float2 closest = a + t * ab;
    return length(p - closest);
}

inline float lineMask(float distance, float width) {
    return 1.0 - smoothstep(width, width * 2.0, distance);
}

inline float visibility(float phase) {
    return smoothstep(0.0, 0.12, phase) *
           (1.0 - smoothstep(0.88, 1.0, phase));
}

// MARK: - Fragment

fragment float4 techFragment(
    VertexOut in [[stage_in]],
    constant TechUniforms &u [[buffer(0)]]
) {
    float2 resolution = max(u.resolution, float2(1.0));
    float2 uv = in.position.xy / resolution;

    float aspect = resolution.x / resolution.y;
    float2 p = (uv - 0.5) * float2(aspect, 1.0);

    float time = u.time * u.speed;
    float radius = length(p);

    float3 color = float3(0.003, 0.008, 0.055);

    // MARK: Atmosphere

    color += float3(0.005, 0.025, 0.16) *
             exp(-radius * 4.0);

    // MARK: Tunnel Rings

    constexpr int ringCount = 14;

    for (int i = 0; i < ringCount; ++i) {
        float phase = fract(
            float(i) / float(ringCount) - time * 0.12
        );

        float fade = visibility(phase);

        if (fade < 0.001) {
            continue;
        }

        float z = mix(12.0, 0.65, phase);
        float halfSize = 2.2 / z;
        float width = 0.0015 + phase * 0.004;

        float distance = abs(
            squareDistance(p, halfSize)
        );

        // Reject pixels outside the ring halo
        if (distance > width * 10.0) {
            continue;
        }

        float ring = lineMask(distance, width);
        float halo = lineMask(distance, width * 5.0);

        color += ring * fade *
                 float3(0.02, 0.23, 0.85);

        color += halo * fade *
                 float3(0.005, 0.035, 0.14);
    }

    // MARK: Radial Lines

    constexpr int radialCount = 12;

    for (int i = 0; i < radialCount; ++i) {
        float angle = float(i) *
                      (6.2831853 / float(radialCount));

        float2 direction = float2(
            cos(angle),
            sin(angle)
        );

        float distance = segmentDistance(
            p,
            direction * 0.015,
            direction * 3.4
        );

        float line = lineMask(distance, 0.0018);

        color += line * float3(0.01, 0.08, 0.32);
    }

    // MARK: Electronic Traces

    constexpr int traceCount = 28;

    for (int i = 0; i < traceCount; ++i) {
        float seed = float(i);

        float angle = hash11(seed * 3.17) * 6.2831853;
        float distanceFromCenter = mix(
            0.5,
            2.0,
            hash11(seed * 7.91)
        );

        float phase = fract(
            hash11(seed * 11.3) - time * 0.22
        );

        float fade = visibility(phase);

        if (fade < 0.001) {
            continue;
        }

        float z = mix(11.0, 0.7, phase);

        float2 direction = float2(
            cos(angle),
            sin(angle)
        );

        float2 screen =
            direction * (distanceFromCenter / z);

        float lengthScale = 0.015 + phase * 0.10;
        float2 tail = screen - direction * lengthScale;

        float width = 0.001 + phase * 0.003;

        // Cheap bounding check
        float2 boundsMin = min(screen, tail) - width * 10.0;
        float2 boundsMax = max(screen, tail) + width * 10.0;

        if (any(p < boundsMin) || any(p > boundsMax)) {
            continue;
        }

        float distance = segmentDistance(p, tail, screen);

        float trace = lineMask(distance, width);
        float halo = lineMask(distance, width * 5.0);

        color += trace * fade *
                 float3(0.08, 0.55, 1.0);

        color += halo * fade *
                 float3(0.005, 0.06, 0.18);
    }

    // MARK: Particles

    constexpr int particleCount = 40;

    for (int i = 0; i < particleCount; ++i) {
        float seed = float(i) + 100.0;

        float angle = hash11(seed * 5.3) * 6.2831853;
        float particleRadius =
            sqrt(hash11(seed * 9.1)) * 2.6;

        float phase = fract(
            hash11(seed * 13.7) - time * 0.30
        );

        float fade = visibility(phase);

        if (fade < 0.001) {
            continue;
        }

        float z = mix(14.0, 0.6, phase);

        float2 position = float2(
            cos(angle),
            sin(angle)
        ) * (particleRadius / z);

        float size = 0.001 + phase * 0.007;

        float2 delta = p - position;
        float distanceSquared = dot(delta, delta);

        float sizeSquared = max(size * size, 1e-6);

        // Skip particles that cannot affect this pixel
        if (distanceSquared > sizeSquared * 100.0) {
            continue;
        }

        float particle = exp(
            -distanceSquared / sizeSquared
        );

        float halo = exp(
            -distanceSquared / (sizeSquared * 12.0)
        );

        color += particle * fade *
                 float3(0.65, 0.9, 1.0);

        color += halo * fade *
                 float3(0.015, 0.09, 0.24);
    }

    // MARK: Vanishing Point

    color += exp(-radius * 13.0) *
             float3(0.025, 0.09, 0.32);

    // MARK: Vignette

    float vignette = 1.0 -
        smoothstep(0.35, 1.15, radius);

    color *= 0.55 + vignette * 0.45;

    // MARK: Intensity

    color *= max(u.intensity, 0.0);

    return float4(saturate(color), 1.0);
}
