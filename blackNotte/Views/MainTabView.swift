
import SwiftUI

struct MainTabView: View {
    @StateObject private var voiceService = VoiceCaptureService()

    var body: some View {
        TabView {
            CaptureNoteView()
                .environmentObject(voiceService)
                .tabItem {
                    Label("Capturar", systemImage: "square.and.pencil")
                }

            NotesLibraryView()
                .tabItem {
                    Label("Notas", systemImage: "tray.full")
                }
        }
        .tint(.orange)
        .task {
            if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] != "1" {
                await voiceService.requestPermissions()
            }
        }
        .alert("Permissao necessaria", isPresented: $voiceService.showPermissionAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Ative microfone e reconhecimento de fala nos ajustes do iPhone.")
        }
        .alert("Erro", isPresented: Binding(
            get: { voiceService.errorMessage != nil },
            set: { _ in voiceService.errorMessage = nil }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(voiceService.errorMessage ?? "Erro desconhecido.")
        }
    }
}

#Preview {
    MainTabView()
}
