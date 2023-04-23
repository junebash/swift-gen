import Gen

// We want to generate passwords in the same format as those suggested by the iCloud keychain, for example `huwKun-1zyjxi-nyxseh`. It takes very little work! We're just three operations away:

let password = AnyGen.letterOrNumber
  // Generate a 6-character string of random letters and numbers.
  .string(of: .always(6))
  // Generate 3 segments of these strings.
  .array(of: .always(3))
  // And join them.
  .map { $0.joined(separator: "-") }

password.run()
password.run()
password.run()
password.run()
password.run()

let password2 = Gens.letterOrNumber
  .string(of: Always(6))
  .array(of: Always(3))
  .map { $0.joined(separator: "-") }

password2.run()
password2.run()
password2.run()
password2.run()
password2.run()

// The passwords Apple generates appears to strongly preference lowercase letters over uppercase letters. To get a bit closer we can dip down for a few lower-level combinators:
let iCloudPassword = AnyGen
  // Rather than work with evenly-distributed randomness across lowercase letters, uppercase letters, and numbers, let's weight lowercase letters much higher.
  .frequency(
    (12, .lowercaseLetter),
    (1, .uppercaseLetter),
    (1, .number)
  )
  // And do the same work as before.
  .string(of: .always(6))
  .array(of: .always(3))
  .map { $0.joined(separator: "-") }

iCloudPassword.run()
iCloudPassword.run()
iCloudPassword.run()
iCloudPassword.run()
iCloudPassword.run()

let iCloudPassword2 = Frequency(
  (12, Gens.lowercaseLetter),
  (1, Gens.uppercaseLetter),
  (1, Gens.number)
)
.string(of: Always(6))
.array(of: Always(3))
.map { $0.joined(separator: "-") }

iCloudPassword2.run()
iCloudPassword2.run()
iCloudPassword2.run()
iCloudPassword2.run()
iCloudPassword2.run()
