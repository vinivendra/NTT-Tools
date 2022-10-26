//
//  main.swift
//  TSSFileListCSVReader
//
//  Created by Vinicius Vendramini on 30/09/22.
//

import Foundation

let file = try! String(contentsOfFile: CommandLine.arguments[1])

//"Time of Day","Process Name","PID","Operation","Path","Result","Detail"
//"2:15:16.1066011 PM","LEGOSTARWARSSKYWALKERSAGA_DX11.exe","8688","ReadFile","F:\Steam\steamapps\common\LEGO Star Wars - The Skywalker

let lines = file.split(separator: "\r\n").dropFirst()
let filePaths = lines.map { $0.split(separator: ",")[4] }
var uniquePaths = Set(filePaths)
let cleanPaths = uniquePaths.map {
	$0.split(separator: "\\") // Split path components
	  .drop(while: { $0 != "LEGO Star Wars - The Skywalker Saga" }).dropFirst() // Drop everything through the TSS folder
	  .joined(separator: "/") // Join components back into a string
	  .dropLast() // Drop the closing double quote
}

let pathsWithRightExtension: [Substring]

if CommandLine.arguments.count >= 3 {
    pathsWithRightExtension = cleanPaths.filter { $0.hasSuffix(CommandLine.arguments[2]) }
}
else {
    pathsWithRightExtension = cleanPaths
}

let orderedPaths = pathsWithRightExtension.sorted(by: <)

for path in orderedPaths {
	print(path)
}
