import Foundation

extension String {
	// Result should have at most maxSplits + 1 elements.
	func split(
		withStringSeparator separator: String,
		maxSplits: Int = Int.max,
		omittingEmptySubsequences: Bool = true) -> [String]
	{
		var result: [String] = []

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
	func occurrences(of searchedSubstring: String) -> [Range<String.Index>] {
		var result: [Range<String.Index>] = []

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
}
