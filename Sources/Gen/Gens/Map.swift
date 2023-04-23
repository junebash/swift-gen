extension Gens {
  public struct Map<Upstream: Gen, Value>: Gen {
    public let upstream: Upstream
    public let transform: @Sendable (Upstream.Value) -> Value

    @inlinable
    init(upstream: Upstream, transform: @escaping @Sendable (Upstream.Value) -> Value) {
      self.upstream = upstream
      self.transform = transform
    }

    @inlinable
    public func run<RNG>(using rng: inout RNG) -> Value where RNG : RandomNumberGenerator {
      transform(upstream.run(using: &rng))
    }
  }
}

extension Gens.Map: Sendable where Upstream: Sendable {}

extension Gen {
  /// Transforms a generator of `Value`s into a generator of `NewValue`s by applying a transformation.
  ///
  /// - Parameter transform: A function that transforms `Value`s into `NewValue`s.
  /// - Returns: A generator of `NewValue`s.
  @inlinable
  public func map<NewValue>(
    _ transform: @escaping @Sendable (Value) -> NewValue
  ) -> Gens.Map<Self, NewValue> {
    .init(upstream: self, transform: transform)
  }
}
