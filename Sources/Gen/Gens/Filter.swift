extension Gens {
  public struct Filter<Upstream: Gen>: Gen {
    @inlinable internal init(
      upstream: Upstream,
      predicate: @escaping @Sendable (Upstream.Value) -> Bool
    ) {
      self.upstream = upstream
      self.predicate = predicate
    }

    public let upstream: Upstream
    public let predicate: @Sendable (Upstream.Value) -> Bool

    @inlinable public func run<RNG>(using rng: inout RNG) -> Upstream.Value where RNG : RandomNumberGenerator {
      while true {
        let value = upstream.run(using: &rng)
        if predicate(value) {
          return value
        }
      }
    }
  }
}

extension Gens.Filter: Sendable where Upstream: Sendable {}

extension Gen {
  /// Produces a generator of values that match the predicate.
  ///
  /// - Parameter predicate: A predicate.
  /// - Returns: A generator of values that match the predicate.
  @inlinable
  public func filter(_ predicate: @escaping @Sendable (Value) -> Bool) -> Gens.Filter<Self> {
    .init(upstream: self, predicate: predicate)
  }
}
