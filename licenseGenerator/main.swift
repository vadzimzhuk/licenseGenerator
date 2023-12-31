//
//  licenseGenerator
//

import Foundation

let arguments = CommandLine.arguments
guard let workspaceIndex = arguments.firstIndex(of: "-w"),
      let workspacePath = arguments[safe: workspaceIndex + 1] else { print("Workspace path is missing. Specify -w."); exit(0) }

guard let outputIndex = arguments.firstIndex(of: "-o"),
      let outputPath = arguments[safe: outputIndex + 1] else { print("Output path is missing. Specify -o."); exit(0) }

let fileManager = FileManager.default
let workspaceURL = URL(fileURLWithPath: workspacePath.expandingTildeInPath)

if !fileManager.fileExists(atPath: workspaceURL.path) {
    print("xcworkspace not found at \(workspaceURL)")
    exit(0)
}

let packageURL = workspaceURL.appendingPathComponent("xcshareddata/swiftpm/Package.resolved")

if !fileManager.fileExists(atPath: packageURL.path) {
    print("Package.resolved not found at \(packageURL)")
    exit(0)
}

let resolvedPackagesData = try Data(contentsOf: packageURL)
let resolvedPackagesObject = try JSONSerialization.jsonObject(with: resolvedPackagesData, options: .allowFragments)

guard let packages = resolvedPackagesObject as? [String: Any] else { print("Invalid package format"); exit(0) }
guard let pins = packages["pins"] as? [[String: Any]] else { print("Invalid pins format"); exit(0) }

let projectsURL = Xcode.derivedDataURL

func projectsInfo(at url: URL) throws -> [Xcode.Project] {
    try fileManager
        .contentsOfDirectory(at: url, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
        .map { $0.appendingPathComponent("info.plist") }
        .compactMap {
            guard let info = NSDictionary(contentsOf: $0) as? [String: Any] else { return nil }
            return Xcode.Project(url: $0, info: info)
    }
}

let projects = try projectsInfo(at: projectsURL)

guard let currentProject = (projects.first { $0.workspacePath == workspacePath.expandingTildeInPath }) else { print("Derived data missing for workspace"); exit(0) }

let checkouts = currentProject.url
    .deletingLastPathComponent()
    .appendingPathComponent("SourcePackages/checkouts")

let checkedDependencies = try fileManager.contentsOfDirectory(at: checkouts, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)

let licences: [Xcode.Project.License] = checkedDependencies.compactMap {
    let licenseURL = $0.appendingPathComponent("LICENSE")
    if fileManager.fileExists(atPath: licenseURL.path) {
        return Xcode.Project.License(url: licenseURL, name: $0.lastPathComponent)
    }
    
    let licenseURLs = $0.appendingPathComponent("License")
    if fileManager.fileExists(atPath: licenseURLs.path) {
        return Xcode.Project.License(url: licenseURLs, name: $0.lastPathComponent)
    }
    
    let licenseTXTURL = $0.appendingPathComponent("LICENSE.txt")
    if fileManager.fileExists(atPath: licenseTXTURL.path) {
        return Xcode.Project.License(url: licenseTXTURL, name: $0.lastPathComponent)
    }
    
    let licenseURLmd = $0.appendingPathComponent("LICENSE.md")
    if fileManager.fileExists(atPath: licenseURLmd.path) {
        return Xcode.Project.License(url: licenseURLmd, name: $0.lastPathComponent)
    }
    
    return nil
}

let plistEntries = try licences.map { try $0.makeRepresentation() }

let data = try PropertyListSerialization.data(fromPropertyList: plistEntries, format: .xml, options: .zero)

var isdirectory : ObjCBool = true

switch (fileManager.fileExists(atPath: outputPath.expandingTildeInPath, isDirectory: &isdirectory), isdirectory.boolValue) {
case (false, _):
    print("No such file or directory \(outputPath.expandingTildeInPath)")
    exit(0)
case (true, false):
    // write into the file
    try data.write(to: URL(fileURLWithPath: outputPath.expandingTildeInPath))
    print("Licenses have been saved to \(outputPath)")
case (true, true):
    let newPath = outputPath.expandingTildeInPath.appendingPathComponent("Credits.plist")
    fileManager.createFile(atPath: newPath, contents: data)
    print("Licenses have been saved to \(newPath)")
}

