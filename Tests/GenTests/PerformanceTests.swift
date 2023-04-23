import Gen
import XCTest

@available(macOS 13.0, *)
@available(iOS 16.0, *)
@available(*, unavailable)
final class GenPerformanceTests: XCTestCase {
  func testPerformance() {
    let anyGen = AnyGen.bool
      .flatMap { $0 ? .letter : .number }
      .string(of: AnyGen.int(in: 10...20))
      .array(of: AnyGen.int(in: 5...10))
      .map { $0.joined(separator: " ") }
      .map { $0 }
      .flatMap { Always($0) }
      .map { $0 }
    let protoGen = Bool.Generator()
      .flatMap { $0 ? Gens.letter : Gens.number }
      .string(of: Int.generator(in: 10...20))
      .array(of: Int.generator(in: 5...10))
      .map { $0.joined(separator: " ") }
      .map { $0 }
      .flatMap { Always($0) }
      .map { $0 }

    let clock = SuspendingClock()
    let repeatCount = 10_000

    var rng = Xoshiro(seed: 20)

    let anyTime = clock.measure {
      for _ in 1...repeatCount {
        _ = anyGen.run(using: &rng)
      }
    }
    let protoTime = clock.measure {
      for _ in 1...repeatCount {
        _ = protoGen.run(using: &rng)
      }
    }

    print("Legacy time:", anyTime)
    print("Protocol time:", protoTime)
  }
}
