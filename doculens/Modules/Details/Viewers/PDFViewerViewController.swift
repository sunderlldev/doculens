//
//  PDFViewerViewController.swift
//  doculens
//
//  Created by sunderll on 22/12/25.
//

import PDFKit
import UIKit

class PDFViewerViewController: UIViewController {

    var pdfURL: URL!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configurarNav()
        cargarPDF()
    }
    
    private func configurarNav() {
        title = "Documento"
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .close, target: self, action: #selector(cerrarVisor)
        )
    }
    
    
    private func cargarPDF() {
        let pdfView = PDFView(frame: view.bounds)
        pdfView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        pdfView.autoScales = true
        pdfView.document = PDFDocument(url: pdfURL)
        
        view.addSubview(pdfView)
    }
    
    @objc private func cerrarVisor() {
        dismiss(animated: true)
    }
}
