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

extension Gen where Value: Collection {
  public var element: Gens.FlatMap<Self, ElementOf<Value>> {
    self.flatMap { ElementOf($0) }
  }
}
