/// A composable, transformable context for generating random values.
public protocol Gen<Value> {
  associatedtype Value
  associatedtype _Body

  typealias Body = _Body

  var body: _Body { get }

  func run<RNG: RandomNumberGenerator>(using rng: inout RNG) -> Value
}

extension Gen where _Body == Never {
  /// A non-existent body.
  ///
  /// > Warning: Do not invoke this property directly. It will trigger a fatal error at runtime.
  @_transparent
  public var body: Never {
    fatalError("""
      '\(Self.self)' has no body. …

      Do not access a generator's `body` property directly, as it may not exist. To run a generator, \
      call 'Gen.run', instead.
      """
    )
  }
}

extension Gen where Body: Gen, Body.Value == Value {
  @inlinable
  public func run<RNG: RandomNumberGenerator>(using rng: inout RNG) -> Value {
    body.run(using: &rng)
  }
}

extension Gen {
  @inlinable
  public func run() -> Value {
    var srng = SystemRandomNumberGenerator()
    return self.run(using: &srng)
  }
}
