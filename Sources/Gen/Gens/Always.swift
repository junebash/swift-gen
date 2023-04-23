/// Produces a generator that always returns the same, constant value.
///
/// - Parameter value: A constant value.
/// - Returns: A generator of a constant value.
public struct Always<Value>: Gen, Sendable {
  public let value: @Sendable () -> Value

  @inlinable
  public init(_ value: @escaping @Sendable @autoclosure () -> Value) {
    self.value = value
  }

  @inlinable
  public init(_ value: @escaping @Sendable () -> Value) {
    self.value = value
  }

  @inlinable
  public func run<RNG>(using rng: inout RNG) -> Value where RNG : RandomNumberGenerator {
    value()
  }
}
