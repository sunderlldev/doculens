//
//  Document+Helpers.swift
//  doculens
//
//  Created by sunderll on 18/12/25.
//

import Foundation

extension Document {
    var formattedDate: String {
        createdAt?.formatted(date: .numeric, time: .omitted) ?? "--.--.----"
    }

    var formattedSize: String {
        guard let filePath, !filePath.isEmpty else { return "--" }
        let url = URL(fileURLWithPath: filePath)

        do {
            let values = try url.resourceValues(forKeys: [.fileSizeKey])
            if let bytes = values.fileSize {
                return ByteCountFormatter.string(
                    fromByteCount: Int64(bytes),
                    countStyle: .file
                )
            }
        } catch {
            print("Error al lerr el tamano del archivo: \(error)")
        }

        return "--"
    }
}
