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
