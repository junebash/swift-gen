import Gen
import XCTest

final class GenPerformanceTests: XCTestCase {
    @available(macOS 13.0, *)
    func testPerformance() {
        let anyGen = Gen.bool
            .flatMap { $0 ? .letter : .number }
            .string(of: Gen.int(in: 10...20))
            .array(of: Gen.int(in: 5...10))
            .map { $0.joined(separator: " ") }
        let protoGen = Bool.Generator()
            .flatMap { $0 ? Gens.letter : Gens.number }
            .string(of: Int.generator(in: 10...20))
            .array(of: Int.generator(in: 5...10))
            .map { $0.joined(separator: " ") }

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
