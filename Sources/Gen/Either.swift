public enum Either<Left, Right> {
    case left(Left)
    case right(Right)
}

extension Either: Equatable where Left: Equatable, Right: Equatable {}
extension Either: Hashable where Left: Hashable, Right: Hashable {}
extension Either: Sendable where Left: Sendable, Right: Sendable {}
extension Either: Comparable where Left: Comparable, Right: Comparable {}

extension Either {
    public var swapped: Either<Right, Left> {
        switch self {
        case .left(let left): return .right(left)
        case .right(let right): return .left(right)
        }
    }

    public var left: Left? {
        if case .left(let left) = self {
            return left
        } else { return nil }
    }

    public var right: Right? {
        if case .right(let right) = self {
            return right
        } else { return nil }
    }

    public func mapLeft<NewLeft>(
        _ transform: (Left) throws -> NewLeft
    ) rethrows -> Either<NewLeft, Right> {
        switch self {
        case .left(let left): return .left(try transform(left))
        case .right(let right): return .right(right)
        }
    }

    public func mapRight<NewRight>(
        _ transform: (Right) throws -> NewRight
    ) rethrows -> Either<Left, NewRight> {
        switch self {
        case .left(let left): return .left(left)
        case .right(let right): return .right(try transform(right))
        }
    }
}

// MARK: - Specialized

extension Either: IteratorProtocol
where Left: IteratorProtocol, Right: IteratorProtocol, Left.Element == Right.Element {
    public mutating func next() -> Left.Element? {
        switch self {
        case .left(var iterator):
            let output = iterator.next()
            self = .left(iterator)
            return output
        case .right(var iterator):
            let output = iterator.next()
            self = .right(iterator)
            return output
        }
    }
}

extension Either: Sequence
where Left: Sequence, Right: Sequence, Left.Element == Right.Element {
    public func makeIterator() -> Either<Left.Iterator, Right.Iterator> {
        switch self {
        case .left(let left): return .left(left.makeIterator())
        case .right(let right): return .right(right.makeIterator())
        }
    }
}

extension Either where Right: Error {
    public var asResult: Result<Left, Right> {
        switch self {
        case .left(let left): return .success(left)
        case .right(let right): return .failure(right)
        }
    }
}

extension Either where Left == Right {
    var value: Left {
        switch self {
        case .left(let value), .right(let value): return value
        }
    }
}
