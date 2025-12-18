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
    
    override func viewDidLoad() {
        super.viewDidLoad()

        UIConfig()
        loadExtractedFields()
    }
    
    private func UIConfig() {
        guard let document else {return}
        
        lblTitulo.text = "Titulo: \(document.title ?? "")"
        lblFecha.text = "Fecha de subida: \(document.formattedDate)"
        lblPeso.text = "Peso del archivo: \(document.formattedSize)"
        imageView.image = UIImage(systemName: "doc.text.fill")
    }
    
    private func loadExtractedFields() {
        guard
            let data = document?.extractedFields,
            let json = try? JSONSerialization.jsonObject(with: data) as? [String: String]
        else {
            txtDatos.text = "No hay datos extraidos"
            return
        }
        
        txtDatos.text = json
            .map { "- \($0.key): \($0.value)" }
            .joined(separator: "\n")
    }
}
