extension Gens {
  public struct Zip3<A, B, C>: Gen
  where A: Gen, B: Gen, C: Gen {
    @inlinable internal init(gens: (A, B, C)) {
      self.gens = gens
    }

    public let gens: (A, B, C)

    @inlinable
    public func run<RNG>(using rng: inout RNG) -> (A.Value, B.Value, C.Value)
    where RNG : RandomNumberGenerator {
      (
        gens.0.run(using: &rng),
        gens.1.run(using: &rng),
        gens.2.run(using: &rng)
      )
    }
  }

  public struct Zip4<A, B, C, D>: Gen
  where A: Gen, B: Gen, C: Gen, D: Gen {
    @inlinable internal init(gens: (A, B, C, D)) {
      self.gens = gens
    }

    public let gens: (A, B, C, D)

    @inlinable
    public func run<RNG>(using rng: inout RNG) -> (A.Value, B.Value, C.Value, D.Value)
    where RNG : RandomNumberGenerator {
      (
        gens.0.run(using: &rng),
        gens.1.run(using: &rng),
        gens.2.run(using: &rng),
        gens.3.run(using: &rng)
      )
    }
  }

  public struct Zip5<A, B, C, D, E>: Gen
  where A: Gen, B: Gen, C: Gen, D: Gen, E: Gen {
    @inlinable internal init(gens: (A, B, C, D, E)) {
      self.gens = gens
    }

    public let gens: (A, B, C, D, E)

    @inlinable
    public func run<RNG>(using rng: inout RNG) -> (A.Value, B.Value, C.Value, D.Value, E.Value)
    where RNG : RandomNumberGenerator {
      (
        gens.0.run(using: &rng),
        gens.1.run(using: &rng),
        gens.2.run(using: &rng),
        gens.3.run(using: &rng),
        gens.4.run(using: &rng)
      )
    }
  }

  public struct Zip6<A, B, C, D, E, F>: Gen
  where A: Gen, B: Gen, C: Gen, D: Gen, E: Gen, F: Gen {
    @inlinable internal init(gens: (A, B, C, D, E, F)) {
      self.gens = gens
    }

    public let gens: (A, B, C, D, E, F)

    @inlinable
    public func run<RNG>(using rng: inout RNG) -> (A.Value, B.Value, C.Value, D.Value, E.Value, F.Value)
    where RNG : RandomNumberGenerator {
      (
        gens.0.run(using: &rng),
        gens.1.run(using: &rng),
        gens.2.run(using: &rng),
        gens.3.run(using: &rng),
        gens.4.run(using: &rng),
        gens.5.run(using: &rng)
      )
    }
  }
}

public func zip<A, B, C>(
  _ a: A,
  _ b: B,
  _ c: C
) -> Gens.Zip3<A, B, C> {
  .init(gens: (a, b, c))
}

public func zip<A, B, C, D>(
  _ a: A,
  _ b: B,
  _ c: C,
  _ d: D
) -> Gens.Zip4<A, B, C, D> {
  .init(gens: (a, b, c, d))
}

public func zip<A, B, C, D, E>(
  _ a: A,
  _ b: B,
  _ c: C,
  _ d: D,
  _ e: E
) -> Gens.Zip5<A, B, C, D, E> {
  .init(gens: (a, b, c, d, e))
}

public func zip<A, B, C, D, E, F>(
  _ a: A,
  _ b: B,
  _ c: C,
  _ d: D,
  _ e: E,
  _ f: F
) -> Gens.Zip6<A, B, C, D, E, F> {
  .init(gens: (a, b, c, d, e, f))
}

public func zip<A: Gen, B: Gen, C: Gen, D: Gen, E: Gen, F: Gen, G: Gen>(
  _ a: A,
  _ b: B,
  _ c: C,
  _ d: D,
  _ e: E,
  _ f: F,
  _ g: G
) -> Gens.Map<
  Gens.Zip2<Gens.Zip4<A, B, C, D>, Gens.Zip3<E, F, G>>,
  (A.Value, B.Value, C.Value, D.Value, E.Value, F.Value, G.Value)
> {
  Gens.Zip2(a: Gens.Zip4(gens: (a, b, c, d)), b: Gens.Zip3(gens: (e, f, g))).map { abcd, efg in
    let (a, b, c, d) = abcd
    let (e, f, g) = efg
    return (a, b, c, d, e, f, g)
  }
}

public func zip<A: Gen, B: Gen, C: Gen, D: Gen, E: Gen, F: Gen, G: Gen, H: Gen>(
  _ a: A,
  _ b: B,
  _ c: C,
  _ d: D,
  _ e: E,
  _ f: F,
  _ g: G,
  _ h: H
) -> Gens.Map<
  Gens.Zip2<Gens.Zip4<A, B, C, D>, Gens.Zip4<E, F, G, H>>,
  (A.Value, B.Value, C.Value, D.Value, E.Value, F.Value, G.Value, H.Value)
> {
  Gens.Zip2(a: Gens.Zip4(gens: (a, b, c, d)), b: Gens.Zip4(gens: (e, f, g, h))).map { abcd, efgh in
    let (a, b, c, d) = abcd
    let (e, f, g, h) = efgh
    return (a, b, c, d, e, f, g, h)
  }
}

public func zip<A: Gen, B: Gen, C: Gen, D: Gen, E: Gen, F: Gen, G: Gen, H: Gen, I: Gen>(
  _ a: A,
  _ b: B,
  _ c: C,
  _ d: D,
  _ e: E,
  _ f: F,
  _ g: G,
  _ h: H,
  _ i: I
) -> Gens.Map<
  Gens.Zip2<Gens.Zip4<A, B, C, D>, Gens.Zip5<E, F, G, H, I>>,
  (A.Value, B.Value, C.Value, D.Value, E.Value, F.Value, G.Value, H.Value, I.Value)
> {
  Gens.Zip2(a: Gens.Zip4(gens: (a, b, c, d)), b: Gens.Zip5(gens: (e, f, g, h, i))).map { abcd, efghi in
    let (a, b, c, d) = abcd
    let (e, f, g, h, i) = efghi
    return (a, b, c, d, e, f, g, h, i)
  }
}

public func zip<A: Gen, B: Gen, C: Gen, D: Gen, E: Gen, F: Gen, G: Gen, H: Gen, I: Gen, J: Gen>(
  _ a: A,
  _ b: B,
  _ c: C,
  _ d: D,
  _ e: E,
  _ f: F,
  _ g: G,
  _ h: H,
  _ i: I,
  _ j: J
) -> Gens.Map<
  Gens.Zip2<Gens.Zip4<A, B, C, D>, Gens.Zip6<E, F, G, H, I, J>>,
  (A.Value, B.Value, C.Value, D.Value, E.Value, F.Value, G.Value, H.Value, I.Value, J.Value)
> {
  Gens.Zip2(a: Gens.Zip4(gens: (a, b, c, d)), b: Gens.Zip6(gens: (e, f, g, h, i, j))).map { abcd, efghij in
    let (a, b, c, d) = abcd
    let (e, f, g, h, i, j) = efghij
    return (a, b, c, d, e, f, g, h, i, j)
  }
}
