#!/usr/bin/env python3
"""
Magic Circle Lock Screen - Stroke Evaluator
Calculates how close a drawn stroke path is to a perfect circle.
Receives JSON array of (x,y) points from standard input or file argument.
Outputs a percentage score from 0.0 to 100.0.
"""

import sys
import json
import math

def evaluate_circle(points):
    """
    Evaluates a sequence of points to determine how closely they approximate a circle.
    Returns a percentage score (0.0 to 100.0).
    """
    if not points or len(points) < 15:
        return 0.0

    # Normalize point format: extract (x, y) tuples
    coords = []
    for pt in points:
        if isinstance(pt, dict):
            if 'x' in pt and 'y' in pt:
                coords.append((float(pt['x']), float(pt['y'])))
        elif isinstance(pt, (list, tuple)) and len(pt) >= 2:
            coords.append((float(pt[0]), float(pt[1])))

    n = len(coords)
    if n < 15:
        return 0.0

    # 1. Calculate Centroid (mean (c_x, c_y))
    sum_x = sum(x for x, y in coords)
    sum_y = sum(y for x, y in coords)
    c_x = sum_x / n
    c_y = sum_y / n

    # 2. Calculate distances from centroid to each point (radii)
    radii = [math.hypot(x - c_x, y - c_y) for x, y in coords]

    # 3. Calculate Average Radius
    avg_radius = sum(radii) / n
    if avg_radius < 30.0:
        # Stroke is too small (e.g. dot or tiny scribble)
        return 0.0

    # 4. Measure Variance and Standard Deviation of radii
    variance = sum((r - avg_radius) ** 2 for r in radii) / n
    std_dev = math.sqrt(variance)

    # Coefficient of Variation (CV = std_dev / avg_radius)
    # For a perfect circle, std_dev = 0, so CV = 0.
    cv = std_dev / avg_radius

    # Base radial score: map CV to percentage (0 to 100)
    # A circle with CV <= 0.05 scores >= 95.0%
    base_score = max(0.0, min(100.0, (1.0 - cv) * 100.0))

    # 5. Closure & Continuity Checks
    # Check distance between start and end points
    start_x, start_y = coords[0]
    end_x, end_y = coords[-1]
    gap_distance = math.hypot(end_x - start_x, end_y - start_y)
    gap_ratio = gap_distance / avg_radius

    # If the gap between start and end is significant (> 35% of radius), apply deduction
    closure_penalty = 0.0
    if gap_ratio > 0.35:
        closure_penalty = (gap_ratio - 0.35) * 30.0

    # Check cumulative angle around centroid to ensure full 360 loop (not just a clean arc)
    total_angle = 0.0
    for i in range(1, n):
        a1 = math.atan2(coords[i-1][1] - c_y, coords[i-1][0] - c_x)
        a2 = math.atan2(coords[i][1] - c_y, coords[i][0] - c_x)
        diff = a2 - a1
        # Normalize angle difference to [-pi, pi]
        while diff > math.pi:
            diff -= 2 * math.pi
        while diff < -math.pi:
            diff += 2 * math.pi
        total_angle += diff

    # If the total angular sweep absolute value is far from 2*pi (360 degrees), deduct score
    angle_sweep = abs(total_angle)
    angle_penalty = 0.0
    if angle_sweep < (2 * math.pi * 0.85): # Less than 85% of full circle (~306 degrees)
        missing_fraction = (2 * math.pi * 0.85 - angle_sweep) / (2 * math.pi * 0.85)
        angle_penalty = missing_fraction * 50.0

    final_score = max(0.0, base_score - closure_penalty - angle_penalty)
    return round(final_score, 2)

def main():
    raw_data = ""
    if len(sys.argv) > 1:
        try:
            with open(sys.argv[1], 'r', encoding='utf-8') as f:
                raw_data = f.read()
        except Exception as e:
            sys.stderr.write(f"Error reading file: {e}\n")
            print("0.0")
            sys.exit(1)
    else:
        # Read from standard input using readline first for instant processing when newline terminated
        try:
            raw_data = sys.stdin.readline()
            if not raw_data.strip():
                raw_data = sys.stdin.read()
        except Exception as e:
            sys.stderr.write(f"Error reading stdin: {e}\n")
            print("0.0")
            sys.exit(1)

    if not raw_data.strip():
        print("0.0")
        sys.exit(0)

    try:
        points = json.loads(raw_data)
        score = evaluate_circle(points)
        print(score)
    except Exception as e:
        sys.stderr.write(f"Error evaluating circle: {e}\n")
        print("0.0")

if __name__ == '__main__':
    main()
