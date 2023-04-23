import Gen
import UIKit

// We want to create a random art generator that creates UIImages.
// ⚠️ Run this playground with the live view open. ⚠️

let canvas = CGRect(x: 0, y: 0, width: 600, height: 600)
let mainArea = canvas.insetBy(dx: 130, dy: 100)
let numLines = 60
let numPointsPerLine = 60
let dx = mainArea.width / CGFloat(numPointsPerLine)
let dy = mainArea.height / CGFloat(numLines)

struct BumpGenerator {
  let amplitude: CGFloat
  let center: CGFloat
  let plateauSize: CGFloat
  let curveSize: CGFloat

  // A nice smooth curve that starts at zero and trends towards 1 asymptotically
  func f(_ x: CGFloat) -> CGFloat {
    if x <= 0 { return 0 }
    return exp(-1 / x)
  }

  // A nice smooth curve that starts at zero and curves up to 1 on the unit interval.
  func g(_ x: CGFloat) -> CGFloat {
    return f(x) / (f(x) + f(1 - x))
  }

  func bump(_ x: CGFloat) -> CGFloat {
    let plateauSize = plateauSize / 2
    let curveSize = curveSize / 2
    let size = plateauSize + curveSize
    let x = x - center
    return amplitude * (1 - g((x * x - plateauSize * plateauSize) / (size * size - plateauSize * plateauSize)))
  }

  func noisyBump(_ x: CGFloat) -> some Gen<CGFloat> {
    let y = self.bump(x)
    return CGFloat.generator(in: 0...3).map { $0 * (y / amplitude + 0.5) + y }
  }
}

//let curve = zip(
//  Gen<CGFloat>.float(in: -30...(-1)),
//  Gen<CGFloat>.float(in: -60...60)
//    .map { $0 + canvas.width / 2 },
//  Gen<CGFloat>.float(in: 0...60),
//  Gen<CGFloat>.float(in: 10...60)
//  )
//  .map(noisyBump(amplitude:center:plateauSize:curveSize:))
let curve = zip(
  CGFloat.generator(in: -30 ... -1),
  CGFloat.generator(in: -60 ... 60)
    .map { $0 + canvas.width * 0.5 },
  CGFloat.generator(in: 0...60),
  CGFloat.generator(in: 10...60)
).map { BumpGenerator(amplitude: $0, center: $1, plateauSize: $2, curveSize: $3) }

struct PathGenerator: Gen {
  typealias Value = CGPath

  let min: CGFloat
  let max: CGFloat
  let baseline: CGFloat

  let bumps: some Gen<[BumpGenerator]> = curve.array(of: Int.generator(in: 1...4))

  func run<RNG>(using rng: inout RNG) -> CGPath
  where RNG: RandomNumberGenerator {
    let bumps = self.bumps.run(using: &rng)
    let path = CGMutablePath()
    path.move(to: CGPoint(x: min, y: baseline))
    stride(from: min, to: max, by: dx).forEach { x in
      let ys = bumps.map { $0.noisyBump(x).run(using: &rng) }
      let average = ys.reduce(0, +) / CGFloat(ys.count)
      path.addLine(to: CGPoint(x: x, y: baseline + average))
    }
    path.addLine(to: CGPoint.init(x: max, y: baseline))
    return path
  }
}

let paths = stride(from: mainArea.minY, to: mainArea.maxY, by: dy)
  .map { PathGenerator(min: mainArea.minX, max: mainArea.maxX, baseline: $0) }
  .traverse()

let colors = [
  UIColor(red: 0.47, green: 0.95, blue: 0.69, alpha: 1),
  UIColor(red: 1, green: 0.94, blue: 0.5, alpha: 1),
  UIColor(red: 0.3, green: 0.80, blue: 1, alpha: 1),
  UIColor(red: 0.59, green: 0.30, blue: 1, alpha: 1)
]

let image = paths.map { paths in
  UIGraphicsImageRenderer(bounds: canvas).image { ctx in
    let ctx = ctx.cgContext

    ctx.setFillColor(UIColor.black.cgColor)
    ctx.fill(canvas)

    paths.enumerated().forEach { idx, path in
      ctx.setStrokeColor(
        colors[colors.count * idx / paths.count].cgColor
      )
      ctx.addPath(path)
      ctx.drawPath(using: .fillStroke)
    }
  }
}

let imageView = image.map { UIImageView(image: $0) }

import PlaygroundSupport
PlaygroundPage.current.liveView = imageView.run()
