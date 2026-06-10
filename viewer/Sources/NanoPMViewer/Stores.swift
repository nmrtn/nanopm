import Foundation
import SwiftUI

/// Claude-Code-style recents list (PRD "The One UX Decision", Option A).
@MainActor
final class RecentsStore: ObservableObject {
    @Published private(set) var recents: [Project] = []
    private let defaultsKey = "recentProjectPaths"

    init() {
        let paths = UserDefaults.standard.stringArray(forKey: defaultsKey) ?? []
        recents = paths.map { Project(path: $0) }
    }

    func touch(_ project: Project) {
        recents.removeAll { $0.path == project.path }
        recents.insert(project, at: 0)
        recents = Array(recents.prefix(8))
        save()
    }

    func remove(_ project: Project) {
        recents.removeAll { $0.path == project.path }
        save()
    }

    private func save() {
        UserDefaults.standard.set(recents.map(\.path), forKey: defaultsKey)
    }
}

@MainActor
final class ArtifactStore: ObservableObject {
    enum State: Equatable {
        case loading
        case missingNanopm
        case loaded
        case error(String)
    }

    let project: Project
    @Published var state: State = .loading
    @Published var artifacts: [Artifact] = []
    @Published var competitors: [Competitor] = []
    /// Bumped on every refresh so open detail views re-read their file.
    @Published var generation = 0

    init(project: Project) {
        self.project = project
    }

    func refresh() async {
        if artifacts.isEmpty { state = .loading }
        let path = project.path
        do {
            let (result, foundCompetitors) = try await Task.detached(priority: .userInitiated) {
                (try ArtifactScanner.scan(projectPath: path),
                 ArtifactScanner.loadCompetitors(projectPath: path))
            }.value
            competitors = foundCompetitors
            switch result {
            case .missingNanopm:
                artifacts = []
                state = .missingNanopm
            case .found(let found):
                artifacts = found
                state = .loaded
            }
            generation += 1
        } catch {
            state = .error("\(error)")
        }
    }

    func content(of artifact: Artifact) async throws -> String {
        let file = project.nanopmPath + "/" + artifact.relativePath
        return try await ShellRunner.runAsync("cat \(ShellRunner.quote(file))")
    }
}
