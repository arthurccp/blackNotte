import SwiftData
import SwiftUI

struct NotesLibraryView: View {
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
                        }
                        .onDelete(perform: deleteNotes)
                    }
                }
            }
            .navigationTitle("Notas")
        }
    }

    private func deleteNotes(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(notes[index])
        }

        try? modelContext.save()
    }
}

private struct NoteRowView: View {
    let note: ThoughtNote

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(note.title)
                .font(.headline)
                .lineLimit(1)

            Text(note.rawText)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(2)

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
}
