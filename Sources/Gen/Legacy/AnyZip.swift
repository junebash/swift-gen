@inlinable
public func zip<A, B, C>(
  _ a: AnyGen<A>,
  _ b: AnyGen<B>,
  _ c: AnyGen<C>
)
-> AnyGen<(A, B, C)>
{
  return zip(zip(a, b), c).map { ($0.0, $0.1, $1) }
}

@inlinable
public func zip<A, B, C, D>(
  _ a: AnyGen<A>,
  _ b: AnyGen<B>,
  _ c: AnyGen<C>,
  _ d: AnyGen<D>
)
-> AnyGen<(A, B, C, D)>
{
  return zip(zip(a, b), c, d).map { ($0.0, $0.1, $1, $2) }
}

@inlinable
public func zip<A, B, C, D, E>(
  _ a: AnyGen<A>,
  _ b: AnyGen<B>,
  _ c: AnyGen<C>,
  _ d: AnyGen<D>,
  _ e: AnyGen<E>
)
-> AnyGen<(A, B, C, D, E)>
{
  return zip(zip(a, b), c, d, e).map { ($0.0, $0.1, $1, $2, $3) }
}

@inlinable
public func zip<A, B, C, D, E, F>(
  _ a: AnyGen<A>,
  _ b: AnyGen<B>,
  _ c: AnyGen<C>,
  _ d: AnyGen<D>,
  _ e: AnyGen<E>,
  _ f: AnyGen<F>
)
-> AnyGen<(A, B, C, D, E, F)>
{
  return zip(zip(a, b), c, d, e, f).map { ($0.0, $0.1, $1, $2, $3, $4) }
}

@inlinable
public func zip<A, B, C, D, E, F, G>(
  _ a: AnyGen<A>,
  _ b: AnyGen<B>,
  _ c: AnyGen<C>,
  _ d: AnyGen<D>,
  _ e: AnyGen<E>,
  _ f: AnyGen<F>,
  _ g: AnyGen<G>
)
-> AnyGen<(A, B, C, D, E, F, G)>
{
  return zip(zip(a, b), c, d, e, f, g).map { ($0.0, $0.1, $1, $2, $3, $4, $5) }
}

@inlinable
public func zip<A, B, C, D, E, F, G, H>(
  _ a: AnyGen<A>,
  _ b: AnyGen<B>,
  _ c: AnyGen<C>,
  _ d: AnyGen<D>,
  _ e: AnyGen<E>,
  _ f: AnyGen<F>,
  _ g: AnyGen<G>,
  _ h: AnyGen<H>
)
-> AnyGen<(A, B, C, D, E, F, G, H)>
{
  return zip(zip(a, b), c, d, e, f, g, h).map { ($0.0, $0.1, $1, $2, $3, $4, $5, $6) }
}

@inlinable
public func zip<A, B, C, D, E, F, G, H, I>(
  _ a: AnyGen<A>,
  _ b: AnyGen<B>,
  _ c: AnyGen<C>,
  _ d: AnyGen<D>,
  _ e: AnyGen<E>,
  _ f: AnyGen<F>,
  _ g: AnyGen<G>,
  _ h: AnyGen<H>,
  _ i: AnyGen<I>
)
-> AnyGen<(A, B, C, D, E, F, G, H, I)>
{
  return zip(zip(a, b), c, d, e, f, g, h, i).map { ($0.0, $0.1, $1, $2, $3, $4, $5, $6, $7) }
}

@inlinable
public func zip<A, B, C, D, E, F, G, H, I, J>(
  _ a: AnyGen<A>,
  _ b: AnyGen<B>,
  _ c: AnyGen<C>,
  _ d: AnyGen<D>,
  _ e: AnyGen<E>,
  _ f: AnyGen<F>,
  _ g: AnyGen<G>,
  _ h: AnyGen<H>,
  _ i: AnyGen<I>,
  _ j: AnyGen<J>
)
-> AnyGen<(A, B, C, D, E, F, G, H, I, J)>
{
  return zip(zip(a, b), c, d, e, f, g, h, i, j).map { ($0.0, $0.1, $1, $2, $3, $4, $5, $6, $7, $8) }
}
