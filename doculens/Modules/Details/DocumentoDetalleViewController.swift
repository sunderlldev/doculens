//
//  DocumentoDetalleViewController.swift
//  doculens
//
//  Created by sunderll on 18/12/25.
//

import UIKit

class DocumentoDetalleViewController: UIViewController {

    var document: Document?

    @IBOutlet weak var imageView: UIImageView!

    @IBOutlet weak var lblTitulo: UILabel!

    @IBOutlet weak var lblFecha: UILabel!

    @IBOutlet weak var lblPeso: UILabel!

    @IBOutlet weak var txtDatos: UITextView!

    @IBOutlet weak var exportarComoPDFButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()

        UIConfig()
        cargarDatosExtraidos()

        exportarComoPDFButton.isHidden = document?.mimeType == "application/pdf"
    }
    
    private func UIConfig() {
        guard let document else { return }

        lblTitulo.text = "Titulo: \(document.title ?? "")"
        lblFecha.text = "Fecha de subida: \(document.formattedDate)"
        lblPeso.text = "Peso del archivo: \(document.formattedSize)"

        if document.mimeType?.starts(with: "image") == true,
            let path = document.filePath,
            FileManager.default.fileExists(atPath: path)
        {
            imageView.image = UIImage(contentsOfFile: path)
        } else if let thumb = document.thumbnail {
            imageView.image = UIImage(data: thumb)
        } else {
            imageView.image = UIImage(systemName: "doc.text")
        }

        imageView.contentMode = .scaleAspectFit
    }

    // MARK: - Extraer Data
    private func cargarDatosExtraidos() {
        guard
            let data = document?.extractedFields,
            let json = try? JSONSerialization.jsonObject(with: data)
                as? [String: String], !json.isEmpty
        else {
            txtDatos.text = "No hay datos extraidos"
            return
        }

        txtDatos.text =
            json
            .map { "- \($0.key): \($0.value)" }
            .joined(separator: "\n")
    }
    
    func generarPDFdeImagen(_ imagen: UIImage) -> URL? {
        let pdfRenderer = UIGraphicsPDFRenderer(
            bounds: CGRect(
                origin: .zero,
                size: imagen.size
            )
        )

        let documentoURL = FileManager.default.urls(
            for: .documentDirectory,
            in: .userDomainMask
        ).first!

        let pdfURL = documentoURL.appendingPathComponent(
            "\(document?.title ?? "Documento").pdf"
        )

        do {
            try pdfRenderer.writePDF(to: pdfURL) { context in
                context.beginPage()
                imagen.draw(in: CGRect(origin: .zero, size: imagen.size))
            }
            return pdfURL
        } catch {
            print("Error al crear el PDF: \(error)")
            return nil
        }
    }

    func compartirArchivo(url: URL) {
        let activityVC = UIActivityViewController(
            activityItems: [url],
            applicationActivities: nil
        )

        present(activityVC, animated: true)
    }
    
    // MARK: - Viewers
    func abrirPDF(url: URL) {
        let vc = PDFViewerViewController()
        vc.pdfURL = url
        
        let nav = UINavigationController(rootViewController: vc)
        nav.modalPresentationStyle = .fullScreen
        present(nav, animated: true)
    }

    func abrirImagen(url: URL) {
        let vc = ImageViewerViewController()
        vc.imageURL = url
        
        let nav = UINavigationController(rootViewController: vc)
        nav.modalPresentationStyle = .fullScreen
        
        present(nav, animated: true)
    }
    
    // MARK: - Actions (Exportar PDF, Compartir, Visualizar)
    @IBAction func exportarComoPDFButtonTapped(_ sender: UIButton) {
        guard document?.mimeType == "image/jpeg" else { return }

        Loader.show(in: self.view, message: "Generando PDF...")
        
        let imagenURL = URL(fileURLWithPath: document?.filePath ?? "")
        guard let imagen = UIImage(contentsOfFile: imagenURL.path) else {
            alerta("No se pudo cargar la imagen")
            return
        }

        if let pdfURL = generarPDFdeImagen(imagen) {
            DispatchQueue.main.async {
                Loader.hide()
                self.compartirArchivo(url: pdfURL)
            }
        } else {
            DispatchQueue.main.async {
                Loader.hide()
                self.alerta("No se pudo generar el PDF")
            }
        }
    }

    @IBAction func verDocumentoButtonTapped(_ sender: UIButton) {
        let url = URL(fileURLWithPath: document?.filePath ?? "")

        if document?.mimeType == "application/pdf" {
            abrirPDF(url: url)
        } else if (document?.mimeType?.starts(with: "image")) != nil {
            abrirImagen(url: url)
        }
    }

    @IBAction func compartirDocumentoButtonTapped(_ sender: UIButton) {
        guard let path = document?.filePath else { return }
        let url = URL(fileURLWithPath: path)

        let activityVC = UIActivityViewController(
            activityItems: [url],
            applicationActivities: nil
        )

        present(activityVC, animated: true)
    }

    // MARK: - Alerta
    func alerta(_ mensaje: String) {
        let alerta = UIAlertController(
            title: "Error",
            message: mensaje,
            preferredStyle: .alert
        )
        alerta.addAction(
            UIAlertAction(
                title: "OK",
                style: .default,
                handler: nil
            )
        )

        present(alerta, animated: true)
    }
}
