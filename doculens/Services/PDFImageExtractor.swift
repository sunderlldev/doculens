//
//  PDFImageExtractor.swift
//  doculens
//
//  Created by sunderll on 19/12/25.
//

import PDFKit
import UIKit

final class PDFImageExtractor {

    static func firstPageAsImage(from url: URL) -> UIImage? {
        guard let pdf = PDFDocument(url: url),
              let page = pdf.page(at: 0) else { return nil }

        let pageRect = page.bounds(for: .mediaBox)

        let renderer = UIGraphicsImageRenderer(size: pageRect.size)
        return renderer.image { ctx in
            UIColor.white.set()
            ctx.fill(pageRect)
            ctx.cgContext.translateBy(x: 0, y: pageRect.size.height)
            ctx.cgContext.scaleBy(x: 1, y: -1)
            page.draw(with: .mediaBox, to: ctx.cgContext)
        }
    }
}
