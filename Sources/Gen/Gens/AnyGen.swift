/// A composable, transformable context for generating random values.
public struct AnyGen<Value>: Gen, Sendable {
  @usableFromInline
  internal var _run: @Sendable (inout any RandomNumberGenerator) -> Value

  @inlinable
  public init(run: @escaping @Sendable (inout any RandomNumberGenerator) -> Value) {
    self._run = run
  }

  @inlinable
  public init<G: Gen<Value>>(_ gen: G) {
    self._run = { gen.run(using: &$0) }
  }

  /// Returns a random value.
  ///
  /// - Parameter rng: A random number generator.
  /// - Returns: A random value.
  @inlinable
  public func run<G: RandomNumberGenerator>(using rng: inout G) -> Value {
    var anyRNG: any RandomNumberGenerator = rng
    defer { rng = anyRNG as! G }
    return self._run(&anyRNG)
  }
}
