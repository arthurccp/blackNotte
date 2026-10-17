import SwiftUI

struct VoiceOrbButton: View {
    let isRecording: Bool
    let isLoading: Bool
    let title: String
    let subtitle: String
    let action: () -> Void

    @State private var pulse = false

    var body: some View {
        Button(action: action) {
            VStack(spacing: 14) {
                ZStack {
                    if isRecording {
                        Circle()
                            .fill(Color.blue.opacity(0.18))
                            .frame(width: 144, height: 144)
                            .scaleEffect(pulse ? 1.18 : 0.96)
                            .opacity(0.8)

                        Circle()
                            .fill(Color.blue.opacity(0.28))
                            .frame(width: 116, height: 116)
                            .scaleEffect(pulse ? 1.08 : 0.98)

                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [
                                        Color.cyan.opacity(0.95),
                                        Color.blue.opacity(0.95),
                                        Color.indigo.opacity(0.9)
                                    ],
                                    center: .center,
                                    startRadius: 6,
                                    endRadius: 60
                                )
                            )
                            .frame(width: 88, height: 88)
                            .shadow(color: Color.blue.opacity(0.45), radius: 22, x: 0, y: 0)
                    } else {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.blue, Color.cyan],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 88, height: 88)
                            .shadow(color: Color.blue.opacity(0.35), radius: 16, x: 0, y: 0)
                    }

                    if isLoading {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image(systemName: isRecording ? "stop.fill" : "mic.fill")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 160)
                .animation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true), value: pulse)

                VStack(spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(.primary)

                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
        .onAppear {
            pulse = isRecording
        }
        .onChange(of: isRecording) { _, newValue in
            pulse = newValue
        }
    }
}
