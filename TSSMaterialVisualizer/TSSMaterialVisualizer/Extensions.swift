import Foundation

//
// Copyright 2018 Vinicius Jorge Vendramini
//
// Licensed under the Hippocratic License, Version 2.1;
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// https://firstdonoharm.dev/version/2/1/license
//
// To the full extent allowed by law, this software comes "AS IS,"
// WITHOUT ANY WARRANTY, EXPRESS OR IMPLIED, and licensor and any other
// contributor shall not be liable to anyone for any damages or other
// liability arising from, out of, or in connection with the sotfware
// or this license, under any kind of legal claim.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import Foundation

internal extension String {
    // Result should have at most maxSplits + 1 elements.
    func split(
        withStringSeparator separator: String,
        maxSplits: Int = Int.max,
        omittingEmptySubsequences: Bool = true) -> MutableList<String>
    {
        let result: MutableList<String> = []

        var splits = 0
        var previousIndex = startIndex
        let separators = self.occurrences(of: separator)

        // Add all substrings immediately before each separator
        for separator in separators {
            if splits >= maxSplits {
                splits += 1
                break
            }

            let substring = self[previousIndex..<separator.lowerBound]

            if omittingEmptySubsequences {
                guard !substring.isEmpty else {
                    splits += 1
                    previousIndex = separator.upperBound
                    continue
                }
            }

            result.append(String(substring))

            splits += 1
            previousIndex = separator.upperBound
        }

        // Add the last substring (which the loop above ignores)
        let substring = self[previousIndex..<endIndex]
        if !(substring.isEmpty && omittingEmptySubsequences) {
            result.append(String(substring))
        }

        return result
    }

    /// Non-overlapping
    func occurrences(of searchedSubstring: String) -> MutableList<Range<String.Index>> {
        let result: MutableList<Range<String.Index>> = []

        var currentSubstring = Substring(self)
        var substringOffset = self.startIndex

        while substringOffset < self.endIndex {
            let maybeIndex = currentSubstring.range(of: searchedSubstring)?.lowerBound

            guard let foundIndex = maybeIndex else {
                break
            }

            // In Kotlin the foundIndex is counted from the substring's start, but in Swift it's
            // from the string's start. This compensates for that difference.
            let occurenceStartIndex = foundIndex

            let occurenceEndIndex =
                currentSubstring.index(occurenceStartIndex, offsetBy: searchedSubstring.count)
            result.append(Range<String.Index>(uncheckedBounds:
                (lower: occurenceStartIndex, upper: occurenceEndIndex)))
            substringOffset = occurenceEndIndex
            currentSubstring = self[substringOffset...]
        }
        return result
    }

    /// Returns an array of the string's components separated by spaces. Spaces that have been
    /// escaped ("\ ") are ignored.
    func splitUsingUnescapedSpaces() -> MutableList<String> {
        let result: MutableList<String> = []

        var isEscaping = false
        var index = self.startIndex
        var startIndexOfCurrentComponent = index
        while index != self.endIndex {
            let character = self[index]
            if character == "\\" {
                isEscaping = !isEscaping
            }
            else if character == " ", !isEscaping {
                let component = String(self[startIndexOfCurrentComponent..<index])
                if !component.isEmpty {
                    result.append(component)
                }
                startIndexOfCurrentComponent = self.index(after: index)
            }

            if character != "\\" {
                isEscaping = false
            }

            index = self.index(after: index)
        }

        if startIndexOfCurrentComponent != index {
            result.append(String(self[startIndexOfCurrentComponent..<index]))
        }

        return result
    }

    func removeTrailingWhitespace() -> String {
        guard !isEmpty else {
            return ""
        }

        var lastValidIndex = index(before: endIndex)
        while lastValidIndex != startIndex {
            let character = self[lastValidIndex]
            if character != " " && character != "\t" {
                break
            }
            self.formIndex(before: &lastValidIndex)
        }
        return String(self[startIndex...lastValidIndex])
    }

    /// "fooBar" becomes "FOO_BAR", "HTTPSBar" becomes "HTTPS_BAR", etc
    func upperSnakeCase() -> String {
        guard !self.isEmpty else {
            return self
        }

        var result: String = ""
        result.append(self[self.startIndex].uppercased())

        let indicesWithoutTheFirstOne = self.indices.dropFirst()

        for index in indicesWithoutTheFirstOne {
            let currentCharacter = self[index]
            if currentCharacter.isUppercase {
                let nextIndex = self.index(after: index)
                if nextIndex != endIndex, !self[nextIndex].isUppercase, self[nextIndex] != "_" {
                    result.append("_")
                }
                else if index > startIndex {
                    let previousIndex = self.index(before: index)
                    if !self[previousIndex].isUppercase, self[previousIndex] != "_" {
                        result.append("_")
                    }
                }
                result.append(currentCharacter)
            }
            else {
                result.append(currentCharacter.uppercased())
            }
        }

        return result
    }

    /// "fooBar" becomes "FooBar"
    func capitalizedAsCamelCase() -> String {
        let firstCharacter = self.first!
        let capitalizedFirstCharacter = String(firstCharacter).uppercased()
        return String(capitalizedFirstCharacter + self.dropFirst())
    }

    /// Turns all "\\n" (backslash + 'n') into "\n" (newline), "\\t" (backslash + 't') into "\t"
    /// (tab), and "\\\\" (backslash + backslash) into "\\" (backslash).
    var removingBackslashEscapes: String {
        var result = ""
        var isEscaping = false

        for character in self {
            if !isEscaping {
                if character == "\\" {
                    isEscaping = true
                }
                else {
                    result.append(character)
                }
            }
            else {
                switch character {
                case "\\":
                    result.append("\\")
                case "n":
                    result.append("\n")
                case "t":
                    result.append("\t")
                default:
                    result.append(character)
                    isEscaping = false
                }

                isEscaping = false
            }
        }

        return result
    }

    /// Removes whitespaces from the beggining and the end of the string.
    func trimmingWhitespaces() -> String {
        var firstValidCharacterIndex: String.Index?
        var lastValidCharacterIndex = self.startIndex

        for index in self.indices {
            let character = self[index]
            if character != " " {
                lastValidCharacterIndex = index
                if firstValidCharacterIndex == nil {
                    firstValidCharacterIndex = index
                }
            }
        }

        guard let resultStartIndex = firstValidCharacterIndex else {
            return ""
        }
        let resultEndIndex = self.index(after: lastValidCharacterIndex)

        return String(self[resultStartIndex..<resultEndIndex])
    }
}

//
extension Character {
    var isNumber: Bool {
        return self == "0" ||
            self == "1" ||
            self == "2" ||
            self == "3" ||
            self == "4" ||
            self == "5" ||
            self == "6" ||
            self == "7" ||
            self == "8" ||
            self == "9"
    }

    var isUppercase: Bool {
        return self == "A" ||
            self == "B" ||
            self == "C" ||
            self == "D" ||
            self == "E" ||
            self == "F" ||
            self == "G" ||
            self == "H" ||
            self == "I" ||
            self == "J" ||
            self == "K" ||
            self == "L" ||
            self == "M" ||
            self == "N" ||
            self == "O" ||
            self == "P" ||
            self == "Q" ||
            self == "R" ||
            self == "S" ||
            self == "T" ||
            self == "U" ||
            self == "V" ||
            self == "W" ||
            self == "X" ||
            self == "Y" ||
            self == "Z"
    }
}

//
extension List where Element == String {
    // Turns ["a", "b", "c"] into "a, b and c", optionally adding double quotes to each element
    func readableList(withQuotes: Bool = false) -> String {
        if withQuotes {
            return self.map { "\"\($0)\"" }.readableList()
        }

        if self.isEmpty {
            return ""
        }
        else if self.count == 1 {
            return "\(self[0])"
        }

        let prefix = self.dropLast().joined(separator: ", ")
        let suffix = " and \(self.last!)"

        return prefix + suffix
    }
}

//
extension List {
    /// Returns nil if index is out of bounds.
    subscript (safe index: Int) -> Element? {
        return getSafe(index)
    }

    /// Returns nil if index is out of bounds.
    func getSafe(_ index: Int) -> Element? {
        if index >= 0 && index < count {
            return self[index]
        }
        else {
            return nil
        }
    }

    var secondToLast: Element? {
        return self.dropLast().last
    }

    /// Returns the same array, but with the first element moved to the end.
    func rotated() -> List<Element> {
        guard let first = self.first else {
            return self
        }

        var newArray: MutableList<Element> = []
        newArray.reserveCapacity(self.count)
        newArray.append(contentsOf: self.dropFirst())
        newArray.append(first)

        return newArray
    }

    /// Groups the array's elements into a dictionary according to the keys provided by the given
    /// closure, forming a sort of histogram.
    func group<Key>(by getKey: (Element) -> Key)
        -> MutableMap<Key, MutableList<Element>>
    {
        let result: MutableMap<Key, MutableList<Element>> = [:]
        for element in self {
            let key = getKey(element)
            let array = result[key] ?? []
            array.append(element)
            result[key] = array
        }
        return result
    }

    /// Separates the list in two. The first contains all elements that satisfy the given predicate,
    /// and the second contains all elements that don't. The separation is stable.
    func separate(_ predicate: (Element) -> Bool) -> (MutableList<Element>, MutableList<Element>) {
        let first: MutableList<Element> = []
        let second: MutableList<Element> = []
        for element in self {
            if predicate(element) {
                first.append(element)
            }
            else {
                second.append(element)
            }
        }

        return (first, second)
    }
}

extension List where Element: Equatable {
    /// Removes duplicated items from the array, keeping the first unique items. Returns a copy of
    /// the array with only unique items in it. O(n^2).
    func removingDuplicates() -> MutableList<Element> {
        let result: MutableList<Element> = []

        for i in self.indices {
            let consideredDeclaration = self[i]

            var hasDuplicate = false

            var j = i - 1
            while j >= 0 {
                let possibleDuplicate = self[j]

                if possibleDuplicate == consideredDeclaration {
                    hasDuplicate = true
                    break
                }

                j -= 1
            }

            if !hasDuplicate {
                result.append(consideredDeclaration)
            }
        }

        return result
    }
}

extension RandomAccessCollection where Element: Equatable {
    /// Checks if a collection contains the elements of another one, in the same order.
    /// If the given collection is empty, returns `true`.
    /// This is `O(self.count)`.
    func contains<C: Collection>(collection: C) -> Bool where C.Element == Element {
        guard !collection.isEmpty else {
            return true
        }

        guard self.count >= collection.count else {
            return false
        }

        var collectionIndex = collection.startIndex
        for index in self.indices {
            if self[index] == collection[collectionIndex] {
                collection.formIndex(after: &collectionIndex)
                if collectionIndex == collection.endIndex {
                    return true
                }
            }
            else {
                collectionIndex = collection.startIndex
            }
        }

        return false
    }
}

extension MutableList where Element: Equatable {
    /// Removes the given element, if it is in the list. Returns `true` if the element was present,
    /// `false` otherwise.
    @discardableResult
    func remove(_ element: Element) -> Bool {
        if let index = self.firstIndex(of: element) {
            self.array.remove(at: index)
            return true
        }
        else {
            return false
        }
    }
}

class SortedList<Element>: List<Element> {
    init(_ array: [Element], sortedBy closure: (Element, Element) throws -> Bool) rethrows {
        let sortedArray = try array.sorted(by: closure)
        super.init(sortedArray)
    }

    init(_ list: List<Element>, sortedBy closure: (Element, Element) throws -> Bool) rethrows {
        let sortedArray = try list.array.sorted(by: closure)
        super.init(sortedArray)
    }

    public required init(arrayLiteral elements: Element...) {
        fatalError("Sorted Array can't be initialized by a literal array. " +
            "Use init(_: sortedBy:) or init(of:) instead.")
    }

    /// Search for an element using the given `predicate` with a binary search.
    /// The `predicate` should return `.orderedAscending` if the searched element is larger than the
    /// given element, `.orderedDescending` if the contrary is true, and `.orderedSame` if the given
    /// element is the searched element.
    func search(predicate: (Element) -> ComparisonResult) -> Element? {
        var left = 0
        var right = array.count - 1
        while left <= right {
            let middle = (left + right) / 2
            let comparison = predicate(array[middle])
            switch comparison {
            case .orderedAscending:
                left = middle + 1
            case .orderedDescending:
                right = middle - 1
            case .orderedSame:
                return array[middle]
            }
        }

        return nil
    }
}

extension SortedList where Element: Comparable {
    convenience init(of array: [Element]) {
        self.init(array, sortedBy: <)
    }

    func search(for element: Element) -> Element? {
        var left = 0
        var right = array.count - 1
        while left <= right {
            let middle = (left + right) / 2

            if array[middle] < element {
                left = middle + 1
            }
            else if array[middle] > element {
                right = middle - 1
            }
            else {
                return array[middle]
            }
        }

        return nil
    }
}

//
extension PrintableTree {
    static func ofStrings(_ description: String, _ subtrees: List<String>)
        -> PrintableAsTree?
    {
        let newSubtrees = subtrees.map { string -> PrintableAsTree? in PrintableTree(string) }
        return PrintableTree.initOrNil(description, newSubtrees)
    }
}

extension Array {
	subscript (safe safeIndex: Int) -> Element? {
		if safeIndex > 0, safeIndex < self.count {
			return self[safeIndex]
		}
		else {
			return nil
		}
	}
}

infix operator !!: NilCoalescingPrecedence
extension Optional {
	static func !! (left: Wrapped?, right: String) -> Wrapped {
		guard let left = left else {
			fatalError(right)
		}
		return left
	}
}

extension String {
	func removingWhitespace() -> String {
		return self.replacingOccurrences(of: " ", with: "")
	}

	func hashCode() -> Int {
		var hash = 0
		if self.isEmpty {
			return hash
		}
		for char in self {
			let charValue: UInt8 = char.asciiValue ?? 1
			let intValue: Int = Int(exactly: charValue)!
			hash += intValue
		}
		return hash
	}
}
