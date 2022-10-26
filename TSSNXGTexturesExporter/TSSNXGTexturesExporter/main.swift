
import Foundation

guard CommandLine.arguments.count > 2 else {
	fatalError("Please provide an input file path and an output folder path.")
}

let inputFilePath = CommandLine.arguments[1]
let outputFilePath = CommandLine.arguments[2].hasSuffix("/") ?
	CommandLine.arguments[2] :
	CommandLine.arguments[2] + "/"

let fileContents = try Data(contentsOf: URL(fileURLWithPath: inputFilePath))

// -------------------------------------------------------------------------------------------------
// Find the DDS data
let ddsStart = "DDS |"

var ddsStartIndices = [Int]()
for index in fileContents.indices.dropLast(ddsStart.count) {
	if let maybeStringStart =
		String(data: fileContents[index..<(index + ddsStart.count)], encoding: .utf8),
	   maybeStringStart == ddsStart
	{
		ddsStartIndices.append(index)
	}
}

guard ddsStartIndices.count >= 1 else {
	fatalError("No DDS data found")
}

// -------------------------------------------------------------------------------------------------
// Get the output file names

// Example file path:
// "lego_models_extended/lego_charactertools/lego_characters_images_nut/super_character_texture/template/lego_white255.nut"

// Find the occurrences of ".nut"
let headerData = fileContents[..<ddsStartIndices[0]]

let nutExtension = ".nut"

var nutStartIndices = [Int]()
for index in fileContents.indices.dropLast(nutExtension.count) {
	if let maybeStringStart =
		String(data: fileContents[index..<(index + nutExtension.count)], encoding: .utf8),
	   maybeStringStart == nutExtension
	{
		nutStartIndices.append(index)
	}
}

var fileNames = [String]()
// Find the first occurence of a slash before the ".nut"
for nutStartIndex in nutStartIndices {
	for slashIndex in (0..<nutStartIndex).reversed() {
		if let maybeFileName =
			String(data: fileContents[slashIndex..<nutStartIndex], encoding: .utf8)
		{
			if maybeFileName.first! == "/" {
				let fileName = String(maybeFileName.dropFirst())
				fileNames.append(fileName)
				break
			}
		}
		else {
			// If we got to the point where this can't be turned into a string anymore (probably
			// because an unknown character was included in the substring), give up on this file
			// name and move on to the next.
			break
		}
	}
}

if fileNames.count != ddsStartIndices.count {
	print("Unable to get file names, printing DDS files by number.")
	fileNames = ddsStartIndices.indices.map { String($0) }
}

// -------------------------------------------------------------------------------------------------
// Print the DDS data to the files

// Append the endIndex so we can use it in the for loop below
ddsStartIndices.append(fileContents.endIndex)


for (fileName, (startIndex, endIndex)) in
		zip(fileNames, zip(ddsStartIndices, ddsStartIndices.dropFirst()))
{
	let dataSection = fileContents[startIndex..<endIndex]
	let fileURL = URL(fileURLWithPath: "\(outputFilePath)\(fileName).dds")

	try dataSection.write(to: fileURL)
}
