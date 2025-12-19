//
//  OCRService.swift
//  doculens
//
//  Created by sunderll on 19/12/25.
//

import Vision
import UIKit

final class OCRService {

    static func recognizeText(
        from image: UIImage,
        completion: @escaping ([String]) -> Void
    ) {

        guard let cgImage = image.cgImage else {
            completion([])
            return
        }

        let request = VNRecognizeTextRequest { request, error in
            guard error == nil else {
                completion([])
                return
            }

            let observations = request.results as? [VNRecognizedTextObservation] ?? []

            let lines = observations.compactMap {
                $0.topCandidates(1).first?.string
            }

            completion(lines)
        }

        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        request.recognitionLanguages = ["es"]

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])

        DispatchQueue.global(qos: .userInitiated).async {
            try? handler.perform([request])
        }
    }
}
