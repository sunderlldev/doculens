//
//  MainTabBarViewController+Import.swift
//  doculens
//
//  Created by sunderll on 18/12/25.
//

import PDFKit
import UIKit
import UniformTypeIdentifiers

extension MainTabBarViewController: UIImagePickerControllerDelegate,
    UINavigationControllerDelegate, UIDocumentPickerDelegate
{

    // MARK: - Camara / Galeria / Archivos
    func abrirCamara() {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            return
        }
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = self
        present(picker, animated: true)
    }

    func abrirGaleria() {
        let picker = UIImagePickerController()
        picker.sourceType = .photoLibrary
        picker.delegate = self
        present(picker, animated: true)
    }

    func abrirFiles() {
        let picker = UIDocumentPickerViewController(
            forOpeningContentTypes: [.pdf],
            asCopy: true
        )
        picker.delegate = self
        present(picker, animated: true)
    }

    // MARK: - ImagePicker Delegate
    func imagePickerController(
        _ picker: UIImagePickerController,
        didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey:
            Any]
    ) {
        guard let image = info[.originalImage] as? UIImage else { return }
        
        // Guardar archivo real
        let documentsURL = FileManager.default.urls(
            for: .documentDirectory,
            in: .userDomainMask
        ).first!

        let fileName = UUID().uuidString + ".jpg"
        let destinoURL = documentsURL.appendingPathComponent(fileName)

        guard let data = image.jpegData(compressionQuality: 0.8) else {
            return
        }

        do {
            try data.write(to: destinoURL)

            picker.dismiss(animated: true) {
                self.pedirTituloYCrearDoc(
                    path: destinoURL.path,
                    mimeType: "image/jpeg",
                    originalFilename: fileName,
                    thumbnailSourceImage: image,
                    extractedFields: nil
                )
            }
        } catch {
            Loader.hide()
            picker.dismiss(animated: true)
            print("Error al guardar imagen: \(error)")
        }
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }

    // MARK: - DocumentPicker Delegate
    func documentPicker(
        _ controller: UIDocumentPickerViewController,
        didPickDocumentsAt urls: [URL]
    ) {

        guard let sourceURL = urls.first else { return }

        let documentsURL = FileManager.default.urls(
            for: .documentDirectory,
            in: .userDomainMask
        ).first!

        let uniqueName = UUID().uuidString + "-" + sourceURL.lastPathComponent
        let destinoURL = documentsURL.appendingPathComponent(uniqueName)

        do {
            try FileManager.default.copyItem(at: sourceURL, to: destinoURL)

            Loader.show(in: self.view, message: "Procesando PDF...")
            
            let textoExtraido = PDFTextExtractor.extraerTexto(from: destinoURL)

            if textoExtraido.trimmingCharacters(in: .whitespacesAndNewlines)
                .isEmpty
            {
                if let image = PDFImageExtractor.firstPageAsImage(
                    from: destinoURL
                ) {
                    OCRService.recognizeText(from: image) { lines in
                        let extracted = OCRPostProcessor.extractFields(
                            from: lines
                        )

                        DispatchQueue.main.async {
                            Loader.hide()
                            
                            self.pedirTituloYCrearDoc(
                                path: destinoURL.path,
                                mimeType: "application/pdf",
                                originalFilename: uniqueName,
                                thumbnailSourceImage: image,
                                extractedFields: extracted
                            )
                        }
                    }
                }

            } else {
                let lines =
                    textoExtraido
                    .components(separatedBy: .newlines)
                    .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }

                let extracted = OCRPostProcessor.extractFields(from: lines)

                Loader.hide()
                
                self.pedirTituloYCrearDoc(
                    path: destinoURL.path,
                    mimeType: "application/pdf",
                    originalFilename: uniqueName,
                    thumbnailSourceImage: nil,
                    extractedFields: extracted
                )
            }

        } catch {
            print("Error al copiar PDF: \(error)")
        }
    }

    // MARK: - Core Data
    private func pedirTituloYCrearDoc(
        path: String,
        mimeType: String,
        originalFilename: String,
        thumbnailSourceImage: UIImage?,
        extractedFields: [String: String]?
    ) {

        let alerta = UIAlertController(
            title: "Nuevo documento",
            message: "Ingresa un título",
            preferredStyle: .alert
        )

        alerta.addTextField { tf in
            tf.placeholder = "Título del documento"
        }

        alerta.addAction(UIAlertAction(title: "Cancelar", style: .cancel))

        alerta.addAction(
            UIAlertAction(title: "Guardar", style: .default) { _ in
                let titulo = alerta.textFields?.first?.text?.trimmingCharacters(
                    in: .whitespacesAndNewlines
                )
                let finalTitle =
                    (titulo?.isEmpty == false)
                    ? titulo! : "Documento sin título"

                let thumbData = self.makeThumbnailData(
                    from: thumbnailSourceImage
                )

                if let image = thumbnailSourceImage {
                    Loader.show(in: self.view, message: "Escaneando imagen...")
                    
                    OCRService.recognizeText(from: image) { lines in
                        let extracted = OCRPostProcessor.extractFields(
                            from: lines
                        )

                        DispatchQueue.main.async {
                            Loader.hide()
                            self.createDocument(
                                title: finalTitle,
                                filePath: path,
                                mimeType: mimeType,
                                originalFilename: originalFilename,
                                thumbnail: thumbData,
                                extractedFields: extracted
                            )
                        }
                    }
                } else {
                    Loader.hide()
                    self.createDocument(
                        title: finalTitle,
                        filePath: path,
                        mimeType: mimeType,
                        originalFilename: originalFilename,
                        thumbnail: thumbData,
                        extractedFields: extractedFields
                    )
                }
            }
        )

        present(alerta, animated: true)
    }

    private func createDocument(
        title: String,
        filePath: String,
        mimeType: String,
        originalFilename: String,
        thumbnail: Data?,
        extractedFields: [String: String]?
    ) {
        let context = (UIApplication.shared.delegate as! AppDelegate)
            .persistentContainer.viewContext

        let doc = Document(context: context)
        doc.id = UUID()
        doc.title = title
        doc.filePath = filePath
        doc.mimeType = mimeType
        doc.originalFilename = originalFilename
        doc.createdAt = Date()
        doc.thumbnail = thumbnail

        if let extractedFields {
            doc.extractedFields = try? JSONSerialization.data(
                withJSONObject: extractedFields,
                options: []
            )
        }

        do {
            try context.save()
            NotificationCenter.default.post(name: .documentoCreado, object: nil)
        } catch {
            print("Error guardando documento: \(error)")
        }
    }

    // MARK: - Thumbnail Helper
    private func makeThumbnailData(from image: UIImage?) -> Data? {
        guard let image else { return nil }

        let size = CGSize(width: 80, height: 80)
        let renderer = UIGraphicsImageRenderer(size: size)
        let thumb = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: size))
        }
        return thumb.jpegData(compressionQuality: 0.7)
    }
}
