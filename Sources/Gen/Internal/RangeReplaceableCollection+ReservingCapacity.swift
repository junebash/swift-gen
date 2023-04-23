extension RangeReplaceableCollection {
  @inlinable
  init(reservingCapacity capacity: Int) {
    self.init()
    reserveCapacity(capacity)
  }
}
