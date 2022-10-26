//
//  ViewController.swift
//  TSSNormalMapConverter
//
//  Created by Vinicius Vendramini on 15/05/22.
//

import Cocoa

class ViewController: NSViewController {

	@IBOutlet weak var greenDifference: NSImageView!
	@IBOutlet weak var blueDifference: NSImageView!
	@IBOutlet weak var redDifference: NSImageView!
	@IBOutlet weak var correctImage: NSImageView!
	@IBOutlet weak var rightImage: NSImageView!
	@IBOutlet weak var leftImage: NSImageView!
	override func viewDidLoad() {
		super.viewDidLoad()


		let imageName = "/Users/vini/Downloads/FINALIZERTILESET_WALLS_N_DX11.png"
//		let imageName = "/Users/vini/Downloads/sci_fi_derivative.jpg"

		let originalImage = NSImage(contentsOfFile: imageName)!
		leftImage.image = originalImage

		// Algorithm for the example at https://docs.knaldtech.com/doku.php?id=derivative_maps_knald
//		let dfdx = (color.redComponent * 2) - 1
//		let dfdy = (color.greenComponent * 2) - 1
//		let normalizedTangentNormal = normalize(-dfdx, -dfdy, 1.0)
//		let newRed = (normalizedTangentNormal.redComponent + 1) / 2
//		let newGreen = (normalizedTangentNormal.greenComponent + 1) / 2
//		let newBlue = (normalizedTangentNormal.blueComponent + 1) / 2
//		return NSColor(red: newRed, green: newGreen, blue: newBlue, alpha: 1.0)

		let image = changePixels(image: originalImage) { color, x, y in
			// Algorithm for TSS
			let dfdx = (color.redComponent * 2) - 1
			let dfdy = (color.greenComponent * 2) - 1
			let normalizedTangentNormal = normalize(dfdx, -dfdy, 1.0)
			let newRed = (normalizedTangentNormal.redComponent + 1) / 2
			let newGreen = (normalizedTangentNormal.greenComponent + 1) / 2
			let newBlue = (normalizedTangentNormal.blueComponent + 1) / 2
			return NSColor(
				red: newRed,
				green: newGreen,
				blue: newBlue,
				alpha: color.alphaComponent)
		}
		rightImage.image = image

		// Write the image to a file
		let data = image.tiffRepresentation!
		let imageRepresentation = NSBitmapImageRep(data: data)!
		let imageProprerties = [NSBitmapImageRep.PropertyKey.compressionFactor: 1.0]
		let outputData = imageRepresentation.representation(
			using: NSBitmapImageRep.FileType.png,
			properties: imageProprerties)
		try! outputData!.write(to: URL(fileURLWithPath: imageName.dropLast(4) + "_NM.png"))

//		let correctImageFile = NSImage(contentsOfFile: "/Users/vini/Downloads/sci_fi_normal.jpg")!
//		correctImage.image = correctImageFile
//
//		let rep = correctImageFile.representations.first(where: { $0 is NSBitmapImageRep })! as! NSBitmapImageRep
//
//		let redDifferenceImage = changePixels(image: image) { color, x, y in
//			let correctColor = rep.colorAt(x: x, y: y)!
//			return NSColor(
//				red: 0.5 + (color.redComponent - correctColor.redComponent),
//				green: 0.5 + (color.redComponent - correctColor.redComponent),
//				blue: 0.5 + (color.redComponent - correctColor.redComponent),
//				alpha: 1.0)
//		}
//		redDifference.image = redDifferenceImage
//
//		let greenDifferenceImage = changePixels(image: image) { color, x, y in
//			let correctColor = rep.colorAt(x: x, y: y)!
//			return NSColor(
//				red: 0.5 + (color.greenComponent - correctColor.greenComponent),
//				green: 0.5 + (color.greenComponent - correctColor.greenComponent),
//				blue: 0.5 + (color.greenComponent - correctColor.greenComponent),
//				alpha: 1.0)
//		}
//		greenDifference.image = greenDifferenceImage
//
//		let blueDifferenceImage = changePixels(image: image) { color, x, y in
//			let correctColor = rep.colorAt(x: x, y: y)!
//			return NSColor(
//				red: 0.5 + (color.blueComponent - correctColor.blueComponent),
//				green: 0.5 + (color.blueComponent - correctColor.blueComponent),
//				blue: 0.5 + (color.blueComponent - correctColor.blueComponent),
//				alpha: 1.0)
//		}
//		blueDifference.image = blueDifferenceImage
	}

	override var representedObject: Any? {
		didSet {
		// Update the view, if already loaded.
		}
	}
}

func normalize(_ doublex: CGFloat, _ doubley: CGFloat, _ doublez: CGFloat) -> NSColor {
	let length = sqrt(doublex*doublex + doubley*doubley + doublez*doublez)
	if length == 0 {
		return NSColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0)
	}
	let resultx = doublex / length
	let resulty = doubley / length
	let resultz = doublez / length
	return NSColor(red: resultx, green: resulty, blue: resultz, alpha: 1.0)
}

func updateImageData(_ image: NSImage) {
	// Dimensions - source image determines context size
	let imageSize = image.size
	let imageRect = NSMakeRect(0, 0, imageSize.width, imageSize.height)

	// Create a context to hold the image data
	let colorSpace = CGColorSpace(name: CGColorSpace.genericRGBLinear)!

	let context = CGContext(
		data: nil,
		width: Int(imageSize.width),
		height: Int(imageSize.height),
		bitsPerComponent: 8,
		bytesPerRow: 0,
		space: colorSpace,
		bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!

	// Wrap graphics context
	let graphicsContext = NSGraphicsContext(cgContext: context, flipped: false)

	// Make our bitmap context current and render the NSImage into it
	NSGraphicsContext.current = graphicsContext
	image.draw(in: imageRect)

	// Do stuff

//	let rep = image.representations.first(where: { $0 is NSBitmapImageRep })! as! NSBitmapImageRep
//	rep.colorAt(x: 0, y: 0)
//	for i in 1...100 {
//		for j in 0...100 {
//			rep.setColor(.blue, atX: i, y: j)
//		}
//	}

//	processBitmap(context)

//	let toSave = NSImage(size: imageSize)
//	toSave.lockFocus()
//	let newContext = graphicsContext.graphicsPort

//	[toSave unlockFocus];
//
//	NSBitmapImageRep *imgRep = [[toSave representations] objectAtIndex: 0];
//
//	NSData *data = [imgRep representationUsingType: NSPNGFileType properties: nil];
//
//	[data writeToFile: @"/path/to/file.png" atomically: NO];

	// Clean up
	NSGraphicsContext.current = nil
}

//func processBitmap(_ bitmap: CGContext) {
//	// NB: Assumes RGBA 8bpp
//	let width = bitmap.width
//	let height = bitmap.height
//
//	var pixel = bitmap.data!
//
//	for _ in 0..<height {
//		for _ in 0..<width {
//			let r = pixel.load(as: UInt8.self)
//			pixel += 1
//			let g = pixel.load(as: UInt8.self)
//			pixel += 1
//			let b = pixel.load(as: UInt8.self)
//			pixel += 1
//			let a = pixel.load(as: UInt8.self)
//			pixel += 1
//
//			print("\(r), \(g), \(b), \(a)")
//		}
//	}
//}

extension NSBitmapImageRep {
	func setColorNew(atX x: Int, y: Int, transform: ColorTransform) {
		guard let data = bitmapData else { return }

		let color = transform(self.colorAt(x: x, y: y)!, x, y).usingColorSpace(.deviceRGB)!

		let ptr = data + bytesPerRow * y + samplesPerPixel * x

		ptr[0] = UInt8(min(color.redComponent * 255, 255))
		ptr[1] = UInt8(min(color.greenComponent * 255, 255))
		ptr[2] = UInt8(min(color.blueComponent * 255, 255))

		if samplesPerPixel > 3 {
			ptr[3] = UInt8(min(color.alphaComponent * 255, 255))
		}
	}
}

typealias ColorTransform = (NSColor, Int, Int) -> NSColor

func changePixels(image: NSImage, transform: ColorTransform) -> NSImage {
	guard let imgData = image.tiffRepresentation,
		  let bitmap = NSBitmapImageRep(data: imgData)
	else { return image }

	var y = 0
	while y < bitmap.pixelsHigh {
		var x = 0
		while x < bitmap.pixelsWide {
			bitmap.setColorNew(atX: x, y: y, transform: transform)
			x += 1
		}
		y += 1
	}

	let newImage = NSImage(size: image.size)
	newImage.addRepresentation(bitmap)

	return newImage
}
