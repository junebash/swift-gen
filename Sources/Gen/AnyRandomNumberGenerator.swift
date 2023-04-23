/// A type-erased random number generator.
///
/// The `AnyRandomNumberGenerator` type forwards random number generating operations to an underlying random number generator, hiding its specific underlying type.
public struct AnyRandomNumberGenerator: RandomNumberGenerator {
  @usableFromInline
  internal var _rng: any RandomNumberGenerator

  /// - Parameter rng: A random number generator.
  @inlinable
  public init(_ rng: some RandomNumberGenerator) {
    self._rng = rng
  }

  @inlinable
  public init(next: @escaping () -> UInt64) {
    self._rng = AnonymousRNG(next: next)
  }

  @inlinable
  public mutating func next() -> UInt64 {
    return self._rng.next()
  }
}

extension AnyRandomNumberGenerator {
  @usableFromInline
  internal struct AnonymousRNG: RandomNumberGenerator {
    @usableFromInline
    var _next: () -> UInt64

    @inlinable
    internal init(next: @escaping () -> UInt64) {
      self._next = next
    }

    @inlinable
    func next() -> UInt64 {
      _next()
    }
  }
}
