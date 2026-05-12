//
//  PatientsListView.swift
//  PatientsSystem
//
//  Created by ITIT on 05/05/26.
//

import SwiftUI

struct PatientsListView: View {
    @EnvironmentObject var store: PatientStore
    @Environment(\.selectedTab) private var selectedTab
    @State private var showingNewPatient = false
    @State private var searchText = ""

    var filteredPatients: [Patient] {
        guard !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return store.patients
        }
        return store.patients.filter {
            $0.nombre.localizedCaseInsensitiveContains(searchText)
            || $0.celular.localizedCaseInsensitiveContains(searchText)
            || $0.diagnostico.localizedCaseInsensitiveContains(searchText)
            || $0.estatus.rawValue.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        List {
            ForEach(filteredPatients) { patient in
                NavigationLink(value: patient) {
                    PatientRow(patient: patient)
                }
            }
            .onDelete(perform: store.remove)
        }
        .navigationDestination(for: Patient.self) { patient in
            PatientDetailView(patient: patient) { updated in
                store.update(updated)
            }
        }
        .navigationTitle("Pacientes")
        .searchable(text: $searchText, prompt: "Buscar por nombre, estatus, diagnóstico…")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingNewPatient = true
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Agregar paciente")
            }
        }
        .sheet(isPresented: $showingNewPatient) {
            NavigationStack {
                PatientDetailView(patient: Patient(
                    nombre: "",
                    celular: "",
                    estatus: .nuevo,
                    diagnostico: "",
                    proximaCita: nil,
                    notas: "",
                    fotoSystemName: nil
                )) { newPatient in
                    store.add(newPatient)
                }
                .navigationTitle("Nuevo paciente")
                .navigationBarTitleDisplayMode(.inline)
            }
        }
    }
}

private struct PatientRow: View {
    let patient: Patient

    var body: some View {
        HStack(spacing: 12) {
            if let data = patient.profilePhotoData, let ui = UIImage(data: data) {
                Image(uiImage: ui)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 40, height: 40)
                    .clipShape(Circle())
            } else {
                Image(systemName: patient.fotoSystemName ?? "person.crop.circle")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 40, height: 40)
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(patient.nombre.isEmpty ? "Sin nombre" : patient.nombre)
                    .font(.headline)
                Text(patient.estatus.rawValue)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationStack {
        PatientsListView()
            .environmentObject(PatientStore())
    }
}
