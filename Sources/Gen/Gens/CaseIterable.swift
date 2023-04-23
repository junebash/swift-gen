extension CaseIterable {
  @inlinable public func generator() -> Gens.Compact<ElementOf<AllCases>, Self> {
    ElementOf(Self.allCases).compact()
  }
}
