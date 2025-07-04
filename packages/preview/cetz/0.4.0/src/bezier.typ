// This file contains functions related to bezier curve calculation
// Many functions are ports from https://github.com/Pomax/bezierjs
#import "vector.typ"
#import "aabb.typ"
#import "wasm.typ": call_wasm

#let cetz-core = plugin("../cetz-core/cetz_core.wasm")

// Map number v from range (ds, de) to (ts, te)
#let _map(v, ds, de, ts, te) = {
  let d1 = de - ds
  let d2 = te - ts
  let v2 = v - ds
  let r = v2 / d1
  return ts + d2 * r
}

/// Get the point on quadratic bezier at position `t`.
///
/// - a (vector): Start point
/// - b (vector): End point
/// - c (vector): Control point
/// - t (float): Position on curve $[0, 1]$
/// -> vector
#let quadratic-point(a, b, c, t) = {
  // (1-t)^2 * a + 2 * (1-t) * t * c + t^2 b
  return vector.add(
    vector.add(
      vector.scale(a, calc.pow(1-t, 2)),
      vector.scale(c, 2 * (1-t) * t)
    ),
    vector.scale(b, calc.pow(t, 2))
  )
}

/// Get the derivative (dx/dt) of a quadratic bezier at position `t`.
///
/// - a (vector): Start point
/// - b (vector): End point
/// - c (vector): Control point
/// - t (float): Position on curve [0, 1]
/// -> vector
#let quadratic-derivative(a, b, c, t) = {
  // 2(-a(1-t) + bt - 2ct + c)
  return vector.scale(
    vector.add(
      vector.sub(
        vector.add(
          vector.scale(vector.neg(a), (1 - t)),
          vector.scale(b, t)),
        vector.scale(c, 2 * t)),
      c)
  , 2)
}

/// Get the point on a cubic bezier curve at position `t`.
///
/// - a (vector):  Start point
/// - b (vector):  End point
/// - c1 (vector): Control point 1
/// - c2 (vector): Control point 2
/// - t (float):   Position on curve [0, 1]
/// -> vector
#let cubic-point(a, b, c1, c2, t) = {
  // (1-t)^3*a + 3*(1-t)^2*t*c1 + 3*(1-t)*t^2*c2 + t^3*b
  vector.add(
    vector.add(
      vector.scale(a, calc.pow(1-t, 3)),
      vector.scale(c1, 3 * calc.pow(1-t, 2) * t)
    ),
    vector.add(
      vector.scale(c2, 3*(1-t)*calc.pow(t,2)),
      vector.scale(b, calc.pow(t, 3))
    )
  )
}

/// Get the derivative (dx/dt) of a cubic bezier at position `t`.
///
/// - a (vector): Start point
/// - b (vector): End point
/// - c1 (vector): Control point 1
/// - c2 (vector): Control point 2
/// - t (float): Position on curve [0, 1]
/// -> vector
#let cubic-derivative(a, b, c1, c2, t) = {
  // -3(a(1-t)^2 + t(-2c2 - bt + 3 c2 t) + c1(-1 + 4t - 3t^2))
  vector.scale(
    vector.add(
      vector.add(
        vector.scale(a, calc.pow((1 - t), 2)),
        vector.scale(
          vector.sub(
            vector.add(
              vector.scale(b, -1 * t),
              vector.scale(c2, 3 * t)
            ),
            vector.scale(c2, 2)
          ),
          t
        )
      ),
      vector.scale(c1, -3 * calc.pow(t, 2) + 4 * t - 1)
    ),
    -3
  )
}

/// Get a bezier curve's ABC coordinates. Returns them as a respective <Type>array</Type> of <Type>vector</Type>s.
/// ```
///        /A\  <-- Control point of quadratic bezier
///       / | \
///      /  |  \
///     /_.-B-._\  <-- Point on curve
///    ,'   |   ',
///   /     |     \
///  s------C------e  <-- Point on line between s and e
/// ```
/// - s (vector): Curve start
/// - e (vector): Curve end
/// - B (vector): Point on curve
/// - t (float): Position on curve $[0, 1]$
/// - deg (int): Bezier degree (2 or 3)
/// -> array
#let to-abc(s, e, B, t, deg: 2) = {
  let abc-ratio(t) = {
    if t == 0 or t == 1 { return t }
    let bottom = calc.pow(t, deg) + calc.pow(1 - t, deg)
    let top = bottom - 1
    return calc.abs(top / bottom)
  }

  let projection-ratio(t) = {
    if t == 0 or t == 1 { return t }
    let top = calc.pow(1 - t, deg)
    let bottom = calc.pow(t, deg) + top
    return top / bottom
  }

  let u = projection-ratio(t)
  let um = 1 - u

  let C = vector.add(
    vector.scale(s, u),
    vector.scale(e, um))

  let s = abc-ratio(t)
  let A = vector.add(
    B,
    vector.scale(vector.sub(B, C), 1/s))

  return (A, B, C)
}


/// Compute the control points for a quadratic bezier through 3 points.
///
/// - s (vector): Curve start
/// - e (vector): Curve end
/// - B (vector): A point which the curve passes through
/// -> bezier
#let quadratic-through-3points(s, B, e) = {
  let d1 = vector.dist(s, B)
  let d2 = vector.dist(e, B)
  let t = d1 / (d1 + d2)

  let (A, B, C) = to-abc(s, e, B, t, deg: 2)

  return (s, e, A)
}


/// Convert a quadratic bezier to a cubic bezier.
///
/// - s (vector): Curve start
/// - e (vector): Curve end
/// - c (vector): Control point
/// -> bezier
#let quadratic-to-cubic(s, e, c) = {
  let c1 = vector.add(s, vector.scale(vector.sub(c, s), 2/3))
  let c2 = vector.add(e, vector.scale(vector.sub(c, e), 2/3))
  return (s, e, c1, c2)
}

/// Compute the control points for a cubic bezier through 3 points.
///
/// - s (vector): Curve start
/// - e (vector): Curve end
/// - B (vector): A point which the curve passes through
/// -> bezier
#let cubic-through-3points(s, B, e) = {
  if s == B or e == B {
    return (s, e, s, e)
  }

  let d1 = vector.dist(s, B)
  let d2 = vector.dist(e, B)
  let t = d1 / (d1 + d2)

  let (A, _, C) = to-abc(s, e, B, t, deg: 3)

  let angle = vector.angle2(s, e) - vector.angle2(s, B)
  if angle == 0deg or calc.abs(angle) == 180deg {
    let se = vector.dist(s, e)
    let sB = vector.dist(s, B)
    let eB = vector.dist(e, B)

    if sB >= se and sB >= eB {
      return (s, B, s, B)
    } else if eB >= se and eB >= sB {
      return (e, B, e, B)
    }
    return (s, e, s, e)
  }

  let bc = (if angle < 0deg or angle > 180deg { -1 } else { 1 }) * vector.dist(s, e) / 3
  let de1 = t * bc
  let de2 = (1 - t) * bc

  let (ax, ay, az) = A
  let (sx, sy, sz) = s
  let (ex, ey, ez) = e
  let (bx, by, bz) = B

  import "/src/util.typ": calculate-circle-center-3pt
  let (cx, cy, cz) = calculate-circle-center-3pt(s, B, e)
  let tangent = (
    (bx - (by - cy), by + (bx - cx), bz),
    (bx + (by - cy), by - (bx - cx), bz))
  let (dx, dy, dz) = vector.norm(vector.sub(tangent.at(1), tangent.at(0)))

  let (e1x, e1y) = (
    bx + de1 * dx,
    by + de1 * dy)
  let (e2x, e2y) = (
    bx - de2 * dx,
    by - de2 * dy)
  let (v1x, v1y) = (
    ax + (e1x - ax) / (1 - t),
    ay + (e1y - ay) / (1 - t))
  let (v2x, v2y) = (
    ax + (e2x - ax) / t,
    ay + (e2y - ay) / t)
  let c1 = (
    sx + (v1x - sx) / t,
    sy + (v1y - sy) / t)
  let c2 = (
    ex + (v2x - ex) / (1 - t),
    ey + (v2y - ey) / (1 - t))

  return (s, e, c1, c2)
}

/// Split a cubic bezier into two cubic beziers at the point `t`. Returns an <Type>array</Type> of two <Type>bezier</Type>. The first holds the original curve start `s`, and the second holds the original curve end `e`.
///
/// - s  (vector): Curve start
/// - e  (vector): Curve end
/// - c1 (vector): Control point 1
/// - c2 (vector): Control point 2
/// - t  (float): The point on the bezier to split, $[0, 1]$
/// -> array
#let split(s, e, c1, c2, t) = {
  t = calc.max(0, calc.min(t, 1))

  let split-rec(pts, t, left, right) = {
    if pts.len() == 1 {
      left.push(pts.at(0))
      right.push(pts.at(0))
    } else {
      let new-pts = ()
      for i in range(0, pts.len() - 1) {
        if i == 0 {
          left.push(pts.at(i))
        }
        if i == pts.len() - 2 {
          right.push(pts.at(i + 1))
        }
        new-pts.push(vector.add(vector.scale(pts.at(i), (1 - t)),
                                vector.scale(pts.at(i + 1), t)))
      }
      (left, right) = split-rec(new-pts, t, left, right)
    }
    return (left, right)
  }
  let (left, right) = split-rec((s, c1, c2, e), t, (), ())

  return ((left.at(0), left.at(3), left.at(1), left.at(2)),
          (right.at(3), right.at(0), right.at(2), right.at(1)))
}

/// Get the approximate cubic curve length
/// - s  (vector): Curve start
/// - e  (vector): Curve end
/// - c1 (vector): Control point 1
/// - c2 (vector): Control point 2
/// -> float
#let cubic-arclen(s, e, c1, c2, samples: 20) = {
  let d = 0
  for i in range(1, samples + 1) {
    let t0 = (i - 1) / samples
    let t1 = i / samples
    d += vector.dist(
      cubic-point(s, e, c1, c2, t0),
      cubic-point(s, e, c1, c2, t1))
  }
  return d
}

/// Shorten the curve by offsetting s and c1 or e and c2 by distance d. If d is positive the curve gets shortened by moving s and c1 closer to e, if d is negative, e and c2 get moved closer to s.
///
/// - s  (vector): Curve start
/// - e  (vector): Curve end
/// - c1 (vector): Control point 1
/// - c2 (vector): Control point 2
/// - d  (float): Distance to shorten by
/// -> bezier
#let cubic-shorten-linear(s, e, c1, c2, d) = {
  if d == 0 { return (s, e, c1, c2) }

  let t = if d < 0 { 1 } else { 0 }
  let sign = if d < 0 { -1 } else { 1 }

  let a = cubic-point(s, e, c1, c2, t)
  let b = cubic-point(s, e, c1, c2, t + sign * 0.01)
  let offset = vector.scale(vector.norm(vector.sub(b, a)),
    calc.abs(d))
  if d > 0 {
    s = vector.add(s, offset)
    c1 = vector.add(c1, offset)
  } else {
    e = vector.add(e, offset)
    c2 = vector.add(c2, offset)
  }
  return (s, e, c1, c2)
}

/// Approximate bezier interval `t` for a given distance `d`. If `d` is positive, the functions starts from the curve's start `s`, if `d` is negative, it starts form the curve's end `e`.
/// - s  (vector): Curve start
/// - e  (vector): Curve end
/// - c1 (vector): Control point 1
/// - c2 (vector): Control point 2
/// - d  (float): The distance along the bezier to find `t`.
/// -> float
#let cubic-t-for-distance(s, e, c1, c2, d, samples: 20) = {
  let travel-forwards(s, e, c1, c2, d) = {
    let sum = 0
    for n in range(1, samples + 1) {
      let t0 = (n - 1) / samples
      let t1 = n / samples

      let segment-dist = vector.dist(cubic-point(s, e, c1, c2, t0),
                                     cubic-point(s, e, c1, c2, t1))
      if sum <= d and d <= sum + segment-dist {
        let lambda = (d - sum) / segment-dist
        return (1 - lambda) * t0 + lambda * t1
      }
      sum += segment-dist
    }
    return 1
  }

  if d == 0 {
    return 0
  }

  if d > 0 {
    return travel-forwards(s, e, c1, c2, d)
  } else {
    return 1 - travel-forwards(e, s, c2, c1, -d)
  }
}

/// Shorten curve by distance `d`. This keeps the curvature of the curve by finding new values along the original curve. If `d` is positive the curve gets shortened by moving `s` closer to `e`, if `d` is negative, `e` is moved closer to `s`. The points `s` and `e` are moved along the curve, keeping the curve's curvature the same (the control points get recalculated).
///
/// - s  (vector): Curve start
/// - e  (vector): Curve end
/// - c1 (vector): Control point 1
/// - c2 (vector): Control point 2
/// - d  (float): Distance to shorten by
/// - samples (int): Maximum of samples/steps to use
/// -> bezier
#let cubic-shorten(s, e, c1, c2, d, samples: 15) = {
  if d == 0 { return (s, e, c1, c2) }

  let (left, right) = split(s, e, c1, c2, cubic-t-for-distance(s, e, c1, c2, d, samples: samples))
  return if d > 0 {
    right
  } else {
    left
  }
}

/// Find cubic curve extrema by calculating the roots of the curve's first derivative. Returns an <Type>array</Type> of <Type>vector</Type> ordered by distance along the curve from the start to its end.
/// - s (vector): Curve start
/// - e (vector): Curve end
/// - c1 (vector): Control point 1
/// - c2 (vector): Control point 2
/// -> array
#let cubic-extrema(s, e, c1, c2) = {
  let args = (s: s, e: e, c1: c1, c2: c2)
  return call_wasm(cetz-core.cubic_extrema_func, args)
}

/// Returns axis aligned bounding box coordinates `(bottom-left, top-right)` for a cubic bezier curve.
///
/// - s  (vector): Curve start
/// - e  (vector): Curve end
/// - c1 (vector): Control point 1
/// - c2 (vector): Control point 2
/// -> array
#let cubic-aabb(s, e, c1, c2) = {
  return aabb.aabb(cubic-extrema(s, e, c1, c2) + (s, e,)).bounds
}

/// Returns a cubic bezier between points `p2` and `p3` for a catmull-rom curve through all four points.
///
/// - p1 (vector): Point 1
/// - p2 (vector): Point 2
/// - p3 (vector): Point 3
/// - p4 (vector): Point 4
/// - k  (float): The tension of the catmull-rom curve. Must be in the range $[0, 1]$
/// -> bezier
#let _catmull-section-to-cubic(p1, p2, p3, p4, k) = {
  return (p2, p3,
          vector.add(p2, vector.scale(vector.sub(p3, p1), 1/(k * 6))),
          vector.sub(p3, vector.scale(vector.sub(p4, p2), 1/(k * 6))))
}

/// Returns an array of cubic <Type>bezier</Type> for a catmull curve through an array of points.
///
/// - points (array): Array of 2d points
/// - k (float): Strength between 0 and 1
/// - close (bool):
/// -> array
#let catmull-to-cubic(points, k, close: false) = {
  k = calc.max(k, 0.1)
  k = if k < .5 {
    1 / _map(k, .5, 0, 1, 10)
  } else {
    _map(k, .5, 1, 1, 10)
  }

  let len = points.len()
  if len == 2 {
    return ((points.at(0), points.at(1),
             points.at(0), points.at(1)),)
  } else if len > 2 {
    let curves = ()

    let (i0, iN) = if close {
      (-1, 0)
    } else {
      (0, -1)
    }

    curves.push(_catmull-section-to-cubic(points.at(i0), points.at(0),
                                          points.at(1), points.at(2), k))
    for i in range(1, len - 2, step: 1) {
      curves.push(_catmull-section-to-cubic(
        ..range(i - 1, i + 3).map(i => points.at(i)), k))
    }

    curves.push(_catmull-section-to-cubic(
      points.at(-3), points.at(-2), points.at(-1), points.at(iN), k))

    if close {
      curves.push(_catmull-section-to-cubic(
        points.at(-2), points.at(-1), points.at(0), points.at(1), k))
    }

    return curves
  }
  return ()
}

/// Find the roots of a cubic polynomial with the coefficients a, b, c and d.
///
/// -> array Array of roots
#let _cubic-roots(a, b, c, d) = {
  let epsilon = 1e-6
  if calc.abs(a) < epsilon {
    if calc.abs(b) < epsilon {
      // Constant
      if c == 0 {
        return ()
      }

      // Linear
      let root = -1 * d / c
      if root < 0 - epsilon and root > 1 + epsilon {
        return ()
      }
      return (root,)
    }

    // Quadratic
    let dq = calc.pow(c, 2) - 4 * b * d
    if dq >= 0 {
      dq = calc.sqrt(dq)
      let roots = (-1 * (dq + c) / (2 * b),
                        (dq - c) / (2 * b))
      return roots.filter(t => t >= 0 - epsilon and t <= 1 + epsilon)
    } else {
      // No real roots
      return ()
    }
  }

  let (A, B, C) = (b/a, c/a, d/a)
  let Q = (3 * B - calc.pow(A, 2)) / 9
  let R = (9 * A * B - 27 * C - 2 * calc.pow(A, 3)) / 54
  let D = calc.pow(Q, 3) + calc.pow(R, 2)
  let aa = -A / 3

  let sgn = x => { if x < 0 { -1 } else { 1 } }
  let roots = if D >= 0 {
    let S = sgn(R + calc.sqrt(D)) * calc.pow(calc.abs(R + calc.sqrt(D)), 1/3)
    let T = sgn(R - calc.sqrt(D)) * calc.pow(calc.abs(R - calc.sqrt(D)), 1/3)

    if (S - T) != 0 {
      // Roots 2 and 3 are complex
      (aa + (S + T),)
    } else {
      (aa + (S + T), aa - (S + T) / 2)
    }
  } else {
    let th = calc.acos(R / calc.sqrt(-calc.pow(Q, 3))) / 1rad
    let qq = 2 * calc.sqrt(-Q)
    (qq * calc.cos(th / 3) + aa,
     qq * calc.cos((th + 2 * calc.pi) / 3) + aa,
     qq * calc.cos((th + 4 * calc.pi) / 3) + aa)
  }

  return roots.filter(t => t >= 0 - epsilon and t <= 1 + epsilon)
}

/// Calculate the intersection points between a 2D cubic-bezier and a straight line. Returns an array of <Type>vector</Type>
///
/// - s   (vector): Bezier start point
/// - e   (vector): Bezier end point
/// - c1  (vector): Bezier control point 1
/// - c2  (vector): Bezier control point 2
/// - la  (vector): Line start point
/// - lb  (vector): Line end point
/// - ray (bool): If set to true, ignore line length
/// -> array
#let line-cubic-intersections(la, lb, s, e, c1, c2, ray: false) = {
  // Based on:
  //   http://www.particleincell.com/blog/2013/cubic-line-intersection/
  // with some rounding improvements
  let a = lb.at(1) - la.at(1)
  let b = la.at(0) - lb.at(0)
  let c = la.at(0) * (la.at(1) - lb.at(1)) + la.at(1) * (lb.at(0) - la.at(0))

  /// Get cubic bezier function coefficients
  let _cubic-coeff(a, b, c, d) = (
    -a + 3*b - 3*c + d,
    3*a - 6*b + 3*c,
    -3*a +3*b,
    a)

  let x-coeff = _cubic-coeff(s.at(0), c1.at(0), c2.at(0), e.at(0))
  let y-coeff = _cubic-coeff(s.at(1), c1.at(1), c2.at(1), e.at(1))

  let roots = _cubic-roots(a * x-coeff.at(0) + b * y-coeff.at(0),
                           a * x-coeff.at(1) + b * y-coeff.at(1),
                           a * x-coeff.at(2) + b * y-coeff.at(2),
                           a * x-coeff.at(3) + b * y-coeff.at(3) + c)

  let pts = ()
  for t in roots {
    let pt = cubic-point(s, e, c1, c2, t)
    if ray {
      pts.push(pt)
    } else {
      let s = if calc.abs(lb.at(0) - la.at(0)) >= 1e-6 {
        (pt.at(0) - la.at(0)) / (lb.at(0) - la.at(0))
      } else {
        (pt.at(1) - la.at(1)) / (lb.at(1) - la.at(1))
      }
      if s >= 0 and s <= 1 {
        pts.push(pt)
      }
    }
  }
  return pts
}
