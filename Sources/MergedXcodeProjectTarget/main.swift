import Foundation
import XcodeProjectCore

func usage() {
    print("""
Usage: mxpt [subcommand] [options | --project PROJECT_PATH, --from SOURCE_TARGET_NAME --to DESTINATION_TARGET_NAME]

mxpt help       Print usage mxpt
mxpt merge      Execute merge from source target to destination target.
""")
}

func extractArgument(key: String) -> String {
    let indices = ProcessInfo.processInfo.arguments[1...].indices
    for index in indices {
        let optionName = ProcessInfo.processInfo.arguments[index]
        if optionName == key {
            return ProcessInfo.processInfo.arguments[index + 1]
        }
    }
    fatalError("Can not find option \(key)")
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
    
    let xcodeProjectUrl = ProcessInfo.processInfo.environment["MERGED_XCODE_PROJECT_TARGET_PATH"] ?? extractArgument(key: "--project")
    do {
        let project = try XcodeProject(
            xcodeprojectURL: URL(string: "file://" + xcodeProjectUrl)!
        )

        let sourceTargetName = extractArgument(key: "--from")
        let destinationTargetName = extractArgument(key: "--to")
        guard let sourceTarget = project.targets.first(where: { $0.name == sourceTargetName }) else {
                fatalError("Can not find \(sourceTargetName)")
        }
        guard let destinationTarget = project.targets.first(where: { $0.name == destinationTargetName }) else {
            fatalError("Can not find \(destinationTargetName)")
        }
        
        let sourceFiles = sourceTarget.buildPhases.flatMap { $0.files }
        let destinationFiles = destinationTarget.buildPhases.flatMap { $0.files }
        
        sourceFiles.forEach { sourceFile in
            if destinationFiles.contains(where: { $0.id == sourceFile.id }) {
                return
            }
            destinationTarget.appendToSourceBuildFile(fileName: sourceFile.fileRef.path ?? sourceFile.fileRef.name!)
        }
        try project.write()
    } catch {
        fatalError(error.localizedDescription)
    }
}

main()
