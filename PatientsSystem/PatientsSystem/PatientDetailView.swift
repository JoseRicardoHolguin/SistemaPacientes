//
//  PatientDetailView.swift
//  PatientsSystem
//
//  Created by ITIT on 05/05/26.
//

import SwiftUI
import PhotosUI

struct PatientDetailView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var draft: Patient
    var onSave: (Patient) -> Void

    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var previewImageData: Data? = nil
    @State private var showPreview: Bool = false

    // Picker de foto de perfil
    @State private var profilePickerItem: PhotosPickerItem? = nil

    init(patient: Patient, onSave: @escaping (Patient) -> Void) {
        self._draft = State(initialValue: patient)
        self.onSave = onSave
    }

    var body: some View {
        Form {
            Section("Identificación") {
                TextField("Nombre", text: $draft.nombre)
                TextField("Celular", text: Binding(
                    get: { draft.celular },
                    set: { newValue in
                        draft.celular = newValue.filter { $0.isNumber }
                    }
                ))
                .keyboardType(.numberPad)

                Picker("Estatus", selection: $draft.estatus) {
                    ForEach(PatientStatus.allCases) { status in
                        Text(status.rawValue).tag(status)
                    }
                }
            }

            Section("Clínico") {
                TextField("Diagnóstico", text: $draft.diagnostico, axis: .vertical)
                    .lineLimit(1...3)

                DatePicker("Próxima cita",
                           selection: Binding(
                            get: { draft.proximaCita ?? Date() },
                            set: { draft.proximaCita = $0 }),
                           displayedComponents: .date)
                    .environment(\.locale, Locale(identifier: "es_MX"))
                    .tint(.accentColor)

                Toggle("Sin fecha definida", isOn: Binding(
                    get: { draft.proximaCita == nil },
                    set: { noDate in draft.proximaCita = noDate ? nil : Date() }
                ))
            }

            Section("Notas") {
                TextEditor(text: $draft.notas)
                    .frame(minHeight: 120)

                if !draft.fotos.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(Array(draft.fotos.enumerated()), id: \.offset) { index, data in
                                if let uiImage = UIImage(data: data) {
                                    ZStack(alignment: .topTrailing) {
                                        Image(uiImage: uiImage)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 100, height: 100)
                                            .clipped()
                                            .cornerRadius(8)
                                            .onTapGesture {
                                                previewImageData = data
                                                showPreview = true
                                            }

                                        Button {
                                            draft.fotos.remove(at: index)
                                        } label: {
                                            Image(systemName: "xmark.circle.fill")
                                                .foregroundStyle(.white, .black.opacity(0.6))
                                        }
                                        .offset(x: 6, y: -6)
                                    }
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }

                PhotosPicker(selection: $selectedItems,
                             maxSelectionCount: 10,
                             matching: .images,
                             preferredItemEncoding: .compatible,
                             photoLibrary: .shared()) {
                    Label("Agregar fotos", systemImage: "photo.on.rectangle")
                }
                .onChange(of: selectedItems) { _, newItems in
                    Task {
                        for item in newItems {
                            if let data = try? await item.loadTransferable(type: Data.self) {
                                draft.fotos.append(data)
                            }
                        }
                        selectedItems.removeAll()
                    }
                }
            }

            Section("Foto") {
                HStack(spacing: 12) {
                    if let data = draft.profilePhotoData, let uiImage = UIImage(data: data) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 64, height: 64)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(.secondary.opacity(0.3)))
                    } else {
                        Image(systemName: draft.fotoSystemName ?? "person.crop.circle")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 64, height: 64)
                            .foregroundStyle(.secondary)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        PhotosPicker(selection: $profilePickerItem, matching: .images) {
                            Label("Seleccionar foto de perfil", systemImage: "photo")
                        }
                        .onChange(of: profilePickerItem) { _, item in
                            guard let item else { return }
                            Task {
                                if let data = try? await item.loadTransferable(type: Data.self) {
                                    draft.profilePhotoData = data
                                }
                                profilePickerItem = nil
                            }
                        }

                        Button {
                            draft.profilePhotoData = nil
                        } label: {
                            Label("Usar icono de perfil", systemImage: "person.crop.circle")
                        }
                    }
                }

                if draft.profilePhotoData == nil {
                    Picker("Icono", selection: Binding(
                        get: { draft.fotoSystemName ?? "person.crop.circle" },
                        set: { draft.fotoSystemName = $0 }
                    )) {
                        Image(systemName: "person.crop.circle").tag("person.crop.circle")
                        Image(systemName: "person.crop.circle.fill").tag("person.crop.circle.fill")
                        Image(systemName: "person").tag("person")
                        Image(systemName: "person.fill").tag("person.fill")
                    }
                    .pickerStyle(.menu)
                }
            }
        }
        .navigationTitle(draft.nombre.isEmpty ? "Paciente" : draft.nombre)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Guardar") {
                    onSave(draft)
                    dismiss()
                }
                .disabled(draft.nombre.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .fullScreenCover(isPresented: $showPreview) {
            if let data = previewImageData, let uiImage = UIImage(data: data) {
                ImagePreviewView(image: uiImage) {
                    showPreview = false
                }
            } else {
                Color.black.ignoresSafeArea().onAppear { showPreview = false }
            }
        }
    }
}

private struct ImagePreviewView: View {
    let image: UIImage
    var onClose: () -> Void

    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .scaleEffect(scale)
                .offset(offset)
                .gesture(
                    MagnifyGesture()
                        .onChanged { value in
                            scale = max(1.0, min(4.0, lastScale * value.magnification))
                        }
                        .onEnded { _ in
                            lastScale = scale
                        }
                )
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            offset = CGSize(width: lastOffset.width + value.translation.width,
                                            height: lastOffset.height + value.translation.height)
                        }
                        .onEnded { _ in
                            lastOffset = offset
                        }
                )
                .animation(.easeOut(duration: 0.15), value: scale)
                .animation(.easeOut(duration: 0.15), value: offset)

            VStack {
                HStack {
                    Button {
                        onClose()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.title2.weight(.semibold))
                            .foregroundStyle(.white)
                            .padding(10)
                            .background(.black.opacity(0.4), in: Circle())
                    }
                    .padding(.leading)
                    .padding(.top, 12)
                    Spacer()
                }
                Spacer()
            }
        }
    }
}

#Preview {
    NavigationStack {
        PatientDetailView(patient: .example(with: UUID())) { _ in }
    }
}

