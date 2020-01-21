import Foundation
import XcodeProjectCore

func usage() {
    print("""
Usage: mxpt [subcommand] [options | --project PROJECT_PATH, --from SOURCE_TARGET_NAME --to DESTINATION_TARGET_NAME, --extension=.swift, --ignoreFileNames=AppDelegate.swift,main.swift]

mxpt help       Print usage mxpt
mxpt merge      Execute merge from source target to destination target.
""")
}

func extractArgument(key: String) -> String? {
    let indices = ProcessInfo.processInfo.arguments[1...].indices
    for index in indices {
        let optionName = ProcessInfo.processInfo.arguments[index]
        if optionName == key {
            return ProcessInfo.processInfo.arguments[index + 1]
        }
    }
    return nil
}

func buildIgnoreFileList() -> [String] {
    guard let names = extractArgument(key: "ignoreFileNames") else {
        return []
    }
    return names.split(separator: ",").map { String($0) }
}

func main() {
    let subcommand = ProcessInfo.processInfo.arguments[1]
    switch subcommand {
    case "help":
        return usage()
    case "merge":
        break
    case _:
        fatalError("Could not allow option for \(subcommand). See `$ mxpt help`")
    }
    
    guard let xcodeProjectUrl = ProcessInfo.processInfo.environment["MERGED_XCODE_PROJECT_TARGET_PATH"] ?? extractArgument(key: "--project") else {
        fatalError("Required option for --project. See `$ mxpt help`")
    }
    do {
        let project = try XcodeProject(
            xcodeprojectURL: URL(string: "file://" + xcodeProjectUrl)!
        )

        guard let sourceTargetName = extractArgument(key: "--from") else {
            fatalError("Required option for --from. See `$ mxpt help`")
        }
        guard let destinationTargetName = extractArgument(key: "--to") else{
            fatalError("Required option for --to. See `$ mxpt help`")
        }
        guard let sourceTarget = project.targets.first(where: { $0.name == sourceTargetName }) else {
            fatalError("Can not find \(sourceTargetName)")
        }
        guard let destinationTarget = project.targets.first(where: { $0.name == destinationTargetName }) else {
            fatalError("Can not find \(destinationTargetName)")
        }
        
        
        let sourceFiles = sourceTarget.context.fileRefs
        let destinationFiles = destinationTarget.context.fileRefs
        
        func filePathOrName(fileRef: PBX.FileReference) -> String {
            return fileRef.path ?? fileRef.name!
        }
        let fileExtension = extractArgument(key: "extension") ?? ".swift"
        let ignoreFiles = buildIgnoreFileList()
        sourceFiles.forEach { sourceFile in
            if destinationFiles.contains(where: { $0.id == sourceFile.id }) {
                return
            }
            if !destinationFiles.contains(where: { filePathOrName(fileRef: $0).hasSuffix(fileExtension) }) {
                return
            }
            if destinationFiles.contains(where: { ignoreFiles.contains(filePathOrName(fileRef: $0)) }) {
                return
            }
            project.appendFile(path: filePathOrName(fileRef: sourceFile), targetName: destinationTargetName)
        }
        try project.write()
    } catch {
        fatalError(error.localizedDescription)
    }
}

main()
