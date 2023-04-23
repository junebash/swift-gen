extension Gens {
  public struct FlatMap<Upstream: Gen, NewValue: Gen>: Gen {
    @inlinable internal init(
      upstream: Upstream,
      transform: @escaping @Sendable (Upstream.Value) -> NewValue
    ) {
      self.upstream = upstream
      self.transform = transform
    }

    public let upstream: Upstream
    public let transform: @Sendable (Upstream.Value) -> NewValue

    @inlinable
    public func run<RNG>(using rng: inout RNG) -> NewValue.Value where RNG : RandomNumberGenerator {
      transform(upstream.run(using: &rng)).run(using: &rng)
    }
  }
}

extension Gens.FlatMap: Sendable where Upstream: Sendable {}

extension Gen {
  /// Transforms a generator of `Value`s into a generator of `NewValue`s by transforming a value into a generator of `NewValue`s.
  ///
  /// - Parameter transform: A function that transforms `Value`s into a generator of `NewValue`s.
  /// - Returns: A generator of `NewValue`s.
  @inlinable public func flatMap<NewGen: Gen>(
    _ transform: @escaping @Sendable (Value) -> NewGen
  ) -> Gens.FlatMap<Self, NewGen> {
    .init(upstream: self, transform: transform)
  }
}
