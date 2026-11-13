import AVFoundation
import PhotosUI
import SwiftUI

enum PrimalStyle {
    static let ink = Color(red: 0.14, green: 0.23, blue: 0.18)
    static let paper = Color(red: 0.96, green: 0.95, blue: 0.91)
    static let leaf = Color(red: 0.82, green: 0.91, blue: 0.56)
    static let muted = Color(red: 0.36, green: 0.40, blue: 0.35)
}

struct PrimaryButton: View {
    let title: String
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: icon)
                .font(.headline)
                .frame(maxWidth: .infinity, minHeight: 32)
                .padding(12)
        }
        .buttonStyle(.plain)
        .foregroundStyle(PrimalStyle.paper)
        .background(PrimalStyle.ink, in: RoundedRectangle(cornerRadius: 18))
    }
}

struct ScanView: View {
    @StateObject private var model = ScanModel()
    @AppStorage("apiBaseURL") private var apiBaseURL = ScanView.defaultServer
    @State private var photo: PhotosPickerItem?
    @State private var showingCamera = false
    @State private var showingSettings = false
    @State private var importingPhoto = false
    @FocusState private var editingText: Bool

    private static var defaultServer: String {
        if let configured = Bundle.main.object(forInfoDictionaryKey: "APIBaseURL") as? String,
           !configured.isEmpty { return configured }
        #if DEBUG && targetEnvironment(simulator)
        return "http://localhost:8000"
        #else
        return ""
        #endif
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    brand
                    if let result = model.result {
                        ResultView(result: result)
                        PrimaryButton(title: "Scan another label", icon: "camera") { model.reset() }
                            .accessibilityIdentifier("newScan")
                        Button("Edit this ingredient list") { model.editIngredients() }
                            .frame(maxWidth: .infinity)
                    } else {
                        introduction
                        captureControls
                        ingredientEditor
                        if model.isBusy || importingPhoto {
                            HStack(spacing: 12) {
                                ProgressView().tint(PrimalStyle.ink)
                                Text(importingPhoto ? "Opening your photo…" : model.progress)
                                    .font(.subheadline)
                            }
                            .accessibilityElement(children: .combine)
                        }
                        PrimaryButton(title: "Understand this label", icon: "arrow.up.right") {
                            editingText = false
                            model.evaluate(server: apiBaseURL)
                        }
                        .accessibilityIdentifier("evaluateLabel")
                        .disabled(model.isBusy || importingPhoto || model.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        .opacity(model.isBusy || importingPhoto || model.text.isEmpty ? 0.5 : 1)
                        Text("Your photo stays on your phone. Only the ingredient text you confirm is sent for evaluation.")
                            .font(.footnote).foregroundStyle(PrimalStyle.muted)
                    }
                }
                .padding(24)
                .frame(maxWidth: 640)
                .frame(maxWidth: .infinity)
            }
            .background(PrimalStyle.paper.ignoresSafeArea())
            .foregroundStyle(PrimalStyle.ink)
            .tint(PrimalStyle.ink)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Connection", systemImage: "slider.horizontal.3") { showingSettings = true }
                        .disabled(model.isBusy || importingPhoto)
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") { editingText = false }
                }
            }
            .sheet(isPresented: $showingSettings) { ConnectionView(server: $apiBaseURL) }
            .fullScreenCover(isPresented: $showingCamera) {
                CameraCapture(onImage: { data in
                    showingCamera = false
                    model.recognize(data)
                }, onCancel: { showingCamera = false })
                .ignoresSafeArea()
            }
            .onChange(of: photo) { _, item in
                guard let item else { return }
                importingPhoto = true
                Task { @MainActor in
                    defer { importingPhoto = false; photo = nil }
                    do {
                        guard let data = try await item.loadTransferable(type: Data.self),
                              data.count <= 25_000_000 else {
                            throw ScanError.message("Choose a photo smaller than 25 MB.")
                        }
                        model.recognize(data)
                    } catch {
                        model.errorMessage = "Could not open this photo. Choose another or enter the text."
                    }
                }
            }
            .alert("Let’s try that again", isPresented: Binding(
                get: { model.errorMessage != nil },
                set: { if !$0 { model.errorMessage = nil } }
            )) {
                Button("OK", role: .cancel) { model.errorMessage = nil }
            } message: {
                Text(model.errorMessage ?? "")
            }
        }
    }

    private var brand: some View {
        HStack(spacing: 8) {
            Image(systemName: "leaf.fill")
            Text("primal").font(.system(.title2, design: .rounded, weight: .bold))
            Spacer()
            Text("LABEL, MEET CLARITY").font(.caption2.weight(.semibold)).tracking(1.5)
        }
    }

    private var introduction: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("A little clarity.\nA better grocery run.")
                .font(.system(.largeTitle, design: .serif)).fontWeight(.medium)
                .fixedSize(horizontal: false, vertical: true)
            Text("Start with the ingredients. We’ll help you understand what’s on the label, one ingredient at a time.")
                .font(.body).foregroundStyle(PrimalStyle.muted)
            Label("Whole-food preferences · Draft model", systemImage: "sparkle")
                .font(.caption.weight(.medium)).padding(.horizontal, 12).padding(.vertical, 8)
                .background(PrimalStyle.leaf, in: Capsule())
        }
    }

    private var captureControls: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                Text("01").font(.caption.monospaced()).foregroundStyle(PrimalStyle.muted)
                Text("Get the ingredient list").font(.headline)
            }
            PrimaryButton(title: "Photograph a label", icon: "camera.viewfinder") {
                Task { await openCamera() }
            }
            PhotosPicker(selection: $photo, matching: .images) {
                Label("Choose a photo", systemImage: "photo.on.rectangle")
                    .font(.subheadline.weight(.semibold)).frame(maxWidth: .infinity, minHeight: 44)
            }
            Text("Use the ingredient list, not just the nutrition panel. You can also type it below.")
                .font(.footnote).foregroundStyle(PrimalStyle.muted)
        }
        .padding(20).background(.white.opacity(0.65), in: RoundedRectangle(cornerRadius: 24))
        .disabled(model.isBusy || importingPhoto)
    }

    private var ingredientEditor: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("02").font(.caption.monospaced()).foregroundStyle(PrimalStyle.muted)
                Text("Check the text").font(.headline)
                Spacer()
                Text("\(model.text.count)/8000").font(.caption.monospacedDigit())
                    .foregroundStyle(model.text.count > 8000 ? .red : PrimalStyle.muted)
            }
            Text("Keep only the full ingredient list. Separate ingredients with commas; correct anything the camera missed.")
                .font(.footnote).foregroundStyle(PrimalStyle.muted)
            TextEditor(text: $model.text)
                .frame(minHeight: 180).padding(10).scrollContentBackground(.hidden)
                .background(.white, in: RoundedRectangle(cornerRadius: 16))
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(PrimalStyle.ink.opacity(0.15)))
                .focused($editingText)
                .accessibilityLabel("Ingredient list")
                .accessibilityIdentifier("ingredientText")
                .accessibilityHint("Review and correct recognized text before submitting")
                .disabled(model.isBusy || importingPhoto)
            if model.text.isEmpty {
                Button("Try an example: oats, almonds, honey", systemImage: "text.badge.plus") {
                    model.text = "oats, almonds, honey"
                }
                .accessibilityIdentifier("exampleLabel")
                .font(.footnote)
                .disabled(model.isBusy || importingPhoto)
            }
        }
    }

    @MainActor
    private func openCamera() async {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            model.errorMessage = "This device has no available camera. Choose a photo or enter ingredients instead."
            return
        }
        let granted = await AVCaptureDevice.requestAccess(for: .video)
        guard granted else {
            model.errorMessage = "Camera access is off. Enable it in iPhone Settings → Primal, or choose a photo."
            return
        }
        showingCamera = true
    }
}

struct ConnectionView: View {
    @Binding var server: String
    @Environment(\.dismiss) private var dismiss
    @State private var draft = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Backend address") {
                    TextField("https://your-api.example.com", text: $draft)
                        .textInputAutocapitalization(.never).autocorrectionDisabled()
                        .keyboardType(.URL).accessibilityLabel("API base URL")
                    Text("Use the root address of your Django server. Text you submit is sent to this address.")
                        .font(.footnote)
                }
                Section("Privacy") {
                    Text("Photos and recognized text are kept only in the active scan. There are no accounts or saved scan history. The API address is saved on this device.")
                    Text("The draft model describes ingredient preferences, not medical advice or allergen safety.")
                }
            }
            .navigationTitle("Connection")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { server = draft.trimmingCharacters(in: .whitespacesAndNewlines); dismiss() }
                        .disabled(APIClient.validatedURL(draft) == nil)
                }
            }
            .onAppear { draft = server }
        }
        .tint(PrimalStyle.ink)
    }
}
