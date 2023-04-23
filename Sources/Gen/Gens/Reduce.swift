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

extension Gen {
  @inlinable
  public func reduce<Count: Gen, InitialValue: Gen>(
    count: Count,
    into initialValue: @escaping @Sendable (Count.Value) -> InitialValue,
    _ accumulate: @escaping @Sendable (inout InitialValue.Value, Value) -> Void
  ) -> Reduce<Self, InitialValue, Count> {
    .init(upstream: self, count: count, initialValue: initialValue, accumulate: accumulate)
  }

  @inlinable
  public func reduce<Count: Gen, NewValue>(
    count: Count,
    into initialValue: @escaping @Sendable (Count.Value) -> NewValue,
    _ accumulate: @escaping @Sendable (inout NewValue, Value) -> Void
  ) -> Reduce<Self, Always<NewValue>, Count> {
    .init(
      upstream: self,
      count: count,
      initialValue: { Always(initialValue($0)) },
      accumulate: accumulate
    )
  }

  @inlinable
  public func reduce<Count: Gen, InitialValue: Gen>(
    count: Count,
    into initialValue: @escaping @Sendable @autoclosure () -> InitialValue,
    _ accumulate: @escaping @Sendable (inout InitialValue.Value, Value) -> Void
  ) -> Reduce<Self, InitialValue, Count> {
    .init(upstream: self, count: count, initialValue: { _ in initialValue() }, accumulate: accumulate)
  }

  @inlinable
  public func reduce<Count: Gen, InitialValue>(
    count: Count,
    into initialValue: @escaping @Sendable @autoclosure () -> InitialValue,
    _ accumulate: @escaping @Sendable (inout InitialValue, Value) -> Void
  ) -> Reduce<Self, Always<InitialValue>, Count> {
    .init(upstream: self, count: count, initialValue: { _ in Always(initialValue()) }, accumulate: accumulate)
  }
}

extension Gen {
  @inlinable
  public func array<Count: Gen<Int>>(
    of count: Count
  ) -> Reduce<Self, Always<[Self.Value]>, Count> {
    self.reduce(count: count, into: { Array(reservingCapacity: $0) }) { output, item in
      output.append(item)
    }
  }

  @inlinable
  public func dictionary<K: Hashable, V, Count: Gen<Int>>(
    ofAtMost count: Count
  ) -> Reduce<Self, Always<Dictionary<K, V>>, Count>
  where Value == (K, V) {
    self.reduce(count: count, into: {
      var d = Dictionary<K, V>()
      d.reserveCapacity($0)
      return d
    }) { output, pair in
      output[pair.0] = pair.1
    }
  }
}

extension Gen where Value: Hashable {
  public func set<Count: Gen<Int>>(
    ofAtMost count: Count
  ) -> Reduce<Self, Always<Set<Value>>, Count> {
    self.reduce(count: count, into: { Set(minimumCapacity: $0) }, { $0.insert($1) })
  }
}
