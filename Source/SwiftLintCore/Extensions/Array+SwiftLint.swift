import Dispatch

public extension Array where Element: Equatable {
    /// The elements in this array, discarding duplicates after the first one.
    /// Order-preserving.
    var unique: [Element] {
        var uniqueValues = [Element]()
        for item in self where !uniqueValues.contains(item) {
            uniqueValues.append(item)
        }
        return uniqueValues
    }
}

public extension Array where Element: Hashable {
    /// Produces an array containing the passed `obj` value.
    /// If `obj` is an array already, return it.
    /// If `obj` is a set, copy its elements to a new array.
    /// If `obj` is a value of type `Element`, return a single-item array containing it.
    ///
    /// - parameter obj: The input.
    ///
    /// - returns: The produced array.
    static func array(of obj: Any?) -> [Element]? {
        if let array = obj as? [Element] {
            return array
        }
        if let set = obj as? Set<Element> {
            return Array(set)
        }
        if let obj = obj as? Element {
            return [obj]
        }
        return nil
    }
}

public extension Array {
    /// Produces an array containing the passed `obj` value.
    /// If `obj` is an array already, return it.
    /// If `obj` is a value of type `Element`, return a single-item array containing it.
    ///
    /// - parameter obj: The input.
    ///
    /// - returns: The produced array.
    static func array(of obj: Any?) -> [Element]? {
        if let array = obj as? [Element] {
            return array
        }
        if let obj = obj as? Element {
            return [obj]
        }
        return nil
    }

    /// Group the elements in this array into a dictionary, keyed by applying the specified `transform`.
    ///
    /// - parameter transform: The transformation function to extract an element to its group key.
    ///
    /// - returns: The elements grouped by applying the specified transformation.
    func group<U: Hashable>(by transform: (Element) -> U) -> [U: [Element]] {
        Dictionary(grouping: self, by: { transform($0) })
    }

    /// Group the elements in this array into a dictionary, keyed by applying the specified `transform`.
    /// Elements for which the `transform` returns a `nil` key are removed.
    ///
    /// - parameter transform: The transformation function to extract an element to its group key,
    ///                        or exclude the element.
    ///
    /// - returns: The elements grouped by applying the specified transformation.
    func filterGroup<U: Hashable & Sendable>(by transform: (Element) -> U?) ->
        [U: [Element]] where Element: Sendable {
        var result = [U: [Element]]()
        for element in self {
            if let key = transform(element) {
                result[key, default: []].append(element)
            }
        }
        return result
    }

    /// Same as `filterGroup`, but spreads the work in the `transform` block in parallel using GCD's
    /// `concurrentPerform`.
    ///
    /// - parameter transform: The transformation function to extract an element to its group key,
    ///                        or exclude the element.
    ///
    /// - returns: The elements grouped by applying the specified transformation.
    func parallelFilterGroup<U: Hashable & Sendable>(by transform: @Sendable (Element) -> U?) ->
        [U: [Element]] where Element: Sendable {
        if count < 16 {
            return filterGroup(by: transform)
        }
        let pivot = count / 2
        let results = [
            Array(self[0..<pivot]),
            Array(self[pivot...]),
        ].parallelMap { subarray in
            subarray.parallelFilterGroup(by: transform)
        }
        return results[0].merging(results[1], uniquingKeysWith: +)
    }

    /// Returns the elements failing the `belongsInSecondPartition` test, followed by the elements passing the
    /// `belongsInSecondPartition` test.
    ///
    /// - parameter belongsInSecondPartition: The test function to determine if the element should be in the second
    ///                                       partition.
    ///
    /// - returns: The elements failing the `belongsInSecondPartition` test, followed by the elements passing the
    ///            `belongsInSecondPartition` test.
    func partitioned(by belongsInSecondPartition: (Element) throws -> Bool) rethrows ->
        (first: ArraySlice<Element>, second: ArraySlice<Element>) {
            var copy = self
            let pivot = try copy.partition(by: belongsInSecondPartition)
            return (copy[0..<pivot], copy[pivot..<count])
    }

    /// Same as `flatMap` but spreads the work in the `transform` block in parallel using GCD's `concurrentPerform`.
    ///
    /// - parameter transform: The transformation to apply to each element.
    ///
    /// - returns: The result of applying `transform` on every element and flattening the results.
    func parallelFlatMap<T>(transform: @Sendable (Element) -> [T]) -> [T] {
        parallelMap(transform: transform).flatMap { $0 }
    }

    /// Same as `compactMap` but spreads the work in the `transform` block in parallel using GCD's `concurrentPerform`.
    ///
    /// - parameter transform: The transformation to apply to each element.
    ///
    /// - returns: The result of applying `transform` on every element and discarding the `nil` ones.
    func parallelCompactMap<T>(transform: @Sendable (Element) -> T?) -> [T] {
        parallelMap(transform: transform).compactMap { $0 }
    }

    /// Same as `map` but spreads the work in the `transform` block in parallel using GCD's `concurrentPerform`.
    ///
    /// - parameter transform: The transformation to apply to each element.
    ///
    /// - returns: The result of applying `transform` on every element.
    func parallelMap<T>(transform: @Sendable (Element) -> T) -> [T] {
        var result = ContiguousArray<T?>(repeating: nil, count: count)
        return result.withUnsafeMutableBufferPointer { buffer in
            let buffer = MutableWrapper(buffer: buffer)
            withUnsafeBufferPointer { array in
                let array = ImmutableWrapper(buffer: array)
                DispatchQueue.concurrentPerform(iterations: buffer.count) { idx in
                    buffer[idx] = transform(array[idx])
                }
            }
            return buffer.data
        }
    }

    private class MutableWrapper<T>: @unchecked Sendable {
        let buffer: UnsafeMutableBufferPointer<T?>

        init(buffer: UnsafeMutableBufferPointer<T?>) {
            self.buffer = buffer
        }

        var data: [T] {
            buffer.map { $0! }
        }

        var count: Int {
            buffer.count
        }

        subscript(index: Int) -> T {
            get {
                queuedFatalError("Do not call this getter.")
            }
            set(newValue) {
                buffer[index] = newValue
            }
        }
    }

    private class ImmutableWrapper<T>: @unchecked Sendable {
        let buffer: UnsafeBufferPointer<T>

        init(buffer: UnsafeBufferPointer<T>) {
            self.buffer = buffer
        }

        subscript(index: Int) -> T {
            buffer[index]
        }
    }
}

public extension Collection {
    /// Whether this collection has one or more element.
    var isNotEmpty: Bool {
        !isEmpty
    }

    /// Get the only element in the collection.
    ///
    /// If the collection is empty or contains more than one element the result will be `nil`.
    var onlyElement: Element? {
        count == 1 ? first : nil
    }
}
