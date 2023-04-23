extension UnicodeScalar {
  @inlinable
  public static func generator(
    inNumericRange range: ClosedRange<UInt32>
  ) -> Gens.Compact<Gens.Map<Gens.Integer<UInt32>, UnicodeScalar?>, UnicodeScalar> {
    UInt32.generator(in: range)
      .compactMap { UnicodeScalar($0) }
  }

  @inlinable
  public static func generator(
    in range: ClosedRange<UnicodeScalar>
  ) -> Gens.Compact<Gens.Map<Gens.Integer<UInt32>, UnicodeScalar?>, UnicodeScalar> {
    UnicodeScalar.generator(inNumericRange: range.lowerBound.value...range.upperBound.value)
  }
}

extension Character {
  @inlinable
  public static func generator(
    in range: ClosedRange<Character>
  ) -> Gens.Map<
    Gens.Compact<Gens.Map<Gens.Integer<UInt32>, UnicodeScalar?>, UnicodeScalar>,
    Character
  > {
    UnicodeScalar.generator(
      in: range.lowerBound.unicodeScalars.first!...range.upperBound.unicodeScalars.last!
    )
    .map { Character($0) }
  }

  public static func generator(
    in string: String
  ) -> Gens.Compact<ElementOf<[Character]>, Character> {
    ElementOf([Character](string)).compact()
  }
}

private extension String {
  static let _numbers = "0123456789"
  static let _lowerLetters = "abcdefghijklmnopqrstuvwxyz"
  static let _upperLetters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
}

extension Gens {
  public static let number = Character.generator(in: ._numbers)
  public static let uppercaseLetter = Character.generator(in: ._upperLetters)
  public static let lowercaseLetter = Character.generator(in: ._lowerLetters)
  public static let letter = Character.generator(in: ._upperLetters + ._lowerLetters)
  public static let letterOrNumber = Character
    .generator(in: ._lowerLetters + ._upperLetters + ._numbers)

  public static let ascii = UnicodeScalar.generator(inNumericRange: 0...127)
  public static let latin1 = UnicodeScalar.generator(inNumericRange: 0...255)
}

extension Gen where Value == Character {
  @inlinable
  public func string<Count: Gen<Int>>(
    of count: Count
  ) -> Reduce<Self, Always<String>, Count> {
    self.reduce(count: count, into: { String(reservingCapacity: $0) }) { $0.append($1) }
  }
}
