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
  public var shuffled: Gens.FlatMap<Self, Shuffled<Self.Value>> {
    self.flatMap { Shuffled($0) }
  }
}
