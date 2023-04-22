public protocol Gen<Value> {
    associatedtype Value

    func run<RNG: RandomNumberGenerator>(using rng: inout RNG) -> Value
}

extension Gen {
    @inlinable
    public func run() -> Value {
        var srng = SystemRandomNumberGenerator()
        return self.run(using: &srng)
    }
}

/// Produces a generator that always returns the same, constant value.
///
/// - Parameter value: A constant value.
/// - Returns: A generator of a constant value.
public struct Always<Value>: Gen {
    public let value: Value

    @inlinable
    public init(_ value: Value) {
        self.value = value
    }

    @inlinable
    public func run<RNG>(using rng: inout RNG) -> Value where RNG : RandomNumberGenerator {
        value
    }
}

public enum Gens {}

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

extension Gens {
    public struct Zip2<A: Gen, B: Gen>: Gen {
        public let a: A
        public let b: B

        @inlinable internal init(a: A, b: B) {
            self.a = a
            self.b = b
        }

        @inlinable
        public func run<RNG>(using rng: inout RNG) -> (A.Value, B.Value) where RNG : RandomNumberGenerator {
            (a.run(using: &rng), b.run(using: &rng))
        }
    }
}

extension Gens.Zip2: Sendable where A: Sendable, B: Sendable {}

/// Combines two generators into a single one.
///
/// - Parameters:
///   - a: A generator of `A`s.
///   - b: A generator of `B`s.
/// - Returns: A generator of `(A, B)` pairs.
@inlinable
public func zip<A: Gen, B: Gen>(_ a: A, _ b: B) -> Gens.Zip2<A, B> {
    .init(a: a, b: b)
}

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

extension Gens {
    public struct Filter<Upstream: Gen>: Gen {
        @inlinable internal init(
            upstream: Upstream,
            predicate: @escaping @Sendable (Upstream.Value) -> Bool
        ) {
            self.upstream = upstream
            self.predicate = predicate
        }

        public let upstream: Upstream
        public let predicate: @Sendable (Upstream.Value) -> Bool

        @inlinable public func run<RNG>(using rng: inout RNG) -> Upstream.Value where RNG : RandomNumberGenerator {
            while true {
                let value = upstream.run(using: &rng)
                if predicate(value) {
                    return value
                }
            }
        }
    }
}

extension Gens.Filter: Sendable where Upstream: Sendable {}

extension Gen {
    /// Produces a generator of values that match the predicate.
    ///
    /// - Parameter predicate: A predicate.
    /// - Returns: A generator of values that match the predicate.
    @inlinable
    public func filter(_ predicate: @escaping @Sendable (Value) -> Bool) -> Gens.Filter<Self> {
        .init(upstream: self, predicate: predicate)
    }
}

/// Uses a weighted distribution to randomly select one of the generators in the list.
public struct Frequency<Upstream: Gen>: Gen {
    public let generators: [Upstream]

    /// Uses a weighted distribution to randomly select one of the generators in the list.
    @inlinable
    public init?(_ distribution: some Sequence<(Int, Upstream)>) {
        self.generators = distribution.flatMap { repeatElement($1, count: $0) }
        guard !generators.isEmpty else { return nil }
    }

    /// Uses a weighted distribution to randomly select one of the generators in the list.
    @inlinable
    public init?(_ distribution: (Int, Upstream)...) {
        self.init(distribution)
    }

    @inlinable
    public func run<RNG>(using rng: inout RNG) -> Upstream.Value where RNG : RandomNumberGenerator {
        generators.randomElement(using: &rng)!.run(using: &rng)
    }
}

extension FixedWidthInteger {
    /// Returns a generator of random values within the specified range.
    ///
    /// - Parameter range: The range in which to create a random value. `range` must be finite.
    /// - Returns: A generator of random values within the bounds of range.
    @inlinable
    public static func generator(in range: ClosedRange<Self>) -> Gens.Integer<Self> {
        .init(range: range)
    }
}

extension BinaryFloatingPoint where RawSignificand: FixedWidthInteger {
    /// Returns a generator of random values within the specified range.
    ///
    /// - Parameter range: The range in which to create a random value. `range` must be finite.
    /// - Returns: A generator of random values within the bounds of range.
    @inlinable
    public static func generator(in range: ClosedRange<Self>) -> Gens.Float<Self> {
        .init(range: range)
    }
}

extension Gens {
    public struct Integer<Value: FixedWidthInteger>: Gen {
        @inlinable
        internal init(range: ClosedRange<Value>) {
            self.range = range
        }

        public let range: ClosedRange<Value>

        @inlinable
        public func run<RNG>(using rng: inout RNG) -> Value where RNG : RandomNumberGenerator {
            Value.random(in: range, using: &rng)
        }
    }

    public struct Float<Value: BinaryFloatingPoint>: Gen
    where Value.RawSignificand: FixedWidthInteger {
        @inlinable internal init(range: ClosedRange<Value>) {
            self.range = range
        }

        public let range: ClosedRange<Value>

        @inlinable
        public func run<RNG>(using rng: inout RNG) -> Value where RNG : RandomNumberGenerator {
            Value.random(in: range, using: &rng)
        }
    }
}

extension Gens.Integer: Sendable where Value: Sendable {}
extension Gens.Float: Sendable where Value: Sendable {}

extension Bool {
    public struct Generator: Gen, Sendable {
        @inlinable
        public init() {}

        @inlinable
        public func run<RNG>(using rng: inout RNG) -> Bool where RNG : RandomNumberGenerator {
            Bool.random(using: &rng)
        }
    }
}

public struct ElementOf<C: Collection>: Gen {
    public let collection: C

    @inlinable
    public init(_ collection: C) {
        self.collection = collection
    }

    @inlinable
    public func run<RNG>(using rng: inout RNG) -> C.Element? where RNG : RandomNumberGenerator {
        collection.randomElement(using: &rng)
    }
}

extension ElementOf: Sendable where C: Sendable {}

public struct Shuffled<C: Collection>: Gen {
    public let collection: C

    @inlinable
    public init(_ collection: C) {
        self.collection = collection
    }

    @inlinable
    public func run<RNG>(using rng: inout RNG) -> [C.Element] where RNG : RandomNumberGenerator {
        collection.shuffled(using: &rng)
    }
}

extension Shuffled: Sendable where C: Sendable {}

extension Gen where Value: Collection {
    public var element: Gens.FlatMap<Self, ElementOf<Value>> {
        self.flatMap { ElementOf($0) }
    }

    public var shuffled: Gens.FlatMap<Self, Shuffled<Self.Value>> {
        self.flatMap { Shuffled($0) }
    }
}

extension CaseIterable {
    @inlinable public func generator() -> Gens.Compact<ElementOf<AllCases>, Self> {
        ElementOf(Self.allCases).compact()
    }
}

extension RangeReplaceableCollection {
    @inlinable
    init(reservingCapacity capacity: Int) {
        self.init()
        reserveCapacity(capacity)
    }
}

extension Gens {
    public struct Reduce<
        Upstream: Gen,
        InitialValue: Gen,
        Count: Gen
    >: Gen where Count.Value: FixedWidthInteger {
        @inlinable
        internal init(
            upstream: Upstream,
            count: Count,
            initialValue: @escaping @Sendable (Count.Value) -> InitialValue,
            accumulate: @escaping @Sendable (inout InitialValue.Value, Upstream.Value) -> Void
        ) {
            self.upstream = upstream
            self.count = count
            self.initialValue = initialValue
            self.accumulate = accumulate
        }

        public typealias Value = InitialValue.Value

        public let upstream: Upstream
        public let count: Count
        public let initialValue: @Sendable (Count.Value) -> InitialValue
        public let accumulate: @Sendable (inout InitialValue.Value, Upstream.Value) -> Void

        @inlinable public func run<RNG>(using rng: inout RNG) -> Value where RNG : RandomNumberGenerator {
            let actualCount = self.count.run(using: &rng)
            var output = initialValue(actualCount).run(using: &rng)
            for _ in 1...actualCount {
                accumulate(&output, upstream.run(using: &rng))
            }
            return output
        }
    }
}

extension Gens.Reduce: Sendable where Upstream: Sendable, InitialValue: Sendable, Count: Sendable {}

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
        public func run<RNG>(using rng: inout RNG) -> Either<A.Value, B.Value> where RNG : RandomNumberGenerator {
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
    ) -> Gens.Reduce<Self, InitialValue, Count> {
        .init(upstream: self, count: count, initialValue: initialValue, accumulate: accumulate)
    }

    @inlinable
    public func reduce<Count: Gen, NewValue>(
        count: Count,
        into initialValue: @escaping @Sendable (Count.Value) -> NewValue,
        _ accumulate: @escaping @Sendable (inout NewValue, Value) -> Void
    ) -> Gens.Reduce<Self, Always<NewValue>, Count> {
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
    ) -> Gens.Reduce<Self, InitialValue, Count> {
        .init(upstream: self, count: count, initialValue: { _ in initialValue() }, accumulate: accumulate)
    }

    @inlinable
    public func reduce<Count: Gen, InitialValue>(
        count: Count,
        into initialValue: @escaping @Sendable @autoclosure () -> InitialValue,
        _ accumulate: @escaping @Sendable (inout InitialValue, Value) -> Void
    ) -> Gens.Reduce<Self, Always<InitialValue>, Count> {
        .init(upstream: self, count: count, initialValue: { _ in Always(initialValue()) }, accumulate: accumulate)
    }

    @inlinable
    public func array<Count: Gen<Int>>(
        of count: Count
    ) -> Gens.Reduce<Self, Always<[Self.Value]>, Count> {
       self.reduce(count: count, into: { Array(reservingCapacity: $0) }) { output, item in
            output.append(item)
        }
    }

    @inlinable
    public func dictionary<K: Hashable, V, Count: Gen<Int>>(
        ofAtMost count: Count
    ) -> Gens.Reduce<Self, Always<Dictionary<K, V>>, Count>
    where Value == (key: K, value: V) {
        self.reduce(count: count, into: {
            var d = Dictionary<K, V>()
            d.reserveCapacity($0)
            return d
        }) { output, pair in
            output[pair.key] = pair.value
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
    ) -> Gens.Reduce<Self, Always<String>, Count> {
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
    public func arrayGenerator() -> Gens.Traverse<Self, Element.Value> {
        self.traverse { $0 }
    }
}
