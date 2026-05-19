//
//  PersistenceService.swift
//  PatientsSystem
//
//  Created by ITIT on 05/05/26.
//

import Foundation

struct PersistenceService {
    enum File: String {
        case patients = "patients.json"
        case appointments = "appointments.json"
        case profiles = "profiles.json"
    }

    private static func baseDirectory() throws -> URL {
        let fm = FileManager.default
        let appSupport = try fm.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let bundleId = Bundle.main.bundleIdentifier ?? "PatientsSystem"
        let dir = appSupport.appendingPathComponent(bundleId, isDirectory: true)
        if !fm.fileExists(atPath: dir.path) {
            try fm.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }

    private static func url(for file: File) throws -> URL {
        try baseDirectory().appendingPathComponent(file.rawValue)
    }

    static func load<T: Decodable>(_ type: T.Type, from file: File) throws -> T {
        let url = try url(for: file)
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(T.self, from: data)
    }

    static func save<T: Encodable>(_ value: T, to file: File) throws {
        let url = try url(for: file)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(value)
        try data.write(to: url, options: .atomic)
    }
}

