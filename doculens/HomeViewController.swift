//
//  HomeViewController.swift
//  doculens
//
//  Created by sunderll on 2/12/25.
//

import UIKit
import CoreData

class HomeViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate {
    
    @IBOutlet weak var tablaRecientes: UITableView!
    
    @IBOutlet weak var searchBar: UISearchBar!
    
    
    var documentosRecientes: [Document] = []
    
    var documentosFiltrados: [Document] = []
    
    var isSearching = false
    
    lazy var context: NSManagedObjectContext = {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        return appDelegate.persistentContainer.viewContext
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tablaRecientes.delegate = self
        tablaRecientes.dataSource = self
        
        let longPress = UILongPressGestureRecognizer(
            target: self,
            action: #selector(handleLongPress(_:))
        )
        tablaRecientes.addGestureRecognizer(longPress)
        
        testDocuments()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        fetchDocumentosRecientes()
    }
    
    // MARK: - Datos para testeo
    private func testDocuments() {
        let request: NSFetchRequest<Document> = Document.fetchRequest()

        if let count = try? context.count(for: request), count > 0 {
            return
        }

        let doc = Document(context: context)
        doc.id = UUID()
        doc.title = "Factura Claro - Enero"
        doc.originalFilename = "factura_claro_enero.pdf"
        doc.mimeType = "application/pdf"
        doc.createdAt = Date()
        doc.filePath = "/tmp/factura_claro_enero.pdf"

        // Simulación de datos OCR
        let extracted: [String: String] = [
            "Empresa": "Claro Perú",
            "Monto": "S/ 89.90",
            "Fecha": "15/01/2025",
            "Cliente": "Juan Pérez"
        ]
        doc.extractedFields = try? JSONSerialization.data(
            withJSONObject: extracted,
            options: []
        )

        do {
            try context.save()
        } catch {
            print("Error creando documento de prueba:", error)
        }
    }
    
    // MARK: - Documentos Recientes Fetch
    func fetchDocumentosRecientes() {
        let request: NSFetchRequest<Document> = Document.fetchRequest()
        request.sortDescriptors = [
            NSSortDescriptor(key: "createdAt", ascending: false)
        ]
        request.fetchLimit = 5
        
        do {
            let resultados = try context.fetch(request)
            
            documentosRecientes = resultados
            
            tablaRecientes.reloadData()
        } catch {
            print("Error al cargar documentos recientes: \(error)")
        }
    }
    
    // MARK: - Long Press Menu
    @objc func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began else {return}
        
        let point = gesture.location(in: tablaRecientes)
        guard let indexPath = tablaRecientes.indexPathForRow(at: point) else {return}
        
        let document = documentosRecientes[indexPath.row]
        showMenuModal(for: document, indexPath: indexPath)
    }
    
    func showMenuModal(for document: Document, indexPath: IndexPath) {
        let alerta = UIAlertController(
            title: nil,
            message: nil,
            preferredStyle: .actionSheet
        )
        
        alerta.addAction(UIAlertAction(title: "Renombrar", style: .default) { _ in
            self.renameDocument(document)
        })
        
        alerta.addAction(UIAlertAction(title: "Compartir", style: .default) { _ in
            self.shareDocument(document)
        })
        
        alerta.addAction(UIAlertAction(title: "Eliminar", style: .destructive) { _ in
            self.deleteDocument(document, indexPath: indexPath)
        })
        
        alerta.addAction(UIAlertAction(title: "Cancelar", style: .cancel))
        
        present(alerta, animated: true)
    }
    
    // MARK: - Acciones del Modal Menu (Core Data)
    func renameDocument(_ document: Document) {
        let alert = UIAlertController(
            title: "Renombrar documento",
            message: nil,
            preferredStyle: .alert
        )

        alert.addTextField { textField in
            textField.text = document.title
        }

        alert.addAction(UIAlertAction(title: "Cancelar", style: .cancel))

        alert.addAction(UIAlertAction(title: "Guardar", style: .default) { [weak self] _ in
            guard let self = self, let nuevoTitulo = alert.textFields?.first?.text else {return}
            
            document.title = nuevoTitulo
            
            do {
                try self.context.save()
                
                self.tablaRecientes.reloadData()
            } catch {
                print("Error al renombrar el documento: \(error)")
            }
        })

        present(alert, animated: true)
    }

    func shareDocument(_ document: Document) {
        guard let path = document.filePath else {return}
        let url = URL(fileURLWithPath: path)
        
        // Pasamos url
        let activity = UIActivityViewController(
            activityItems: [url],
            applicationActivities: nil
        )
        present(activity, animated: true)
    }

    func deleteDocument(_ document: Document, indexPath: IndexPath) {
        // Borrar archivo del almacenamiento interno
        if let path = document.filePath {
            try? FileManager.default.removeItem(atPath: path)
        }
        
        // Borrar en Core Data
        context.delete(document)

        do {
            try context.save()

            // Actualizar la interfaz
            documentosRecientes.remove(at: indexPath.row)
            tablaRecientes.deleteRows(at: [indexPath], with: .automatic)
        } catch {
            print("Error al guardar en Core Data: \(error)")
        }
    }
    
    // MARK: - SearchBar Delegate
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        guard !searchText.isEmpty else {
            isSearching = false
            tablaRecientes.reloadData()
            return
        }
        
        isSearching = true
        documentosFiltrados = documentosRecientes.filter {
            ($0.title ?? "").localizedCaseInsensitiveContains(searchText)
        }
        
        tablaRecientes.reloadData()
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.text = ""
        searchBar.resignFirstResponder()
        
        isSearching = false
        tablaRecientes.reloadData()
    }
    
    // MARK: - TableView DataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return isSearching ? documentosFiltrados.count : documentosRecientes.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let celda = tableView.dequeueReusableCell(
            withIdentifier: "RecentCell",
            for: indexPath
        ) as! RecentCell
        
        let doc = isSearching ? documentosFiltrados[indexPath.row] : documentosRecientes[indexPath.row]
        
        celda.lblTitulo.text = doc.title
        celda.lblFecha.text = doc.formattedDate
        celda.lblPeso.text = doc.formattedSize
        celda.thumbnail.image = UIImage(systemName: "document.text.fill")
        
    // celda.thumbnail.contentMode = .scaleAspectFit
        
        return celda
    }
    
    
    // MARK: - TableView Delegate
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let doc = isSearching ? documentosFiltrados[indexPath.row] : documentosRecientes[indexPath.row]
        
        performSegue(withIdentifier: "segueDocDetalle", sender: doc)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "segueDocDetalle",
           let destino = segue.destination as? DocumentoDetalleViewController,
           let document = sender as? Document {
            destino.document = document
        }
    }
}
