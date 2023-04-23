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
