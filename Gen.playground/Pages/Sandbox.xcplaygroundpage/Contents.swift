import Gen

zip(.bool, .bool).dictionary(ofAtMost: .always(1)).run()
zip(Bool.Generator(), Bool.Generator()).dictionary(ofAtMost: Always(1)).run()
Bool.Generator().set(ofAtMost: Always(3)).run()
Float.generator(in: 0...1)

import CoreGraphics
CGFloat.generator(in: 0...1)
