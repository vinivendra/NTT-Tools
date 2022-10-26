import Foundation
import Algorithms

protocol Node: Codable {
    var type: String { get }

    /// Leftmost x value of the Node
    var x: Int { get }
    /// Topmost y value of the Node
    var y: Int { get }
    var width: Int { get }
    var height: Int { get }

    func asSVG() -> String
}

extension Node {
    var maxX: Int {
        return self.x + self.width
    }
    
    var maxY: Int {
        return self.y + self.height
    }
}

extension Node {
    func asJSON() throws -> String {
        if let aNode = self as? Text {
            return try String.init(data: JSONEncoder().encode(aNode), encoding: .utf8)!
        }
        else if let aNode = self as? Rectangle {
            return try String.init(data: JSONEncoder().encode(aNode), encoding: .utf8)!
        }
        else if let aNode = self as? Arrow {
            return try String.init(data: JSONEncoder().encode(aNode), encoding: .utf8)!
        }
        else {
            fatalError("Unknown node: \(self)")
        }
    }
}

struct Color: Codable {
    let r: Float
    let g: Float
    let b: Float

    static let darkText =                  Color(r: 27  / 255, g: 27  / 255, b: 27 / 255)
    static let subText =                   Color(r: 137 / 255, g: 137 / 255, b: 137 / 255)
    static let lightText =                 Color(r: 255 / 255, g: 255 / 255, b: 255 / 255)
    static let invalidText =               Color(r: 200 / 255, g: 40  / 255, b: 40  / 255)
    static let greyBackground =            Color(r: 194 / 255, g: 195 / 255, b: 203 / 255)
    static let sprintHightlightStroke =    Color(r: 236 / 255, g: 215 / 255, b: 29  / 255)
    static let blueBackground =            Color(r: 28  / 255, g: 63  / 255, b: 103 / 255)
    static let lightBackground =           Color(r: 241 / 255, g: 241 / 255, b: 241 / 255)
    static let arrowColor =                Color(r: 200 / 255, g: 200 / 255, b: 200 / 255)
    static let invalidArrowColor =         Color(r: 200 / 255, g: 40  / 255, b: 40  / 255)
    static let statusDoneColor =           Color(r: 99  / 255, g: 201 / 255, b: 97  / 255)
    static let statusReviewColor =         Color(r: 86  / 255, g: 164 / 255, b: 255 / 255)
    static let statusToDoColor =           Color(r: 223 / 255, g: 225 / 255, b: 230 / 255)
    static let statusBlockedColor =        Color(r: 255 / 255, g: 101 / 255, b: 91  / 255)

    /// Returns the color in hex form, e.g. `"FFFFFF"`
    var hexValue: String {
        let red1 = Int(r*16)
        let red1Remainder = r*16 - Float(red1)
        let red2 = Int(red1Remainder * 16)

        let green1 = Int(g*16)
        let green1Remainder = g*16 - Float(green1)
        let green2 = Int(green1Remainder * 16)

        let blue1 = Int(b*16)
        let blue1Remainder = b*16 - Float(blue1)
        let blue2 = Int(blue1Remainder * 16)

        return "\(red1.hexValue)\(red2.hexValue)\(green1.hexValue)\(green2.hexValue)\(blue1.hexValue)\(blue2.hexValue)"
    }
}

extension Int {
    var hexValue: String {
        switch self {
        case 0..<10: return String(self)
        case 10: return "A"
        case 11: return "B"
        case 12: return "C"
        case 13: return "D"
        case 14: return "E"
        default: return "F"
        }
    }
}

struct FontName: Codable {
    let family: String
    let style: String

    static let regularFont = FontName(family: "Roboto", style: "Regular")
    static let boldFont = FontName(family: "Roboto", style: "Bold")
}

struct Shadow: Codable {
    let alpha: Float
    let offset: Float
    let radius: Float
    let spread: Float
}

struct Text: Node {
    enum HorizontalAlignment: String, Codable {
        case LEFT
        case CENTER
        case RIGHT
    }

    enum VerticalAlignment: String, Codable {
        case TOP
        case CENTER
        case BOTTOM
    }

    private(set) var type: String = "Text"
    let x: Int
    let y: Int
    let height: Int
    let width: Int
    let string: String
    let horizontalAlignment: HorizontalAlignment
    let verticalAlignment: VerticalAlignment
    let size: Int
    let color: Color
    let fontName: FontName

    init(
        x: Int,
        y: Int,
        height: Int,
        width: Int,
        string: String,
        horizontalAlignment: HorizontalAlignment,
        verticalAlignment: VerticalAlignment,
        size: Int,
        color: Color,
        fontName: FontName)
    {
        self.x = x
        self.y = y
        self.height = height
        self.width = width
        self.string = string
        self.horizontalAlignment = horizontalAlignment
        self.verticalAlignment = verticalAlignment
        self.size = size
        self.color = color
        self.fontName = fontName
    }

    /// Based on https://developer.mozilla.org/en-US/docs/Web/SVG/Element/text
    func asSVG() -> String {
        let x: Int
        let anchor: String
        switch horizontalAlignment {
        case .LEFT:
            x = self.x
            anchor = "left"
        case .CENTER:
            x = self.x + self.width / 2
            anchor = "middle"
        case .RIGHT:
            x = self.x + self.width
            anchor = "right"
        }

        let svgText = wrappedText()

        // SVG vertical anchor is at the bottom of the text, but there's no text width, only the font size
        let y = self.y + self.size

        return "<text x=\"\(x)\" y=\"\(y)\" font-size=\"\(self.size)\" text-anchor=\"\(anchor)\" fill=\"#\(color.hexValue)\">\(svgText)</text>\n"
    }

    func wrappedText() -> String {
        let characterAspectRatio: Double = 0.5
        let characterWidth = Int(Double(size) * characterAspectRatio)
        var result = ""
        var currentWord = ""
        var currentLineSize = 0

        let string = self.string + " "

        for character in string {
            currentLineSize += 1

            switch character {
            case " ", "\n":
                // If this word overflows the line
                if (currentLineSize + 1 + currentWord.count) * characterWidth > width {
                    // If the new word is too big to put in a new line
                    if currentWord.count * characterWidth > width {
                        if !result.isEmpty {
                            result += "\n"
                        }

                        // Break the word into one piece per line
                        let lineWidthInChars = width / characterWidth
                        let wordChunks = currentWord.chunks(ofCount: lineWidthInChars)
                        let wordString = wordChunks.joined(separator: "\n")

                        result += wordString + String(character)
                        currentLineSize = Array(wordChunks).last!.count + 1
                        currentWord = ""
                    }
                    // If the new word fits in a new line
                    else {
                        result += "\n" + currentWord + String(character)
                        currentLineSize = currentWord.count + 1
                        currentWord = ""
                    }
                }
                // If this word fits in the line
                else {
                    result += currentWord + String(character)
                    currentLineSize += currentWord.count + 1
                    currentWord = ""
                }
            default:
                currentWord += String(character)
            }

        }

        return result
    }
}

struct Rectangle: Node {
    private(set) var type: String = "Rectangle"
    let x: Int
    let y: Int
    let height: Int
    let width: Int
    let color: Color
    let shadow: Shadow?
    let strokeColor: Color?
    let strokeWeight: Int?

    init(
        x: Int,
        y: Int,
        height: Int,
        width: Int,
        color: Color,
        shadow: Shadow? = nil,
        strokeColor: Color? = nil,
        strokeWeight: Int? = nil)
    {
        self.x = x
        self.y = y
        self.height = height
        self.width = width
        self.color = color
        self.shadow = shadow
        self.strokeColor = strokeColor
        self.strokeWeight = strokeWeight
    }

    /// Based on https://developer.mozilla.org/en-US/docs/Web/SVG/Element/rect
    func asSVG() -> String {
        return "<rect x=\"\(self.x)\" y=\"\(self.y)\" width=\"\(self.width)\" height=\"\(self.height)\" fill=\"#\(self.color.hexValue)\"/>"
    }
}

struct Arrow: Node {
    private(set) var type: String = "Arrow"
    let startX: Int
    let startY: Int
    let endX: Int
    let endY: Int
    let color: Color
    let hasArrow: Bool
    let isStraight: Bool

    /// Based on https://developer.mozilla.org/en-US/docs/Web/SVG/Element/rect
    func asSVG() -> String {
//        return "<rect x=\"\(self.x)\" y=\"\(self.y)\" width=\"\(self.width)\" height=\"\(self.height)\" color=\"#\(self.color.hexValue)\"/>"
        return ""
    }

    /// Leftmost x value of the Node
    var x: Int {
        return min(startX, endX)
    }
    /// Topmost y value of the Node
    var y: Int {
        return min(startY, endY)
    }
    var width: Int {
        return x + abs(startX - endX)
    }
    var height: Int {
        return y + abs(startY - endY)
    }
}
