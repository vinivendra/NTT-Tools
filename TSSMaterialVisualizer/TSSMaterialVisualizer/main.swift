import Foundation

guard CommandLine.arguments.count > 1,
	  let filePath = CommandLine.arguments.last else
{
	fatalError("Please provide a file path")
}

let fileContents = try Data(contentsOf: URL(fileURLWithPath: filePath))

let xmlStart = "<materialInstance"
let xmlStartCount = xmlStart.count
var startIndex: Int?
let xmlEnd = "materialInstance>"
let xmlEndCount = xmlEnd.count
var endIndex: Int?
for index in fileContents.indices.dropLast(max(xmlStartCount, xmlEndCount)) {
	if startIndex == nil,
	   let maybeStringStart =
		String(data: fileContents[index...(index + xmlStartCount - 1)], encoding: .utf8),
	   maybeStringStart == xmlStart
	{
		startIndex = index
	}
	if startIndex != nil,
	   let maybeStringEnd =
		String(data: fileContents[index...(index + xmlEndCount - 1)], encoding: .utf8),
	   maybeStringEnd == xmlEnd
	{
		endIndex = index + xmlEndCount - 1
	}
}

guard let startIndex = startIndex,
	  let endIndex = endIndex,
	  let xmlInput = String(data: fileContents[startIndex...endIndex], encoding: .utf8) else
{
	fatalError("Unable to find XML data in file")
}

struct Edge {
	let inputParameter: String
	let outputParameter: String
	let outputNode: MaterialNode
}

class MaterialNode: PrintableAsTree {
	let id: Int
    let name: String
	var parameters: [(key: String, value: String)]
	var outputs: [Edge]
	var availableInputs: [String]
    var x: Int
    var y: Int

	static var idCounter = 0

    init(name: String, x: Int, y: Int) {
        self.name = name
        self.parameters = []
        self.outputs = []
		self.availableInputs = []
        self.x = x
        self.y = y
		self.id = MaterialNode.idCounter
		MaterialNode.idCounter += 1
    }
	
	var treeDescription: String {
		return name
	}
	
	var printableSubtrees: List<PrintableAsTree?> {
		let parameterTrees: List<PrintableAsTree?> =
			List(parameters
				.map { PrintableTree("\($0.key) -> \($0.value)") })
		let outputTrees: List<PrintableAsTree?> =
			List(outputs
				.map { PrintableTree("\($0.inputParameter) -> (\($0.outputParameter) \($0.outputNode.name)") })

		return [PrintableTree(name, [
			PrintableTree("Coordinates: (\(x), \(y))"),
			PrintableTree("Parameters", parameterTrees),
			PrintableTree("Inputs", outputTrees),
			PrintableTree("Output", outputTrees)
		])]
	}
}

class Parser {
    func parse(string: String) -> [MaterialNode] {
        let lines = string.split(separator: "\r\n").map(String.init)
        
        var result = [MaterialNode]()
        var currentNode: MaterialNode?
        
        for line in lines {
            let (name, parameters) = parseNode(line)
            
            if name == "shaderNodeInstance" {
                let newNode = MaterialNode(
                    name: parameters["name"]!,
                    x: Int(parameters["uiPosX"]!)!,
                    y: Int(parameters["uiPosY"]!)!)
                currentNode = newNode
                result.append(newNode)
            } else if name == "userParam" || name == "userValue" {
                let key = parameters["name"]!
                let value = parameters["value"]!
				currentNode?.parameters.append((key, value))
            }
            else if name == "link" {
                let nodeFrom = parameters["nodeFrom"]!
                let socketFrom = parameters["socketFrom"]!
                let nodeTo = parameters["nodeTo"]!
                let socketTo = parameters["socketTo"]!
                
                let originNode = result.first(where: { $0.name == nodeFrom })!
                let destinationNode = result.first(where: { $0.name == nodeTo })!
                
				originNode.outputs.append(Edge(
					inputParameter: socketFrom,
					outputParameter: socketTo,
					outputNode: destinationNode))

				if !destinationNode.availableInputs.contains(socketTo) {
					destinationNode.availableInputs.append(socketTo)
				}
            }
        }
        
        return result
    }
    
    private func parseNode(_ string: String) -> (name: String, parameters: [String: String]) {
        let cleanString = String(string.drop(while: { $0 != "<" }).dropFirst().dropLast())
        
        // Get the name
        let name = String(cleanString.prefix(while: { $0 != " " }))
        // Remove the name from the string
        let attributesString = String(cleanString.dropFirst(name.count + 1))
        
        // Separate the attributes
        let attributes = attributesString.split(withStringSeparator: "\" ")
        
        var parameters = [String: String]()
        for attribute in attributes {
            let key = String(attribute.prefix(while: { $0 != "="}))
            let value = String(attribute.dropFirst(key.count + 2).prefix(while: { $0 != "\"" }))
            parameters[key] = value
        }
        
        return (name: name, parameters: parameters)
    }
}

// Parse XML into nodes
let parser = Parser()
let allNodes = parser.parse(string: xmlInput)
//allNodes.forEach { $0.prettyPrint() }

// Make all nodes have positivo coordinates for SVG
var oldMinX = allNodes.min { nodeA, nodeB in nodeB.x > nodeA.x }!.x - 150
var oldMinY = allNodes.min { nodeA, nodeB in nodeB.y > nodeA.y }!.y - 150
if oldMinX < 0 {
	for node in allNodes {
		node.x -= oldMinX
	}
}
if oldMinY < 0 {
	for node in allNodes {
		node.y -= oldMinY
	}
}

// Get the size of the SVG
var maxX = allNodes.max { nodeA, nodeB in nodeB.x > nodeA.x }!.x + 150
var maxY = allNodes.max { nodeA, nodeB in nodeB.y > nodeA.y }!.y + 150

let width = maxX
let height = maxY

// Create the SVG
var svg = """
<svg version="1.1"
	width="\(width)" height="\(height)"
	xmlns="http://www.w3.org/2000/svg">

	<rect width=\"100%\" height=\"100%\" fill=\"#FAFAFA\" />

"""


let nodeWidth = 100
for node in allNodes {
	// Render edges (behind everything else so they don't get in the way)
	for (index, edge) in node.outputs.enumerated() {
		let outputNode = allNodes.first(where: { $0.id == edge.outputNode.id })!
		let outputParameterIndex = outputNode.availableInputs.firstIndex(of: edge.outputParameter)!

		let textHeight = 8
		let textMargin = 4
		let topEdgeMargin = 20
		let interEdgeMargin = 20
		let curviness = 100
		let xStart = node.x + nodeWidth
		let yStart = node.y + topEdgeMargin + index * interEdgeMargin
		let xEnd = outputNode.x
		let yEnd = outputNode.y + topEdgeMargin + outputParameterIndex * interEdgeMargin
		svg += """
			<path d="M\(xStart),\(yStart) C\(xStart + curviness),\(yStart)  \(xEnd - curviness),\(yEnd)  \(xEnd),\(yEnd)"
					fill="none" stroke="#\(Color.arrowColor.hexValue)" stroke-width="2px" />\n
		"""
		svg += "\t\t<text x=\"\(xStart + textMargin)\" y=\"\(yStart - textMargin)\" font-size=\"\(textHeight)\" text-anchor=\"left\" fill=\"#\(Color.darkText.hexValue)\">\(edge.inputParameter)</text>\n"
		svg += "\t\t<text x=\"\(xEnd - textMargin)\" y=\"\(yEnd - textMargin)\" font-size=\"\(textHeight)\" text-anchor=\"end\" fill=\"#\(Color.darkText.hexValue)\">\(edge.outputParameter)</text>\n"
	}

	// Render the rectangle background
    svg += "\t<rect x=\"\(node.x)\" y=\"\(node.y)\" width=\"\(nodeWidth)\" height=\"\(100)\" fill=\"#\(Color.greyBackground.hexValue)\"/>\n"

	// Render the node title
	let titleHeight = 10
	let margin = 4
	svg += "\t\t<text x=\"\(node.x + margin)\" y=\"\(node.y + titleHeight + margin)\" font-size=\"\(titleHeight)\" text-anchor=\"left\" fill=\"#\(Color.darkText.hexValue)\">\(node.name)</text>\n"

	// Render the parameters
	var index = 0
	for parameter in node.parameters {
		let textHeight = 8
		let textMargin = 2
		let string = "\(parameter.key): \(parameter.value)"
		let stringLines = string.chunks(ofCount: 20)
		for line in stringLines {
			let xPosition = node.x + margin
			let yPosition = node.y + titleHeight + margin + titleHeight + index * (textHeight + textMargin)
			svg += "\t\t<text x=\"\(xPosition)\" y=\"\(yPosition)\" font-size=\"\(textHeight)\" text-anchor=\"left\" fill=\"#\(Color.darkText.hexValue)\">\(line)</text>\n"
			index += 1
		}
	}

	svg += "\n"
}

svg += """

</svg>
"""

//<circle cx="150" cy="100" r="80" fill="green" />
//<text x="150" y="125" font-size="60" text-anchor="middle" fill="white">SVG</text>

let outputPath = filePath
	.split(separator: ".").dropLast().joined() // Drop ".MATERIAL"
	+ ".svg" // Change the extension

print("Output file path:")
print(outputPath)

try svg.write(
	to: URL(fileURLWithPath: outputPath),
	atomically: true,
	encoding: .utf8)
