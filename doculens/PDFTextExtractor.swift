//
//  PDFTextExtractor.swift
//  doculens
//
//  Created by sunderll on 19/12/25.
//

import PDFKit

final class PDFTextExtractor {
    static func extraerTexto(from url: URL) -> String {
        guard let pdf = PDFDocument(url: url) else { return "" }
        
        var texto = ""
        
        for pageIndex in 0..<pdf.pageCount {
            if let page = pdf.page(at: pageIndex),
               let pageText = page.string {
                texto += pageText + "\n"
            }
        }
        return texto
    }
}
