//
//  VaultView.swift
//  On phoneapp
//
//  Created by Joel  on 10/18/25.
//

import SwiftUI
import PhotosUI
import UIKit
import VisionKit
import LocalAuthentication
import Combine

// MARK: - Biometric Authentication Manager
class BiometricAuthManager: ObservableObject {
    @Published var isAuthenticated = false
    @Published var authenticationError: String?

    private let context = LAContext()

    func canUseBiometrics() -> Bool {
        var error: NSError?
        return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
    }

    func biometricType() -> String {
        guard canUseBiometrics() else { return "None" }

        switch context.biometryType {
        case .faceID:
            return "Face ID"
        case .touchID:
            return "Touch ID"
        case .opticID:
            return "Optic ID"
        default:
            return "Biometrics"
        }
    }

    func authenticate(completion: @escaping (Bool, String?) -> Void) {
        let context = LAContext()
        var error: NSError?

        // Check if biometric authentication is available
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            let reason = "Unlock your vault to access secure documents"

            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, authError in
                DispatchQueue.main.async {
                    if success {
                        self.isAuthenticated = true
                        completion(true, nil)
                    } else {
                        let message = authError?.localizedDescription ?? "Authentication failed"
                        self.authenticationError = message
                        completion(false, message)
                    }
                }
            }
        } else {
            // Biometrics not available, fall back to PIN
            DispatchQueue.main.async {
                completion(false, "Biometric authentication not available. Use PIN.")
            }
        }
    }

    func reset() {
        isAuthenticated = false
        authenticationError = nil
    }
}

// MARK: - PIN Manager
class PINManager {
    private let pinKey = "vault_pin_code"

    func hasPIN() -> Bool {
        return UserDefaults.standard.string(forKey: pinKey) != nil
    }

    func setPIN(_ pin: String) {
        UserDefaults.standard.set(pin, forKey: pinKey)
    }

    func verifyPIN(_ pin: String) -> Bool {
        guard let storedPIN = UserDefaults.standard.string(forKey: pinKey) else {
            return false
        }
        return storedPIN == pin
    }

    func removePIN() {
        UserDefaults.standard.removeObject(forKey: pinKey)
    }
}

// MARK: - Vault Unlock View
struct VaultUnlockView: View {
    @StateObject private var authManager = BiometricAuthManager()
    @State private var pinInput: String = ""
    @State private var showingPINSetup = false
    @State private var showError = false
    @State private var errorMessage = ""
    @FocusState private var isPINFieldFocused: Bool

    let pinManager = PINManager()
    let onUnlock: () -> Void

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.blue.opacity(0.6),
                    Color.purple.opacity(0.6)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 30) {
                Spacer()

                // Lock icon
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.white)
                    .shadow(radius: 10)

                Text("Vault Locked")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                Text("Authenticate to access your secure vault")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)

                Spacer()

                // Authentication buttons
                VStack(spacing: 16) {
                    // Biometric authentication button
                    if authManager.canUseBiometrics() {
                        Button(action: {
                            authenticateWithBiometrics()
                        }) {
                            HStack {
                                Image(systemName: authManager.biometricType() == "Face ID" ? "faceid" : "touchid")
                                    .font(.title2)
                                Text("Unlock with \(authManager.biometricType())")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.white)
                            .foregroundColor(.blue)
                            .cornerRadius(12)
                            .shadow(radius: 5)
                        }
                    }

                    // PIN entry
                    if pinManager.hasPIN() {
                        VStack(spacing: 12) {
                            Text("Or enter PIN")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.8))

                            HStack(spacing: 12) {
                                SecureField("Enter PIN", text: $pinInput)
                                    .keyboardType(.numberPad)
                                    .textContentType(.oneTimeCode)
                                    .padding()
                                    .background(Color.white.opacity(0.9))
                                    .cornerRadius(8)
                                    .focused($isPINFieldFocused)

                                Button(action: {
                                    verifyPIN()
                                }) {
                                    Image(systemName: "arrow.right.circle.fill")
                                        .font(.title2)
                                        .foregroundColor(.white)
                                }
                                .disabled(pinInput.isEmpty)
                            }
                        }
                    } else {
                        Button(action: {
                            showingPINSetup = true
                        }) {
                            HStack {
                                Image(systemName: "lock.rectangle")
                                    .font(.title2)
                                Text("Set Up PIN Code")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.white.opacity(0.2))
                            .foregroundColor(.white)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white, lineWidth: 2)
                            )
                        }
                    }
                }
                .padding(.horizontal, 40)

                Spacer()
            }
        }
        .alert("Authentication Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
        .sheet(isPresented: $showingPINSetup) {
            SetupPINView(pinManager: pinManager, onComplete: {
                showingPINSetup = false
            })
        }
        .onAppear {
            // Auto-trigger biometric authentication on appear
            if authManager.canUseBiometrics() {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    authenticateWithBiometrics()
                }
            }
        }
    }

    private func authenticateWithBiometrics() {
        authManager.authenticate { success, error in
            if success {
                onUnlock()
            } else if let error = error {
                errorMessage = error
                showError = true
            }
        }
    }

    private func verifyPIN() {
        if pinManager.verifyPIN(pinInput) {
            onUnlock()
        } else {
            errorMessage = "Incorrect PIN. Please try again."
            showError = true
            pinInput = ""
        }
    }
}

// MARK: - Setup PIN View
struct SetupPINView: View {
    @Environment(\.dismiss) var dismiss
    @State private var pin: String = ""
    @State private var confirmPin: String = ""
    @State private var showError = false
    @State private var errorMessage = ""
    @FocusState private var focusedField: Field?

    let pinManager: PINManager
    let onComplete: () -> Void

    enum Field {
        case pin, confirmPin
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(uiColor: .systemBackground)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 30) {
                        Image(systemName: "lock.rectangle.fill")
                            .font(.system(size: 70))
                            .foregroundColor(.blue)
                            .padding(.top, 40)

                        Text("Set Up PIN Code")
                            .font(.title)
                            .fontWeight(.bold)

                        Text("Create a 4-6 digit PIN to secure your vault")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)

                        VStack(spacing: 20) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Enter PIN")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)

                                SecureField("4-6 digits", text: $pin)
                                    .keyboardType(.numberPad)
                                    .textContentType(.oneTimeCode)
                                    .padding()
                                    .background(Color(uiColor: .secondarySystemBackground))
                                    .cornerRadius(8)
                                    .focused($focusedField, equals: .pin)
                                    .onChange(of: pin) { _, newValue in
                                        // Limit to 6 digits
                                        if newValue.count > 6 {
                                            pin = String(newValue.prefix(6))
                                        }
                                    }
                            }

                            VStack(alignment: .leading, spacing: 8) {
                                Text("Confirm PIN")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)

                                SecureField("Re-enter PIN", text: $confirmPin)
                                    .keyboardType(.numberPad)
                                    .textContentType(.oneTimeCode)
                                    .padding()
                                    .background(Color(uiColor: .secondarySystemBackground))
                                    .cornerRadius(8)
                                    .focused($focusedField, equals: .confirmPin)
                                    .onChange(of: confirmPin) { _, newValue in
                                        // Limit to 6 digits
                                        if newValue.count > 6 {
                                            confirmPin = String(newValue.prefix(6))
                                        }
                                    }
                            }
                        }
                        .padding(.horizontal, 40)

                        Button(action: {
                            setupPIN()
                        }) {
                            Text("Set PIN")
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(isValidPIN() ? Color.blue : Color.gray)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }
                        .disabled(!isValidPIN())
                        .padding(.horizontal, 40)
                        .padding(.bottom, 40)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
            .onAppear {
                focusedField = .pin
            }
        }
    }

    private func isValidPIN() -> Bool {
        return pin.count >= 4 && pin.count <= 6 && pin == confirmPin
    }

    private func setupPIN() {
        guard isValidPIN() else {
            errorMessage = "PINs must match and be 4-6 digits"
            showError = true
            return
        }

        pinManager.setPIN(pin)
        onComplete()
        dismiss()
    }
}

// MARK: - Document Scanner Coordinator
class DocumentScannerCoordinator: NSObject, VNDocumentCameraViewControllerDelegate {
    let parent: DocumentScannerView

    init(_ parent: DocumentScannerView) {
        self.parent = parent
    }

    func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
        // Process all scanned pages
        var scannedImages: [UIImage] = []
        for pageIndex in 0..<scan.pageCount {
            let image = scan.imageOfPage(at: pageIndex)
            scannedImages.append(image)
        }
        parent.scannedImages = scannedImages
        parent.presentationMode.wrappedValue.dismiss()
    }

    func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
        parent.presentationMode.wrappedValue.dismiss()
    }

    func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFailWithError error: Error) {
        print("Document scanning failed: \(error.localizedDescription)")
        parent.presentationMode.wrappedValue.dismiss()
    }
}

// MARK: - Document Scanner View
struct DocumentScannerView: UIViewControllerRepresentable {
    @Environment(\.presentationMode) var presentationMode
    @Binding var scannedImages: [UIImage]

    func makeCoordinator() -> DocumentScannerCoordinator {
        DocumentScannerCoordinator(self)
    }

    func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
        let scanner = VNDocumentCameraViewController()
        scanner.delegate = context.coordinator
        return scanner
    }

    func updateUIViewController(_ uiViewController: VNDocumentCameraViewController, context: Context) {}
}

// MARK: - Image Picker Coordinator
class ImagePickerCoordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    let parent: ImagePickerView

    init(_ parent: ImagePickerView) {
        self.parent = parent
    }

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let image = info[.originalImage] as? UIImage {
            parent.selectedImage = image
        }
        parent.presentationMode.wrappedValue.dismiss()
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        parent.presentationMode.wrappedValue.dismiss()
    }
}

// MARK: - Image Picker View
struct ImagePickerView: UIViewControllerRepresentable {
    @Environment(\.presentationMode) var presentationMode
    @Binding var selectedImage: UIImage?
    var sourceType: UIImagePickerController.SourceType

    func makeCoordinator() -> ImagePickerCoordinator {
        ImagePickerCoordinator(self)
    }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = sourceType
        picker.allowsEditing = false
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
}

// MARK: - Vault Item Model
struct VaultItem: Identifiable, Codable {
    var id: UUID
    var title: String
    var category: String
    var imageName: String // Stored filename in documents directory
    var thumbnailName: String? // Optional thumbnail for faster loading
    var createdAt: Date
    var tags: [String]
    var notes: String?

    init(id: UUID = UUID(), title: String, category: String, imageName: String, thumbnailName: String? = nil, createdAt: Date = Date(), tags: [String] = [], notes: String? = nil) {
        self.id = id
        self.title = title
        self.category = category
        self.imageName = imageName
        self.thumbnailName = thumbnailName
        self.createdAt = createdAt
        self.tags = tags
        self.notes = notes
    }
}

// MARK: - Vault Storage Manager
class VaultStorageManager {
    private let itemsKey = "vault_items"

    func saveItems(_ items: [VaultItem]) {
        if let encoded = try? JSONEncoder().encode(items) {
            UserDefaults.standard.set(encoded, forKey: itemsKey)
        }
    }

    func loadItems() -> [VaultItem] {
        guard let data = UserDefaults.standard.data(forKey: itemsKey),
              let items = try? JSONDecoder().decode([VaultItem].self, from: data) else {
            return []
        }
        return items
    }

    // Get documents directory for storing images
    func getDocumentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    func saveImage(_ image: UIImage, filename: String) -> Bool {
        guard let data = image.jpegData(compressionQuality: 0.8) else { return false }
        let url = getDocumentsDirectory().appendingPathComponent(filename)
        do {
            try data.write(to: url)
            return true
        } catch {
            print("Error saving image: \(error)")
            return false
        }
    }

    func loadImage(filename: String) -> UIImage? {
        let url = getDocumentsDirectory().appendingPathComponent(filename)
        return UIImage(contentsOfFile: url.path)
    }

    func deleteImage(filename: String) {
        let url = getDocumentsDirectory().appendingPathComponent(filename)
        try? FileManager.default.removeItem(at: url)
    }
}

// MARK: - Add Vault Item View
struct AddVaultItemView: View {
    @Environment(\.dismiss) var dismiss
    @State private var itemTitle: String = ""
    @State private var category: String = ""
    @State private var tags: String = ""
    @State private var notes: String = ""
    @State private var selectedImage: UIImage?
    @State private var scannedImages: [UIImage] = []
    @State private var currentImageIndex: Int = 0
    @State private var showingImageSourcePicker = false
    @State private var showingCamera = false
    @State private var showingPhotoLibrary = false
    @FocusState private var isTextFieldFocused: Bool

    let onSave: (UIImage, String, String, [String], String?) -> Void
    let initialScannedImages: [UIImage]?

    init(onSave: @escaping (UIImage, String, String, [String], String?) -> Void, scannedImages: [UIImage]? = nil) {
        self.onSave = onSave
        self.initialScannedImages = scannedImages
    }

    // Predefined categories
    let predefinedCategories = ["Taxes", "Rental Property", "Receipts", "Insurance", "Medical", "Personal", "Business", "Legal", "Education", "Other"]

    var displayImage: UIImage? {
        if !scannedImages.isEmpty {
            return scannedImages[currentImageIndex]
        }
        return selectedImage
    }

    var hasMultiplePages: Bool {
        scannedImages.count > 1
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(uiColor: .systemBackground)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // Image Preview/Selection
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(hasMultiplePages ? "Scanned Document" : "Image")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primary)

                                if hasMultiplePages {
                                    Spacer()
                                    Text("Page \(currentImageIndex + 1) of \(scannedImages.count)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }

                            if let image = displayImage {
                                VStack(spacing: 12) {
                                    ZStack(alignment: .topTrailing) {
                                        Image(uiImage: image)
                                            .resizable()
                                            .scaledToFit()
                                            .frame(maxHeight: 300)
                                            .cornerRadius(12)

                                        Button(action: {
                                            selectedImage = nil
                                            scannedImages = []
                                            currentImageIndex = 0
                                        }) {
                                            Image(systemName: "xmark.circle.fill")
                                                .font(.title2)
                                                .foregroundColor(.white)
                                                .background(Circle().fill(Color.black.opacity(0.6)))
                                        }
                                        .padding(8)
                                    }

                                    // Page navigation for multi-page scans
                                    if hasMultiplePages {
                                        HStack(spacing: 16) {
                                            Button(action: {
                                                if currentImageIndex > 0 {
                                                    currentImageIndex -= 1
                                                }
                                            }) {
                                                Image(systemName: "chevron.left.circle.fill")
                                                    .font(.title2)
                                                    .foregroundColor(currentImageIndex > 0 ? .blue : .gray)
                                            }
                                            .disabled(currentImageIndex == 0)

                                            // Thumbnail strip
                                            ScrollView(.horizontal, showsIndicators: false) {
                                                HStack(spacing: 8) {
                                                    ForEach(0..<scannedImages.count, id: \.self) { index in
                                                        Button(action: {
                                                            currentImageIndex = index
                                                        }) {
                                                            Image(uiImage: scannedImages[index])
                                                                .resizable()
                                                                .scaledToFill()
                                                                .frame(width: 60, height: 60)
                                                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                                                .overlay(
                                                                    RoundedRectangle(cornerRadius: 8)
                                                                        .stroke(currentImageIndex == index ? Color.blue : Color.clear, lineWidth: 3)
                                                                )
                                                        }
                                                    }
                                                }
                                            }

                                            Button(action: {
                                                if currentImageIndex < scannedImages.count - 1 {
                                                    currentImageIndex += 1
                                                }
                                            }) {
                                                Image(systemName: "chevron.right.circle.fill")
                                                    .font(.title2)
                                                    .foregroundColor(currentImageIndex < scannedImages.count - 1 ? .blue : .gray)
                                            }
                                            .disabled(currentImageIndex == scannedImages.count - 1)
                                        }
                                        .padding(.top, 8)
                                    }
                                }
                            } else {
                                Button(action: { showingImageSourcePicker = true }) {
                                    VStack(spacing: 12) {
                                        Image(systemName: "photo.on.rectangle.angled")
                                            .font(.system(size: 50))
                                            .foregroundColor(.blue)

                                        Text("Select Image")
                                            .font(.headline)
                                            .foregroundColor(.blue)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 200)
                                    .background(Color(uiColor: .tertiarySystemBackground))
                                    .cornerRadius(12)
                                }
                            }
                        }
                        .padding()
                        .background(Color(uiColor: .secondarySystemBackground))
                        .cornerRadius(12)

                        // Title
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Title")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)

                            TextField("Enter title", text: $itemTitle)
                                .padding()
                                .background(Color(uiColor: .tertiarySystemBackground))
                                .cornerRadius(8)
                                .font(.body)
                                .focused($isTextFieldFocused)
                        }
                        .padding()
                        .background(Color(uiColor: .secondarySystemBackground))
                        .cornerRadius(12)

                        // Category
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Category")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)

                            Menu {
                                ForEach(predefinedCategories, id: \.self) { cat in
                                    Button(cat) {
                                        category = cat
                                    }
                                }
                            } label: {
                                HStack {
                                    Text(category.isEmpty ? "Select category" : category)
                                        .foregroundColor(category.isEmpty ? .secondary : .primary)
                                    Spacer()
                                    Image(systemName: "chevron.down")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding()
                                .background(Color(uiColor: .tertiarySystemBackground))
                                .cornerRadius(8)
                            }

                            TextField("Or enter custom category", text: $category)
                                .padding()
                                .background(Color(uiColor: .tertiarySystemBackground))
                                .cornerRadius(8)
                                .font(.body)
                        }
                        .padding()
                        .background(Color(uiColor: .secondarySystemBackground))
                        .cornerRadius(12)

                        // Tags
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Tags (Optional)")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)

                            TextField("Separate tags with commas", text: $tags)
                                .padding()
                                .background(Color(uiColor: .tertiarySystemBackground))
                                .cornerRadius(8)
                                .font(.body)

                            if !tags.isEmpty {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 6) {
                                        ForEach(tags.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }, id: \.self) { tag in
                                            if !tag.isEmpty {
                                                Text("#\(tag)")
                                                    .font(.caption)
                                                    .padding(.horizontal, 8)
                                                    .padding(.vertical, 4)
                                                    .background(Color.blue.opacity(0.1))
                                                    .foregroundColor(.blue)
                                                    .cornerRadius(8)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        .padding()
                        .background(Color(uiColor: .secondarySystemBackground))
                        .cornerRadius(12)

                        // Notes
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Notes (Optional)")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)

                            TextEditor(text: $notes)
                                .frame(height: 100)
                                .padding(4)
                                .background(Color(uiColor: .tertiarySystemBackground))
                                .cornerRadius(8)
                                .scrollContentBackground(.hidden)
                        }
                        .padding()
                        .background(Color(uiColor: .secondarySystemBackground))
                        .cornerRadius(12)
                    }
                    .padding()
                }
            }
            .navigationTitle("Add to Vault")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveItem()
                    }
                    .fontWeight(.semibold)
                    .disabled(displayImage == nil || itemTitle.trimmingCharacters(in: .whitespaces).isEmpty || category.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear {
                if let images = initialScannedImages, !images.isEmpty {
                    scannedImages = images
                    currentImageIndex = 0
                }
            }
            .confirmationDialog("Select Image Source", isPresented: $showingImageSourcePicker, titleVisibility: .visible) {
                if UIImagePickerController.isSourceTypeAvailable(.camera) {
                    Button(action: { showingCamera = true }) {
                        Label("Take Photo", systemImage: "camera")
                    }
                }

                Button(action: { showingPhotoLibrary = true }) {
                    Label("Choose from Library", systemImage: "photo.on.rectangle")
                }

                Button("Cancel", role: .cancel) { }
            }
            .sheet(isPresented: $showingCamera) {
                ImagePickerView(selectedImage: $selectedImage, sourceType: .camera)
            }
            .sheet(isPresented: $showingPhotoLibrary) {
                ImagePickerView(selectedImage: $selectedImage, sourceType: .photoLibrary)
            }
        }
    }

    private func saveItem() {
        // Use the currently displayed image (either selected or from scanned pages)
        guard let image = displayImage else { return }

        let tagArray = tags.split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        let notesText = notes.trimmingCharacters(in: .whitespaces)

        // Add page info to notes if multiple pages
        var finalNotes = notesText
        if hasMultiplePages {
            let pageInfo = "Scanned document with \(scannedImages.count) pages. Showing page \(currentImageIndex + 1)."
            finalNotes = notesText.isEmpty ? pageInfo : "\(pageInfo)\n\n\(notesText)"
        }

        onSave(image, itemTitle, category, tagArray, finalNotes.isEmpty ? nil : finalNotes)
        dismiss()
    }
}

// MARK: - Main Vault View
struct VaultView: View {
    @State private var items: [VaultItem] = []
    @State private var showingAddOptions = false
    @State private var showingImagePicker = false
    @State private var showingDocumentScanner = false
    @State private var showingCategoryFilter = false
    @State private var selectedCategory: String = "All"
    @State private var viewMode: ViewMode = .grid
    @State private var searchText = ""
    @State private var scannedImages: [UIImage] = []
    @State private var showingAddFromScan = false
    @State private var isUnlocked = false
    @AppStorage("vault_security_enabled") private var securityEnabled = false

    private let storageManager = VaultStorageManager()

    enum ViewMode {
        case list, grid
    }

    var categories: [String] {
        var cats = ["All"] + Array(Set(items.map { $0.category })).sorted()
        return cats
    }

    var filteredItems: [VaultItem] {
        var filtered = items

        // Filter by category
        if selectedCategory != "All" {
            filtered = filtered.filter { $0.category == selectedCategory }
        }

        // Filter by search
        if !searchText.isEmpty {
            filtered = filtered.filter { item in
                item.title.localizedCaseInsensitiveContains(searchText) ||
                item.category.localizedCaseInsensitiveContains(searchText) ||
                item.tags.contains(where: { $0.localizedCaseInsensitiveContains(searchText) })
            }
        }

        return filtered.sorted { $0.createdAt > $1.createdAt }
    }

    var body: some View {
        Group {
            if securityEnabled && !isUnlocked {
                VaultUnlockView(onUnlock: {
                    withAnimation {
                        isUnlocked = true
                    }
                })
            } else {
                vaultContentView
            }
        }
    }

    var vaultContentView: some View {
        NavigationStack {
            ZStack {
                // Adaptive background
                Color(uiColor: .systemBackground)
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Search bar
                    if !items.isEmpty {
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.secondary)
                            TextField("Search vault...", text: $searchText)
                                .textFieldStyle(.plain)

                            if !searchText.isEmpty {
                                Button(action: { searchText = "" }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .padding(10)
                        .background(Color(uiColor: .secondarySystemBackground))
                        .cornerRadius(10)
                        .padding(.horizontal)
                        .padding(.top, 8)

                        // Category filter
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(categories, id: \.self) { category in
                                    CategoryPill(
                                        title: category,
                                        isSelected: selectedCategory == category,
                                        count: category == "All" ? items.count : items.filter { $0.category == category }.count
                                    ) {
                                        selectedCategory = category
                                    }
                                }
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 8)
                        }
                    }

                    // Content
                    if items.isEmpty {
                        emptyStateView
                    } else if filteredItems.isEmpty {
                        emptySearchView
                    } else {
                        if viewMode == .grid {
                            gridView
                        } else {
                            listView
                        }
                    }
                }
            }
            .navigationTitle("Vault")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                // Security toggle - leftmost
                ToolbarItem(placement: .navigationBarLeading) {
                    Menu {
                        Toggle(isOn: $securityEnabled) {
                            Label(securityEnabled ? "Security Enabled" : "Security Disabled", systemImage: securityEnabled ? "lock.fill" : "lock.open")
                        }
                    } label: {
                        Image(systemName: securityEnabled ? "lock.shield.fill" : "lock.shield")
                            .font(.title3)
                            .foregroundColor(securityEnabled ? .green : .gray)
                    }
                }

                // View mode toggle
                ToolbarItem(placement: .navigationBarLeading) {
                    if !items.isEmpty {
                        Button(action: { viewMode = viewMode == .grid ? .list : .grid }) {
                            Image(systemName: viewMode == .grid ? "list.bullet" : "square.grid.2x2")
                                .font(.title3)
                                .foregroundColor(.blue)
                        }
                    }
                }

                // Add button
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingAddOptions = true
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(.blue)
                    }
                }
            }
            .confirmationDialog("Add to Vault", isPresented: $showingAddOptions, titleVisibility: .visible) {
                Button(action: {
                    showingImagePicker = true
                }) {
                    Label("Upload from Photos", systemImage: "photo.on.rectangle")
                }

                Button(action: {
                    showingDocumentScanner = true
                }) {
                    Label("Scan Document", systemImage: "doc.text.viewfinder")
                }

                Button("Cancel", role: .cancel) { }
            }
            .sheet(isPresented: $showingImagePicker) {
                AddVaultItemView(onSave: { image, title, category, tags, notes in
                    addVaultItem(image: image, title: title, category: category, tags: tags, notes: notes)
                })
            }
            .sheet(isPresented: $showingDocumentScanner) {
                DocumentScannerView(scannedImages: $scannedImages)
            }
            .sheet(isPresented: $showingAddFromScan) {
                AddVaultItemView(onSave: { image, title, category, tags, notes in
                    addVaultItem(image: image, title: title, category: category, tags: tags, notes: notes)
                }, scannedImages: scannedImages)
            }
            .onChange(of: scannedImages) { oldValue, newValue in
                if !newValue.isEmpty && newValue != oldValue {
                    showingAddFromScan = true
                }
            }
            .onAppear {
                loadItems()
            }
        }
    }

    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "lock.shield.fill")
                .font(.system(size: 80))
                .foregroundColor(.blue.opacity(0.5))

            Text("Your Vault is Empty")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Store your important documents, receipts, and images securely")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            VStack(spacing: 12) {
                Button(action: {
                    showingImagePicker = true
                }) {
                    Label("Upload from Photos", systemImage: "photo.on.rectangle")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }

                Button(action: {
                    showingDocumentScanner = true
                }) {
                    Label("Scan Document", systemImage: "doc.text.viewfinder")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
            }
            .padding(.horizontal, 40)
            .padding(.top, 20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptySearchView: some View {
        VStack(spacing: 20) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 80))
                .foregroundColor(.blue.opacity(0.5))

            Text("No Results Found")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Try adjusting your search or filter")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Grid View
    private var gridView: some View {
        ScrollView {
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 16),
                GridItem(.flexible(), spacing: 16)
            ], spacing: 16) {
                ForEach(filteredItems) { item in
                    VaultItemGridCard(item: item, storageManager: storageManager)
                }
            }
            .padding()
        }
    }

    // MARK: - List View
    private var listView: some View {
        ScrollView {
            VStack(spacing: 12) {
                ForEach(filteredItems) { item in
                    VaultItemListRow(item: item, storageManager: storageManager)
                }
            }
            .padding()
        }
    }

    // MARK: - Data Operations
    private func loadItems() {
        items = storageManager.loadItems()
    }

    private func saveItems() {
        storageManager.saveItems(items)
    }

    private func addVaultItem(image: UIImage, title: String, category: String, tags: [String], notes: String?) {
        // Generate unique filename
        let filename = "\(UUID().uuidString).jpg"

        // Save image to documents directory
        guard storageManager.saveImage(image, filename: filename) else {
            print("Error saving image")
            return
        }

        // Create vault item
        let item = VaultItem(
            title: title,
            category: category,
            imageName: filename,
            tags: tags,
            notes: notes
        )

        // Add to items array and save
        items.insert(item, at: 0)
        saveItems()
    }
}

// MARK: - Category Pill
struct CategoryPill: View {
    let title: String
    let isSelected: Bool
    let count: Int
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(isSelected ? .semibold : .regular)

                Text("\(count)")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(isSelected ? Color.white.opacity(0.3) : Color.secondary.opacity(0.2))
                    .cornerRadius(8)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? Color.blue : Color(uiColor: .secondarySystemBackground))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(20)
        }
    }
}

// MARK: - Grid Card View
struct VaultItemGridCard: View {
    let item: VaultItem
    let storageManager: VaultStorageManager

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Thumbnail
            ZStack {
                Rectangle()
                    .fill(Color(uiColor: .tertiarySystemBackground))
                    .aspectRatio(1, contentMode: .fit)

                if let image = storageManager.loadImage(filename: item.imageName) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .clipped()
                } else {
                    Image(systemName: "photo")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary)
                }
            }
            .cornerRadius(12)

            // Title
            Text(item.title)
                .font(.subheadline)
                .fontWeight(.medium)
                .lineLimit(2)
                .foregroundColor(.primary)

            // Category
            HStack(spacing: 4) {
                Image(systemName: "folder.fill")
                    .font(.caption2)
                Text(item.category)
                    .font(.caption)
            }
            .foregroundColor(.blue)

            // Date
            Text(item.createdAt, style: .date)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(8)
        .background(Color(uiColor: .secondarySystemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

// MARK: - List Row View
struct VaultItemListRow: View {
    let item: VaultItem
    let storageManager: VaultStorageManager

    var body: some View {
        HStack(spacing: 12) {
            // Thumbnail
            ZStack {
                Rectangle()
                    .fill(Color(uiColor: .tertiarySystemBackground))
                    .frame(width: 80, height: 80)

                if let image = storageManager.loadImage(filename: item.imageName) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 80, height: 80)
                        .clipped()
                } else {
                    Image(systemName: "photo")
                        .font(.system(size: 30))
                        .foregroundColor(.secondary)
                }
            }
            .cornerRadius(8)

            // Details
            VStack(alignment: .leading, spacing: 6) {
                Text(item.title)
                    .font(.body)
                    .fontWeight(.medium)
                    .lineLimit(2)

                HStack(spacing: 4) {
                    Image(systemName: "folder.fill")
                        .font(.caption2)
                    Text(item.category)
                        .font(.caption)
                }
                .foregroundColor(.blue)

                // Tags
                if !item.tags.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(item.tags, id: \.self) { tag in
                                Text("#\(tag)")
                                    .font(.caption2)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 3)
                                    .background(Color.blue.opacity(0.1))
                                    .foregroundColor(.blue)
                                    .cornerRadius(6)
                            }
                        }
                    }
                }

                Text(item.createdAt, style: .date)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(uiColor: .secondarySystemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

#Preview {
    VaultView()
}
