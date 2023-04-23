@usableFromInline
internal struct _Chain2Sequence<A: Sequence, B: Sequence>: Sequence where A.Element == B.Element {
  @usableFromInline
  typealias Element = A.Element

  @usableFromInline
  internal struct Iterator: IteratorProtocol {
    @usableFromInline
    var a: A.Iterator?

    @usableFromInline
    var b: B.Iterator

    @inlinable
    init(a: A.Iterator, b: B.Iterator) {
      self.a = a
      self.b = b
    }

    @inlinable
    mutating func next() -> A.Element? {
      if a != nil {
        if let aValue = a!.next() {
          return aValue
        } else {
          a = nil
        }
      }
      return b.next()
    }
  }

  @usableFromInline
  let a: A

  @usableFromInline
  let b: B

  @inlinable
  init(a: A, b: B) {
    self.a = a
    self.b = b
  }

  @inlinable
  func makeIterator() -> Iterator {
    .init(a: a.makeIterator(), b: b.makeIterator())
  }
}
