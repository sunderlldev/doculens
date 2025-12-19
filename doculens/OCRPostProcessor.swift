//
//  OCRPostProcessor.swift
//  doculens
//
//  Created by sunderll on 19/12/25.
//

import UIKit

final class OCRPostProcessor {
    
    private static let rucRegex = try? NSRegularExpression(pattern: #"(?:RUC|R\.U\.C\.?)[:\s]*(\d{11})"#)

    private static let dateRegex = try? NSRegularExpression(pattern: #"\d{2}[/-]\d{2}[/-]\d{4}"#)

    private static let amountRegex = try? NSRegularExpression(pattern: #"(?:S\/|S\.|USD|\$)?\s*\d{1,3}(?:,\d{3})*(?:\.\d{2})"#)

    static func extractFields(from lines: [String]) -> [String: String] {
        
        let normalized = normalize(lines: lines)
        let upper = normalized.map { $0.uppercased() }
        
        var result: [String: String] = [:]

        // Lógica de extracción
        if let ruc = extractRUC(from: upper) {
            result["RUC"] = ruc
        }

        if let date = extractDate(from: upper) {
            result["Fecha"] = date
        }

        if let amount = extractAmount(from: upper) {
            result["Monto"] = amount
        } else {
        }
        
        if result.isEmpty {
            result["Info"] = "No se detectaron datos. Intente tomar una foto mejor iluminada"
        }

        return result
    }

    // MARK: - Helpers
    private static func normalize(lines: [String]) -> [String] {
        var result: [String] = []
        var buffer = ""

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            if trimmed.isEmpty { continue }

            if buffer.isEmpty {
                buffer = trimmed
            } else if trimmed.first?.isNumber == true || trimmed.contains("/") || trimmed.contains("S/") {
                buffer += " " + trimmed
                result.append(buffer)
                buffer = ""
            } else {
                result.append(buffer)
                buffer = trimmed
            }
        }

        if !buffer.isEmpty {
            result.append(buffer)
        }

        return result
    }
    
    private static func extractRUC(from lines: [String]) -> String? {
        guard let regex = rucRegex else { return nil }
        
        for line in lines {
            let range = NSRange(line.startIndex..., in: line)
            if let match = regex.firstMatch(in: line, range: range) {
                return (line as NSString).substring(with: match.range(at: 1))
            }
        }
        return nil
    }
    
    private static func extractDate(from lines: [String]) -> String? {
        guard let regex = dateRegex else { return nil }
        
        let priorityLines = lines.filter { $0.contains("EMISION") || $0.contains("FECHA") }
        let otherLines = lines.filter { !$0.contains("EMISION") && !$0.contains("FECHA") }
        
        // Buscar primero en líneas prioritarias para evitar fecha de vencimiento
        for line in (priorityLines + otherLines) {
            let range = NSRange(line.startIndex..., in: line)
            if let match = regex.firstMatch(in: line, range: range) {
                return (line as NSString).substring(with: match.range)
            }
        }
        return nil
    }

    private static func extractAmount(from lines: [String]) -> String? {
        guard let regex = amountRegex else { return nil }
        
        let keywords = ["TOTAL", "IMPORTE", "PAGAR", "VENTA"]
        
        for line in lines {
            // Verificar si la linea contiene alguna keyword
            if keywords.contains(where: { line.contains($0) }) {
                let range = NSRange(line.startIndex..., in: line)
                if let match = regex.firstMatch(in: line, range: range) {
                    return (line as NSString).substring(with: match.range)
                }
            }
        }
        return nil
    }
}
