public struct Reduce<
  Upstream: Gen,
  InitialValue: Gen,
  Count: Gen<Int>
>: Gen where Count.Value: FixedWidthInteger {
  public typealias Value = InitialValue.Value

  @inlinable
  internal init(
    upstream: Upstream,
    count: Count,
    initialValue: @escaping @Sendable (Int) -> InitialValue,
    accumulate: @escaping @Sendable (inout InitialValue.Value, Upstream.Value) -> Void
  ) {
    self.upstream = upstream
    self.count = count
    self.initialValue = initialValue
    self.accumulate = accumulate
  }

  @inlinable
  public init(
    each: Upstream,
    count: Count,
    into initialValue: @escaping @Sendable (Int) -> InitialValue,
    _ accumulate: @escaping @Sendable (inout InitialValue.Value, Upstream.Value) -> Void
  ) {
    self.init(upstream: each, count: count, initialValue: initialValue, accumulate: accumulate)
  }

  public let upstream: Upstream
  public let count: Count
  public let initialValue: @Sendable (Int) -> InitialValue
  public let accumulate: @Sendable (inout InitialValue.Value, Upstream.Value) -> Void

  @inlinable public func run<RNG>(using rng: inout RNG) -> Value
  where RNG : RandomNumberGenerator {
    let actualCount = self.count.run(using: &rng)
    var output = initialValue(actualCount).run(using: &rng)
    for _ in 0..<actualCount {
      accumulate(&output, upstream.run(using: &rng))
    }
    return output
  }
}

extension Reduce: Sendable where Upstream: Sendable, InitialValue: Sendable, Count: Sendable {}
