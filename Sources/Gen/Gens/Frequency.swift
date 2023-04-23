/// Uses a weighted distribution to randomly select one of the generators in the list.
public struct Frequency<Upstream: Gen>: Gen {
  public let generators: [Upstream]

  /// Uses a weighted distribution to randomly select one of the generators in the list.
  @inlinable
  public init(_ distribution: some Sequence<(Int, Upstream)>) {
    self.generators = distribution.flatMap {
      repeatElement($1, count: $0)
    }
    precondition(!generators.isEmpty)
  }

  /// Uses a weighted distribution to randomly select one of the generators in the list.
  @inlinable
  public init(
    _ first: (Int, Upstream),
    _ distribution: (Int, Upstream)...
  ) {
    self.init(_Chain2Sequence(a: CollectionOfOne(first), b: distribution))
  }

  @inlinable
  public func run<RNG>(using rng: inout RNG) -> Upstream.Value where RNG : RandomNumberGenerator {
    generators.randomElement(using: &rng)!.run(using: &rng)
  }
}
