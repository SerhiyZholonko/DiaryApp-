// MARK: - DiaryStore
// Сховище записів: Firebase Firestore.
// Колекція: users/{uid}/entries/{entryId}
import Foundation
import FirebaseFirestore
import FirebaseAuth

final class DiaryStore: DiaryStoreProtocol {

    private var db: Firestore { Firestore.firestore() }

    private var uid: String? { Auth.auth().currentUser?.uid }

    private func entriesRef() throws -> CollectionReference {
        guard let uid else { throw DiaryStoreError.notAuthenticated }
        return db.collection("users").document(uid).collection("entries")
    }

    // Firestore mapping is in the extension below
    // MediaStore handles local/iCloud file storage; Firestore stores only metadata

    func fetchEntries() async throws -> [DiaryEntry] {
        let ref = try entriesRef()
        let snapshot = try await ref
            .order(by: "createdAt", descending: true)
            .getDocuments()
        return snapshot.documents.compactMap { DiaryEntry(document: $0) }
    }

    func saveEntry(_ entry: DiaryEntry) async throws {
        let ref = try entriesRef()
        try await ref.document(entry.id).setData(entry.firestoreData, merge: true)
    }

    func deleteEntry(id: String) async throws {
        let ref = try entriesRef()
        try await ref.document(id).delete()
        MediaStore.shared.deleteAll(entryId: id)
    }

    func searchEntries(query: String) async throws -> [DiaryEntry] {
        let all = try await fetchEntries()
        guard !query.isEmpty else { return all }
        return all.filter {
            $0.text.localizedCaseInsensitiveContains(query) ||
            $0.tags.contains { $0.localizedCaseInsensitiveContains(query) }
        }
    }
}

enum DiaryStoreError: LocalizedError {
    case notAuthenticated
    var errorDescription: String? { "Будь ласка, увійдіть в акаунт" }
}

// MARK: - Firestore Mapping

private extension DiaryEntry {
    init?(document: QueryDocumentSnapshot) {
        let d = document.data()
        guard let text      = d["text"]      as? String,
              let createdAt = (d["createdAt"] as? Timestamp)?.dateValue(),
              let updatedAt = (d["updatedAt"] as? Timestamp)?.dateValue()
        else { return nil }

        self.id        = document.documentID
        self.text      = text
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.tags      = d["tags"] as? [String] ?? []
        if let moodRaw = d["mood"] as? Int {
            self.mood = MoodLevel(rawValue: moodRaw)
        } else {
            self.mood = nil
        }
        if let raw = d["attachments"] as? [[String: Any]] {
            self.attachments = raw.compactMap { a -> MediaAttachment? in
                guard let id       = a["id"]       as? String,
                      let typeRaw  = a["type"]      as? String,
                      let type     = MediaAttachment.MediaType(rawValue: typeRaw),
                      let fileName = a["fileName"]  as? String
                else { return nil }
                return MediaAttachment(id: id, type: type, fileName: fileName,
                                       thumbnailName: a["thumbnailName"] as? String)
            }
        } else {
            self.attachments = []
        }
    }

    var firestoreData: [String: Any] {
        var data: [String: Any] = [
            "text":      text,
            "tags":      tags,
            "createdAt": Timestamp(date: createdAt),
            "updatedAt": Timestamp(date: updatedAt)
        ]
        if let mood { data["mood"] = mood.rawValue }
        if !attachments.isEmpty {
            data["attachments"] = attachments.map { a -> [String: Any] in
                var d: [String: Any] = ["id": a.id, "type": a.type.rawValue, "fileName": a.fileName]
                if let thumb = a.thumbnailName { d["thumbnailName"] = thumb }
                return d
            }
        }
        return data
    }
}
