import Gen

// We want to create a generator that can randomly "Zalgo-ify" any string, which means it will glitch it
// out with random artifacts, as seen here: http://www.eeemo.net

// A Zalgo character is a UTF8 character in the "combining character" range.
// See: https://en.wikipedia.org/wiki/Combining_character
let zalgo = Int.generator(in: 0x300 ... 0x36f)
  .map { String(UnicodeScalar($0)!) }

// Here's what some Zalgo characters look like
zalgo.run()

zalgo.run()

zalgo.run()

zalgo.run()

struct Zalgos<Intensity: Gen<Int>>: Gen {
  let intensity: Intensity

  typealias Value = String

  private let zalgo = Int.generator(in: 0x300 ... 0x36f)
    .map { Character(UnicodeScalar($0)!) }

  var body: some Gen<String> {
    zalgo.array(of: intensity)
      .map { String($0) }
  }
}

extension Zalgos where Intensity == Gens.Integer<Int> {
  static var tame: Zalgos<Gens.Integer<Int>> { Zalgos(intensity: Int.generator(in: 0...1)) }
  static var low: Zalgos<Gens.Integer<Int>> { Zalgos(intensity: Int.generator(in: 1...5)) }
  static var medium: Zalgos<Gens.Integer<Int>> { Zalgos(intensity: Int.generator(in: 0...10)) }
  static var high: Zalgos<Gens.Integer<Int>> { Zalgos(intensity: Int.generator(in: 0...20)) }
}

// Given an intensity, combines a random number of Zalgo characters into a single string.
func zalgos<G: Gen<Int>>(
  intensity: G
) -> Gens.Map<Reduce<Gens.Map<Gens.Integer<Int>, String>, Always<[String]>, G>, String> {
  zalgo
    .array(of: intensity)
    .map { $0.joined() }
}


"a" + Zalgos.tame.run()
"a" + Zalgos.low.run()
"a" + Zalgos.medium.run()
"a" + Zalgos.high.run()

// Given a way to generate a bunch of Zalgo characters, this will return a function that can "Zalgo-ify" any string given to it.
public struct Zalgoify<Intensity: Gen<Int>>: Gen {
  let zalgos: Zalgos<Intensity>
  let input: String

  init(_ zalgos: Zalgos<Intensity>, input: String) {
    self.input = input
    self.zalgos = zalgos
  }

  public func run<RNG>(using rng: inout RNG) -> String where RNG : RandomNumberGenerator {
    input
      .map { char in String(char) + zalgos.run(using: &rng) }
      .joined()
  }
}

extension Zalgoify where Intensity == Gens.Integer<Int> {
  static func tame(_ input: String) -> Self {
    .init(.tame, input: input)
  }
  static func low(_ input: String) -> Self {
    .init(.low, input: input)
  }
  static func medium(_ input: String) -> Self {
    .init(.medium, input: input)
  }
  static func high(_ input: String) -> Self {
    .init(.high, input: input)
  }
}

//Zalgoify.tame("What’s the point?").run()
Zalgoify(.tame, input: "What's the point?").run()

Zalgoify.low("What’s the point?").run()

Zalgoify.medium("What’s the point?").run()

Zalgoify.high("What’s the point?").run()
