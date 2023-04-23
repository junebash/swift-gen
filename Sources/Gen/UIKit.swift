#if canImport(UIKit)
  import UIKit

  extension AnyGen where Value == UIColor {
    public static let color = zip(.float(in: 0...1), .float(in: 0...1), .float(in: 0...1))
      .map { UIColor(red: $0, green: $1, blue: $2, alpha: 1) }
  }

  extension UIColor {
    public static let generator: some Gen<UIColor> = zip(
      CGFloat.generator(in: 0...1),
      CGFloat.generator(in: 0...1),
      CGFloat.generator(in: 0...1)
    )
    .map { UIColor(red: $0, green: $1, blue: $2, alpha: 1) }
  }
#endif
