import SwiftData
import SwiftUI

struct NotesLibraryView: View {
    @State private var deletionError: String?
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ThoughtNote.updatedAt, order: .reverse) private var notes: [ThoughtNote]

    var body: some View {
        NavigationStack {
            Group {
                if notes.isEmpty {
                    ContentUnavailableView(
                        "Nenhuma nota ainda",
                        systemImage: "tray",
                        description: Text("Capture seu primeiro pensamento na aba Capturar.")
                    )
                } else {
                    List {
                        ForEach(notes) { note in
                            NavigationLink {
                                NoteDetailView(note: note)
                            } label: {
                                NoteRowView(note: note)
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    deleteNote(note)
                                } label: {
                                    Label("Apagar", systemImage: "trash")
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Notas")
            .alert("Não foi possível apagar", isPresented: Binding(
                get: { deletionError != nil },
                set: { if !$0 { deletionError = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(deletionError ?? "")
            }
        }
    }

    private func deleteNote(_ note: ThoughtNote) {
        modelContext.delete(note)
        do {
            try modelContext.save()
        } catch {
            modelContext.rollback()
            deletionError = error.localizedDescription
        }
    }
}

private struct NoteRowView: View {
    let note: ThoughtNote

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(note.title)
                .font(.headline)
                .lineLimit(1)

            if !previewText.isEmpty {
                Text(previewText)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            HStack(spacing: 8) {
                Label(note.source == .voice ? "Voz" : "Texto", systemImage: note.source == .voice ? "mic" : "text.alignleft")

                if let category = note.category, !category.isEmpty {
                    Text(category)
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }

    private var previewText: String {
        if let summary = note.ideaSummary, !summary.isEmpty {
            return summary
        }
        if let topics = note.analysis?.topics, !topics.isEmpty {
            return topics.prefix(2).joined(separator: " • ")
        }

        return note.rawText
    }
}
