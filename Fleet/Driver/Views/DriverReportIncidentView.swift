import SwiftUI
import PhotosUI

struct DriverReportIncidentView: View {
    let trip: Trip
    
    @State private var viewModel = DriverReportIncidentViewModel()
    
    @State private var selectedType: TripIncidentType = .traffic
    @State private var customIncidentType: String = ""
    @State private var description: String = ""
    @State private var selectedPhotos: [PhotosPickerItem] = []
    @State private var capturedImages: [UIImage] = []
    
    @Environment(\.dismiss) private var dismiss
    
    private let maxDescriptionLength = 200
    
    var body: some View {
        ZStack {
            if viewModel.isSubmitted {
                successView
                    .transition(.opacity.combined(with: .scale(scale: 0.96)))
            } else {
                formContent
            }
        }
        .animation(.spring(response: 0.45, dampingFraction: 0.8), value: viewModel.isSubmitted)
        .navigationTitle("Report Incident")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                if viewModel.isSubmitting {
                    ProgressView()
                } else {
                    Button("Submit") { handleSubmit() }
                        .fontWeight(.semibold)
                        .disabled(description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .alert("Submission Error", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(viewModel.errorMessage ?? "An unknown error occurred.")
        }
        .onChange(of: selectedPhotos) { _, newItems in
            Task {
                for item in newItems {
                    if let data = try? await item.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        capturedImages.append(image)
                    }
                }
                selectedPhotos = []
            }
        }
    }
    
    private var formContent: some View {
        Form {
            Section {
                Picker("Incident Type", selection: $selectedType) {
                    ForEach(TripIncidentType.allCases, id: \.self) { type in
                        Label(type.rawValue, systemImage: type.icon)
                            .tag(type)
                    }
                }
                .pickerStyle(.navigationLink)
                
                if selectedType == .other {
                    TextField("Specify Incident Type", text: $customIncidentType)
                }
            } header: {
                Text("Incident Type")
            } footer: {
                Text("Select the type of incident affecting your trip.")
            }
            
            Section {
                ZStack(alignment: .topLeading) {
                    if description.isEmpty {
                        Text("Describe what happened…")
                            .foregroundStyle(Color(.placeholderText))
                            .padding(.top, 8)
                            .padding(.leading, 4)
                            .allowsHitTesting(false)
                    }
                    TextEditor(text: $description)
                        .frame(minHeight: 100)
                        .onChange(of: description) { _, newValue in
                            if newValue.count > maxDescriptionLength {
                                description = String(newValue.prefix(maxDescriptionLength))
                            }
                        }
                }
            } header: {
                Text("Description")
            } footer: {
                HStack {
                    Spacer()
                    Text("\(description.count)/\(maxDescriptionLength)")
                        .foregroundStyle(description.count > maxDescriptionLength - 20 ? .orange : Color(.tertiaryLabel))
                }
            }
            
            Section {
                if capturedImages.isEmpty {
                    PhotosPicker(
                        selection: $selectedPhotos,
                        maxSelectionCount: 3,
                        matching: .images,
                        photoLibrary: .shared()
                    ) {
                        Label("Add Photos", systemImage: "photo.badge.plus")
                    }
                } else {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(capturedImages.indices, id: \.self) { index in
                                ZStack(alignment: .topTrailing) {
                                    Image(uiImage: capturedImages[index])
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 80, height: 80)
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                    
                                    Button {
                                        capturedImages.remove(at: index)
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .symbolRenderingMode(.palette)
                                            .foregroundStyle(.white, .red)
                                            .font(.title3)
                                    }
                                    .padding(2)
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    
                    if capturedImages.count < 3 {
                        PhotosPicker(
                            selection: $selectedPhotos,
                            maxSelectionCount: 3 - capturedImages.count,
                            matching: .images,
                            photoLibrary: .shared()
                        ) {
                            Label("Add More Photos", systemImage: "photo.badge.plus")
                        }
                    }
                }
            } header: {
                Text("Optional Photos")
            } footer: {
                Text("Up to 3 photos. These will be included in the incident report.")
            }
        }
    }
    
    private var successView: some View {
        VStack(spacing: 32) {
            Spacer()
            
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 72))
                .foregroundStyle(.green)
                .symbolEffect(.bounce, value: viewModel.isSubmitted)
            
            VStack(spacing: 8) {
                Text("Incident Reported")
                    .font(.title2.bold())
                Text("Your incident has been logged.\nThe fleet manager has been notified.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
            
            Button(action: { dismiss() }) {
                Text("Done")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .tint(Color(.label))
            .padding(.horizontal, 32)
            .padding(.bottom, 40)
        }
    }
    
    private func handleSubmit() {
        let finalIncidentType = selectedType == .other && !customIncidentType.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty 
            ? customIncidentType 
            : selectedType.rawValue

        Task {
            viewModel.submitIncident(
                tripId: trip.id,
                driverId: trip.driverId,
                incidentType: finalIncidentType,
                description: description,
                images: capturedImages
            )
        }
    }
}
