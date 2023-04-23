extension Gens {
  public struct EitherGenerator<
    A: Gen,
    B: Gen,
    ACount: Gen<Int>,
    BCount: Gen<Int>
  >: Gen {
    @inlinable internal init(aCount: ACount, bCount: BCount, a: A, b: B) {
      self.aCount = aCount
      self.bCount = bCount
      self.a = a
      self.b = b
    }

    public let aCount: ACount
    public let bCount: BCount
    public let a: A
    public let b: B

    @inlinable
    public func run<RNG>(using rng: inout RNG) -> Either<A.Value, B.Value>
    where RNG : RandomNumberGenerator {
      let actualADist = aCount.run(using: &rng)
      let actualBDist = bCount.run(using: &rng)
      let distTotal = actualADist + actualBDist
      let aRange = 0..<actualADist
      let bRange = actualADist..<distTotal
      let index = Int.random(in: 0..<distTotal, using: &rng)
      switch index {
      case aRange:
        return .left(a.run(using: &rng))
      case bRange:
        return .right(b.run(using: &rng))
      default:
        preconditionFailure()
      }
    }
  }
}

extension Gens.EitherGenerator: Sendable
where ACount: Sendable, BCount: Sendable, A: Sendable, B: Sendable {}

extension Either {
  @inlinable
  public static func generator<
    LeftGen: Gen<Left>,
    RightGen: Gen<Right>,
    LeftCount: Gen<Int>,
    RightCount: Gen<Int>
  >(
    left: LeftGen,
    right: RightGen,
    leftDistribution: LeftCount = Always(2),
    rightDistribution: RightCount = Always(2)
  ) -> Gens.EitherGenerator<LeftGen, RightGen, LeftCount, RightCount> {
    .init(aCount: leftDistribution, bCount: rightDistribution, a: left, b: right)
  }
}

extension Gen {
  /// Produces a new generator of optional values.
  ///
  /// - Returns: A generator of optional values.
  @inlinable
  public func `optional`<Some: Gen<Int>, None: Gen<Int>>(
    some someDistribution: Some = Always(3),
    none noneDistribution: None = Always(1)
  ) -> Gens.Map<Gens.EitherGenerator<Self, Always<()>, Some, None>, Self.Value?> {
    Gens.EitherGenerator(
      aCount: someDistribution,
      bCount: noneDistribution,
      a: self,
      b: Always(())
    ).map {
      switch $0 {
      case .left(let value): return Value?.some(value)
      case .right: return nil
      }
    }
  }

  /// Produces a new generator of failable values.
  ///
  /// - Returns: A generator of failable values.
  @inlinable
  public func asResult<
    Failure: Gen,
    SuccessCount: Gen<Int>,
    FailureCount: Gen<Int>
  >(
    withFailure failure: Failure,
    successDistribution: SuccessCount = Always(3),
    failureDistribution: FailureCount = Always(1)
  ) -> Gens.Map<
    Gens.EitherGenerator<Self, Failure, SuccessCount, FailureCount>,
    Result<Self.Value, Failure.Value>
  > {
    Gens.EitherGenerator(
      aCount: successDistribution,
      bCount: failureDistribution,
      a: self,
      b: failure
    ).map(\.asResult)
  }
}
