import Foundation

/// `NanoPMViewer --smoke /path/to/project` prints the scanned artifact list
/// and exits — lets the scanner logic be verified without the UI.
enum SmokeTest {
    static func runIfRequested() {
        let args = CommandLine.arguments
        guard let flag = args.firstIndex(of: "--smoke") else { return }
        guard args.count > flag + 1 else {
            print("usage: NanoPMViewer --smoke /path/to/project")
            exit(64)
        }
        let path = args[flag + 1]
        do {
            switch try ArtifactScanner.scan(projectPath: path) {
            case .missingNanopm:
                print("MISSING: \(path)/.nanopm does not exist")
                exit(2)
            case .found(let artifacts):
                for artifact in artifacts {
                    print("\(artifact.phase.rawValue)\t.nanopm/\(artifact.relativePath)")
                }
                print("TOTAL: \(artifacts.count)")
                exit(0)
            }
        } catch {
            print("SMOKE FAIL: \(error)")
            exit(1)
        }
    }
}
