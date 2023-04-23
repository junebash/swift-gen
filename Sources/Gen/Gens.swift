public enum Gens {}



extension Gens {
  public struct EitherGenerator<
    A: Gen,
    B: Gen,
    ACount: Gen<Int>,
    BCount: Gen<Int>
  >: Gen {
    @inlinable internal init(aCount: ACount, bCount: BCount, a: A, b: B) {
      self.aCount = aCount
      self.bCount = bCount
      self.a = a
      self.b = b
    }

    public let aCount: ACount
    public let bCount: BCount
    public let a: A
    public let b: B

    @inlinable
    public func run<RNG>(using rng: inout RNG) -> Either<A.Value, B.Value>
    where RNG : RandomNumberGenerator {
      let actualADist = aCount.run(using: &rng)
      let actualBDist = bCount.run(using: &rng)
      let distTotal = actualADist + actualBDist
      let aRange = 0..<actualADist
      let bRange = actualADist..<distTotal
      let index = Int.random(in: 0..<distTotal, using: &rng)
      switch index {
      case aRange:
        return .left(a.run(using: &rng))
      case bRange:
        return .right(b.run(using: &rng))
      default:
        preconditionFailure()
      }
    }
  }
}

extension Gens.EitherGenerator: Sendable
where ACount: Sendable, BCount: Sendable, A: Sendable, B: Sendable {}

extension Either {
  @inlinable
  public static func generator<
    LeftGen: Gen<Left>,
    RightGen: Gen<Right>,
    LeftCount: Gen<Int>,
    RightCount: Gen<Int>
  >(
    left: LeftGen,
    right: RightGen,
    leftDistribution: LeftCount = Always(2),
    rightDistribution: RightCount = Always(2)
  ) -> Gens.EitherGenerator<LeftGen, RightGen, LeftCount, RightCount> {
    .init(aCount: leftDistribution, bCount: rightDistribution, a: left, b: right)
  }
}

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

  /// Produces a new generator of optional values.
  ///
  /// - Returns: A generator of optional values.
  @inlinable
  public func `optional`<Some: Gen<Int>, None: Gen<Int>>(
    some someDistribution: Some = Always(3),
    none noneDistribution: None = Always(1)
  ) -> Gens.Map<Gens.EitherGenerator<Self, Always<()>, Some, None>, Self.Value?> {
    Gens.EitherGenerator(
      aCount: someDistribution,
      bCount: noneDistribution,
      a: self,
      b: Always(())
    ).map {
      switch $0 {
      case .left(let value): return Value?.some(value)
      case .right: return nil
      }
    }
  }

  /// Produces a new generator of failable values.
  ///
  /// - Returns: A generator of failable values.
  @inlinable
  public func asResult<
    Failure: Gen,
    SuccessCount: Gen<Int>,
    FailureCount: Gen<Int>
  >(
    withFailure failure: Failure,
    successDistribution: SuccessCount = Always(3),
    failureDistribution: FailureCount = Always(1)
  ) -> Gens.Map<
    Gens.EitherGenerator<Self, Failure, SuccessCount, FailureCount>,
    Result<Self.Value, Failure.Value>
  > {
    Gens.EitherGenerator(
      aCount: successDistribution,
      bCount: failureDistribution,
      a: self,
      b: failure
    ).map(\.asResult)
  }
}

extension Gen where Value: Hashable {
  public func set<Count: Gen<Int>>(
    ofAtMost count: Count
  ) -> Reduce<Self, Always<Set<Value>>, Count> {
    self.reduce(count: count, into: { Set(minimumCapacity: $0) }, { $0.insert($1) })
  }
}

extension UnicodeScalar {
  @inlinable
  public static func generator(
    inNumericRange range: ClosedRange<UInt32>
  ) -> Gens.Compact<Gens.Map<Gens.Integer<UInt32>, UnicodeScalar?>, UnicodeScalar> {
    UInt32.generator(in: range)
      .compactMap { UnicodeScalar($0) }
  }

  @inlinable
  public static func generator(
    in range: ClosedRange<UnicodeScalar>
  ) -> Gens.Compact<Gens.Map<Gens.Integer<UInt32>, UnicodeScalar?>, UnicodeScalar> {
    UnicodeScalar.generator(inNumericRange: range.lowerBound.value...range.upperBound.value)
  }
}

extension Character {
  @inlinable
  public static func generator(
    in range: ClosedRange<Character>
  ) -> Gens.Map<
    Gens.Compact<Gens.Map<Gens.Integer<UInt32>, UnicodeScalar?>, UnicodeScalar>,
    Character
  > {
    UnicodeScalar.generator(
      in: range.lowerBound.unicodeScalars.first!...range.upperBound.unicodeScalars.last!
    )
    .map { Character($0) }
  }

  public static func generator(
    in string: String
  ) -> Gens.Compact<ElementOf<[Character]>, Character> {
    ElementOf([Character](string)).compact()
  }
}

private extension String {
  static let _numbers = "0123456789"
  static let _lowerLetters = "abcdefghijklmnopqrstuvwxyz"
  static let _upperLetters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
}

extension Gens {
  public static let number = Character.generator(in: ._numbers)
  public static let uppercaseLetter = Character.generator(in: ._upperLetters)
  public static let lowercaseLetter = Character.generator(in: ._lowerLetters)
  public static let letter = Character.generator(in: ._upperLetters + ._lowerLetters)
  public static let letterOrNumber = Character
    .generator(in: ._lowerLetters + ._upperLetters + ._numbers)

  public static let ascii = UnicodeScalar.generator(inNumericRange: 0...127)
  public static let latin1 = UnicodeScalar.generator(inNumericRange: 0...255)
}

extension Gen where Value == Character {
  @inlinable
  public func string<Count: Gen<Int>>(
    of count: Count
  ) -> Reduce<Self, Always<String>, Count> {
    self.reduce(count: count, into: { String(reservingCapacity: $0) }) { $0.append($1) }
  }
}

extension Gens {
  public struct Traverse<Input: Sequence, NewElement>: Gen
  where Input.Element: Gen {
    public let input: Input
    public let transform: @Sendable (Input.Element.Value) -> NewElement

    @inlinable
    init(input: Input, transform: @escaping @Sendable (Input.Element.Value) -> NewElement) {
      self.input = input
      self.transform = transform
    }

    @inlinable
    public func run<RNG>(using rng: inout RNG) -> [NewElement] where RNG : RandomNumberGenerator {
      input.map { transform($0.run(using: &rng)) }
    }
  }
}

extension Gens.Traverse: Sendable where Input: Sendable {}

extension Sequence where Element: Gen {
  /// Transforms each value of an array of generators before rewrapping the array in an array generator.
  ///
  /// - Parameter transform: A transform function to apply to the value of each generator.
  /// - Returns: A generator of arrays.
  @inlinable
  public func traverse<NewElement>(
    _ transform: @escaping @Sendable (Element.Value) -> NewElement
  ) -> Gens.Traverse<Self, NewElement> {
    .init(input: self, transform: transform)
  }

  /// Transforms an array of generators into a generator of arrays.
  ///
  /// - Returns: A generator of arrays.
  @inlinable
  public func traverse() -> Gens.Traverse<Self, Element.Value> {
    self.traverse { $0 }
  }
}

extension Gen where Self: Sendable {
  public func eraseToAnyGen() -> AnyGen<Value> {
    AnyGen(self)
  }
}
