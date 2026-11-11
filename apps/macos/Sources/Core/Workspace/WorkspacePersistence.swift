
import Foundation

// MARK: - Workspace Persistence Protocol

protocol WorkspacePersistence {
    func load() throws -> WorkspaceDocument
    func save(_ document: WorkspaceDocument) throws
}

// MARK: - Persistence Errors

enum WorkspacePersistenceError: LocalizedError {
    case backupFailed(underlying: Error)
    case fileOperationFailed(underlying: Error)

    var errorDescription: String? {
        switch self {
        case .backupFailed(let error):
            return "Failed to create workspace backup: \(error.localizedDescription)"

        case .fileOperationFailed(let error):
            return "Workspace file operation failed: \(error.localizedDescription)"
        }
    }
}

// MARK: - File Workspace Persistence

final class FileWorkspacePersistence: WorkspacePersistence {

    // MARK: File Locations

    private let fileManager: FileManager
    private let fileURL: URL
    private let backupURL: URL

    // MARK: Initialization

    init(
        fileManager: FileManager = .default,
        fileURL: URL? = nil
    ) throws {

        self.fileManager = fileManager

        if let fileURL {
            self.fileURL = fileURL
        } else {
            let applicationSupportDirectory = try fileManager.url(
                for: .applicationSupportDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true
            )

            let applicationDirectory = applicationSupportDirectory
                .appendingPathComponent(
                    "AtheerAutotrade",
                    isDirectory: true
                )

            self.fileURL = applicationDirectory
                .appendingPathComponent("workspaces.json")
        }

        self.backupURL = self.fileURL
            .deletingLastPathComponent()
            .appendingPathComponent("workspaces.json.backup")
    }

    // MARK: Load

    func load() throws -> WorkspaceDocument {

        guard fileManager.fileExists(atPath: fileURL.path) else {
            throw CocoaError(.fileNoSuchFile)
        }

        do {
            let data = try Data(contentsOf: fileURL)

            let decoder = JSONDecoder()

            let document = try decoder.decode(
                WorkspaceDocument.self,
                from: data
            )

            try document.validate()

            return document

        } catch {
            // Preserve the original error.
            // Never replace invalid or unreadable data automatically.
            throw error
        }
    }

    // MARK: Save

    func save(_ document: WorkspaceDocument) throws {

        // Validate before writing anything.
        try document.validate()

        do {
            let directoryURL = fileURL.deletingLastPathComponent()

            try fileManager.createDirectory(
                at: directoryURL,
                withIntermediateDirectories: true,
                attributes: nil
            )

            let encoder = JSONEncoder()
            encoder.outputFormatting = [
                .prettyPrinted,
                .sortedKeys
            ]

            let data = try encoder.encode(document)

            // Preserve the previous file before replacing it.
            if fileManager.fileExists(atPath: fileURL.path) {
                try createBackup()
            }

            // Atomic write prevents partially written JSON files.
            try data.write(
                to: fileURL,
                options: .atomic
            )

        } catch let error as WorkspacePersistenceError {
            throw error

        } catch {
            throw WorkspacePersistenceError.fileOperationFailed(
                underlying: error
            )
        }
    }

    // MARK: Backup

    private func createBackup() throws {

        do {
            let existingData = try Data(contentsOf: fileURL)

            try existingData.write(
                to: backupURL,
                options: .atomic
            )

        } catch {
            // Abort the save if the existing file cannot be backed up.
            throw WorkspacePersistenceError.backupFailed(
                underlying: error
            )
        }
    }

    // MARK: Recovery Support

    func restoreBackup() throws -> WorkspaceDocument {

        guard fileManager.fileExists(atPath: backupURL.path) else {
            throw CocoaError(.fileNoSuchFile)
        }

        do {
            let backupData = try Data(contentsOf: backupURL)

            let document = try JSONDecoder().decode(
                WorkspaceDocument.self,
                from: backupData
            )

            try document.validate()

            // Preserve the current file before restoring the backup.
            if fileManager.fileExists(atPath: fileURL.path) {
                try createBackupOfCurrentFile()
            }

            try backupData.write(
                to: fileURL,
                options: .atomic
            )

            return document

        } catch let error as WorkspacePersistenceError {
            throw error

        } catch {
            throw WorkspacePersistenceError.fileOperationFailed(
                underlying: error
            )
        }
    }

    private func createBackupOfCurrentFile() throws {

        do {
            let currentData = try Data(contentsOf: fileURL)

            let recoveryURL = fileURL
                .deletingLastPathComponent()
                .appendingPathComponent("workspaces.pre-restore.json")

            try currentData.write(
                to: recoveryURL,
                options: .atomic
            )

        } catch {
            throw WorkspacePersistenceError.backupFailed(
                underlying: error
            )
        }
    }
}

