import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion

    @AppStorage(PreferenceKey.calmMode) private var calmMode = false
    @AppStorage(PreferenceKey.extraSpacing) private var extraSpacing = false
    @AppStorage(PreferenceKey.readInstructions) private var readInstructions = false
    @AppStorage(PreferenceKey.showTransliteration) private var showTransliteration = true
    @AppStorage(PreferenceKey.arabicScale) private var arabicScale = 1.0
    @AppStorage(PreferenceKey.backgroundStyle) private var backgroundStyle = 0

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text("Diese Optionen sind für alle da. Sie stellen keine Diagnose.")
                        .font(.callout)
                }

                Section("Lesbarkeit") {
                    VStack(alignment: .leading) {
                        HStack {
                            Text("Größe der arabischen Lernzeichen")
                            Spacer()
                            Text("\(Int(arabicScale * 100)) %")
                                .foregroundStyle(.secondary)
                        }
                        Slider(value: $arabicScale, in: 0.85...1.35, step: 0.05)
                            .accessibilityLabel("Größe der arabischen Lernzeichen")
                    }

                    Toggle("Mehr Zeilenabstand", isOn: $extraSpacing)

                    Picker("Hintergrund", selection: $backgroundStyle) {
                        Text("Warm").tag(0)
                        Text("Salbei").tag(1)
                        Text("Kühl").tag(2)
                    }
                }

                Section("Fokus und Unterstützung") {
                    Toggle("Ruhiger Lernmodus", isOn: $calmMode)
                    Text("Blendet nicht notwendige Dekoration aus. Die Systemoption „Bewegung reduzieren“ wird zusätzlich beachtet.")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    LabeledContent("System: Bewegung reduzieren") {
                        Text(systemReduceMotion ? "Ein" : "Aus")
                    }

                    Toggle("Hinweise beim Start vorlesen", isOn: $readInstructions)
                    Toggle("Umschrift zunächst anzeigen", isOn: $showTransliteration)
                }

                Section("Schrift und Bedienung") {
                    Text("Die App unterstützt dynamische Schriftgrößen, VoiceOver, erhöhten Kontrast und Bedienung ohne komplexe Gesten.")
                        .font(.callout)
                    Text("Die iOS-Schriftgröße stellst du in Einstellungen > Bedienungshilfen > Anzeige & Textgröße ein.")
                        .font(.callout)
                }
            }
            .navigationTitle("Lesbarkeit & Fokus")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fertig") {
                        dismiss()
                    }
                    .accessibilityIdentifier("close-settings")
                }
            }
        }
    }
}
