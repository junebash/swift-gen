extension FixedWidthInteger {
  /// Returns a generator of random values within the specified range.
  ///
  /// - Parameter range: The range in which to create a random value. `range` must be finite.
  /// - Returns: A generator of random values within the bounds of range.
  @inlinable
  public static func generator(in range: ClosedRange<Self>) -> Gens.Integer<Self> {
    .init(range: range)
  }
}

extension BinaryFloatingPoint where RawSignificand: FixedWidthInteger {
  /// Returns a generator of random values within the specified range.
  ///
  /// - Parameter range: The range in which to create a random value. `range` must be finite.
  /// - Returns: A generator of random values within the bounds of range.
  @inlinable
  public static func generator(in range: ClosedRange<Self>) -> Gens.Float<Self> {
    .init(range: range)
  }
}

extension Gens {
  public struct Integer<Value: FixedWidthInteger>: Gen {
    @inlinable
    internal init(range: ClosedRange<Value>) {
      self.range = range
    }

    public let range: ClosedRange<Value>

    @inlinable
    public func run<RNG>(using rng: inout RNG) -> Value where RNG : RandomNumberGenerator {
      Value.random(in: range, using: &rng)
    }
  }

  public struct Float<Value: BinaryFloatingPoint>: Gen
  where Value.RawSignificand: FixedWidthInteger {
    @inlinable internal init(range: ClosedRange<Value>) {
      self.range = range
    }

    public let range: ClosedRange<Value>

    @inlinable
    public func run<RNG>(using rng: inout RNG) -> Value where RNG : RandomNumberGenerator {
      Value.random(in: range, using: &rng)
    }
  }
}

extension Gens.Integer: Sendable where Value: Sendable {}
extension Gens.Float: Sendable where Value: Sendable {}
