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
