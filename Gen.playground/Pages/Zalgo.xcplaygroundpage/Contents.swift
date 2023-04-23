import Gen

// We want to create a generator that can randomly "Zalgo-ify" any string, which mean sit will glitch it
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

// Given an intensity, combines a random number of Zalgo characters into a single string.
func zalgos<G: Gen<Int>>(
  intensity: G
) -> Gens.Map<Reduce<Gens.Map<Gens.Integer<Int>, String>, Always<[String]>, G>, String> {
  zalgo
    .array(of: intensity)
    .map { $0.joined() }
}

let tameZalgos   = zalgos(intensity: Int.generator(in: 0...1))
let lowZalgos    = zalgos(intensity: Int.generator(in: 1...5))
let mediumZalgos = zalgos(intensity: Int.generator(in: 0...10))
let highZalgos   = zalgos(intensity: Int.generator(in: 0...20))

"a" + tameZalgos.run()
"a" + lowZalgos.run()
"a" + mediumZalgos.run()
"a" + highZalgos.run()

// Given a way to generate a bunch of Zalgo characters, this will return a function that can "Zalgo-ify" any string given to it.
public struct Zalgoify<Zalgos: Gen<String>> {
  public struct Generator: Gen {
    let zalgos: Zalgos
    let string: String

    public func run<RNG>(using rng: inout RNG) -> String where RNG : RandomNumberGenerator {
      string
        .map { char in String(char) + zalgos.run(using: &rng) }
        .joined()
    }
  }

  public let zalgos: Zalgos

  init(with zalgos: Zalgos) {
    self.zalgos = zalgos
  }

  public func callAsFunction(_ string: String) -> some Gen<String> {
    Generator(zalgos: zalgos, string: string)
  }
}

let tameZalgoify   = Zalgoify(with: tameZalgos)
let lowZalgoify    = Zalgoify(with: lowZalgos)
let mediumZalgoify = Zalgoify(with: mediumZalgos)
let highZalgoify   = Zalgoify(with: highZalgos)

tameZalgoify("What’s the point?").run()
lowZalgoify("What’s the point?").run()
mediumZalgoify("What’s the point?").run()
highZalgoify("What’s the point?").run()
