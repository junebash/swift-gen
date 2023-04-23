extension Gens {
  public struct Compact<Upstream: Gen, Value>: Gen
  where Upstream.Value == Value? {
    @inlinable internal init(upstream: Upstream) {
      self.upstream = upstream
    }

    public let upstream: Upstream

    @inlinable public func run<RNG>(using rng: inout RNG) -> Value where RNG : RandomNumberGenerator {
      while true {
        if let value = upstream.run(using: &rng) {
          return value
        }
      }
    }
  }
}

extension Gens.Compact: Sendable where Upstream: Sendable {}

extension Gen {
  /// Returns a generator of the non-nil results of the given generator.
  @inlinable public func compact<Wrapped>() -> Gens.Compact<Self, Wrapped> where Value == Wrapped? {
    .init(upstream: self)
  }

  /// Returns a generator of the non-nil results of calling the given transformation with a value of the generator.
  ///
  /// - Parameter transform: A closure that accepts an element of this sequence as its argument and returns an optional value.
  /// - Returns: A generator of the non-nil results of calling the given transformation with a value of the generator.
  @inlinable public func compactMap<NewValue>(
    _ transform: @escaping @Sendable (Value) -> NewValue?
  ) -> Gens.Compact<Gens.Map<Self, NewValue?>, NewValue> {
    self.map(transform).compact()
  }
}
