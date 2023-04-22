/// An implementation of xoshiro256**: http://xoshiro.di.unimi.it.
///
/// Portions adopted from [https://github.com/mattgallagher/CwlUtils/blob/0bfc4587d01cfc796b6c7e118fc631333dd8ab33/Sources/CwlUtils/CwlRandom.swift]().
public struct Xoshiro: RandomNumberGenerator, Sendable {
  public struct State: Hashable, Sendable {
    public var a, b, c, d: UInt64

    @inlinable
    public var next: UInt64 {
      let x = b &* 5
      return ((x &<< 7) | (x &>> 57)) &* 9
    }

    @inlinable
    public init(_ a: UInt64, _ b: UInt64, _ c: UInt64, _ d: UInt64) {
      self.a = a
      self.b = b
      self.c = c
      self.d = d
    }

    @inlinable
    internal init(seed: UInt64) {
      self.init(seed, 18_446_744, 073_709, 551_615)
    }

    @inlinable
    public mutating func perturb() {
      let t = self.b &<< 17
      self.c ^= self.a
      self.d ^= self.b
      self.b ^= self.c
      self.a ^= self.d
      self.c ^= t
      self.d = (self.d &<< 45) | (self.d &>> 19)
    }
  }

  @usableFromInline internal var state: State

  public var currentState: State { state }

  /// Initialize with a full state.
  ///
  /// Useful for getting an exact value from `next()` after multiple runs of the RNG.
  @inlinable
  public init(state: State) {
    self.state = state
  }

  @inlinable
  public init() {
    self.state = .init(
      .random(in: .min ... .max),
      .random(in: .min ... .max),
      .random(in: .min ... .max),
      .random(in: .min ... .max)
    )
  }

  @inlinable
  public init(seed: UInt64) {
    self.state = State(seed: seed)
    for _ in 1...10 { _ = self.next() }  // perturb
  }

  @inlinable
  public init(byteSeed: some Collection<UInt8>) {
    self.state = State(seed: 0)
    withUnsafeMutableBytes(of: &state) { stateBuffer in
      var byteSeed = byteSeed[...]
      while !byteSeed.isEmpty {
        let newBytes = byteSeed.prefix(stateBuffer.count)
        for (i, newByte) in zip(stateBuffer.indices, newBytes) {
          stateBuffer[i] ^= newByte
        }
        byteSeed.removeFirst(newBytes.count)
      }
    }
  }

  @inlinable
  public init(textSeed: some StringProtocol) {
    self.init(byteSeed: textSeed.utf8)
  }

  @inlinable
  public mutating func next() -> UInt64 {
    defer { state.perturb() }
    return state.next
  }
}

extension Xoshiro.State: Codable {
  public init(from decoder: Decoder) throws {
    var container = try decoder.unkeyedContainer()
    guard container.count == 4 else {
      throw DecodingError.dataCorrupted(.init(
        codingPath: container.codingPath,
        debugDescription: "Expected 4 values in unkeyed container, found \(container.count.map(String.init(_:)) ?? "none")"
      ))
    }
    self.a = try container.decode(UInt64.self)
    self.b = try container.decode(UInt64.self)
    self.c = try container.decode(UInt64.self)
    self.d = try container.decode(UInt64.self)
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.unkeyedContainer()
    try container.encode(a)
    try container.encode(b)
    try container.encode(c)
    try container.encode(d)
  }
}
