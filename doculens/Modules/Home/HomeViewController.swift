//
//  HomeViewController.swift
//  doculens
//
//  Created by sunderll on 2/12/25.
//

import CoreData
import FirebaseAuth
import MessageUI
import UIKit

class HomeViewController: UIViewController, UITableViewDelegate,
    UITableViewDataSource, UISearchBarDelegate,
    MFMailComposeViewControllerDelegate
{

    @IBOutlet weak var tablaRecientes: UITableView!

    @IBOutlet weak var searchBar: UISearchBar!

    @IBOutlet weak var soporteButton: UIButton!
    
    @IBOutlet weak var emptyView: UIView!
    
    @IBOutlet weak var lblMensajeEmpty: UILabel!
    
    @IBOutlet weak var ivIconoEmpty: UIImageView!

    var documentosRecientes: [Document] = []

    var documentosFiltrados: [Document] = []

    var isSearching = false

    lazy var context: NSManagedObjectContext = {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        return appDelegate.persistentContainer.viewContext
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(recargarDocumentos),
            name: .documentoCreado,
            object: nil
        )

        tablaRecientes.delegate = self
        tablaRecientes.dataSource = self

        let longPress = UILongPressGestureRecognizer(
            target: self,
            action: #selector(handleLongPress(_:))
        )
        tablaRecientes.addGestureRecognizer(longPress)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        fetchDocumentosRecientes()
    }

    @objc private func recargarDocumentos() {
        fetchDocumentosRecientes()
    }
    
    // MARK: - Empty State Busqueda
    func actualizarEstadoBusqueda() {
        let totalItems = isSearching ? documentosFiltrados.count : documentosRecientes.count
        
        emptyView.isHidden = totalItems > 0
        
        if totalItems == 0 {
            if isSearching {
                lblMensajeEmpty.text = "No hay coincidencias"
                ivIconoEmpty.image = UIImage(systemName: "document.on.clipboard.fill")
            } else {
                lblMensajeEmpty.text = "No tienes ningún escaneo"
                ivIconoEmpty.image = UIImage(systemName: "document.viewfinder")
            }
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
            actualizarEstadoBusqueda()
        } catch {
            print("Error al cargar documentos recientes: \(error)")
        }
    }

    // MARK: - Long Press Menu
    @objc func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began else { return }

        let point = gesture.location(in: tablaRecientes)
        guard let indexPath = tablaRecientes.indexPathForRow(at: point) else {
            return
        }

        let document = documentosRecientes[indexPath.row]
        showMenuModal(for: document, indexPath: indexPath)
    }

    func showMenuModal(for document: Document, indexPath: IndexPath) {
        let alerta = UIAlertController(
            title: nil,
            message: nil,
            preferredStyle: .actionSheet
        )

        alerta.addAction(
            UIAlertAction(title: "Renombrar", style: .default) { _ in
                self.renameDocument(document)
            }
        )

        alerta.addAction(
            UIAlertAction(title: "Compartir", style: .default) { _ in
                self.shareDocument(document)
            }
        )

        alerta.addAction(
            UIAlertAction(title: "Eliminar", style: .destructive) { _ in
                self.deleteDocument(document, indexPath: indexPath)
            }
        )

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

        alert.addAction(
            UIAlertAction(title: "Guardar", style: .default) { [weak self] _ in
                guard let self = self,
                    let nuevoTitulo = alert.textFields?.first?.text
                else { return }

                document.title = nuevoTitulo

                do {
                    try self.context.save()

                    self.tablaRecientes.reloadData()
                } catch {
                    print("Error al renombrar el documento: \(error)")
                }
            }
        )

        present(alert, animated: true)
    }

    func shareDocument(_ document: Document) {
        guard let path = document.filePath else { return }
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
            
            actualizarEstadoBusqueda()
        } catch {
            print("Error al guardar en Core Data: \(error)")
        }
    }

    // MARK: - SearchBar Delegate
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        guard !searchText.isEmpty else {
            isSearching = false
            tablaRecientes.reloadData()
            actualizarEstadoBusqueda()
            return
        }

        isSearching = true
        documentosFiltrados = documentosRecientes.filter {
            ($0.title ?? "").localizedCaseInsensitiveContains(searchText)
        }

        tablaRecientes.reloadData()
        actualizarEstadoBusqueda()
    }

    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.text = ""
        searchBar.resignFirstResponder()

        isSearching = false
        tablaRecientes.reloadData()
        actualizarEstadoBusqueda()
    }

    // MARK: - TableView DataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int)
        -> Int
    {
        isSearching
            ? documentosFiltrados.count : documentosRecientes.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath)
        -> UITableViewCell
    {
        let celda = tableView.dequeueReusableCell(
            withIdentifier: "RecentCell",
            for: indexPath
        )

        let doc =
            isSearching
            ? documentosFiltrados[indexPath.row]
            : documentosRecientes[indexPath.row]

        celda.textLabel?.text = doc.title
        celda.detailTextLabel?.text =
            "\(doc.formattedDate) - \(doc.formattedSize)"

        celda.imageView?.image = UIImage(systemName: "doc.text")

        DispatchQueue.global(qos: .userInitiated).async {
            var image: UIImage? = nil

            if let data = doc.thumbnail {
                image = UIImage(data: data)
            }

            DispatchQueue.main.async {
                if let celdaVisible = tableView.cellForRow(at: indexPath) {
                    celdaVisible.imageView?.image =
                        image ?? UIImage(systemName: "doc.text")
                    celdaVisible.setNeedsLayout()
                }
            }
        }

        celda.imageView?.contentMode = .scaleToFill
        celda.imageView?.clipsToBounds = true
        celda.accessoryType = .disclosureIndicator

        return celda
    }

    // MARK: - TableView Delegate
    func tableView(
        _ tableView: UITableView,
        didSelectRowAt indexPath: IndexPath
    ) {
        tableView.deselectRow(at: indexPath, animated: true)

        let doc =
            isSearching
            ? documentosFiltrados[indexPath.row]
            : documentosRecientes[indexPath.row]

        performSegue(withIdentifier: "segueDocDetalle", sender: doc)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "segueDocDetalle",
            let destino = segue.destination as? DocumentoDetalleViewController,
            let document = sender as? Document
        {
            destino.document = document
        }
    }

    // MARK: - Enviar correo a soporte / MFMailCompose Delegate
    @IBAction func soporteButtonTapped(_ sender: UIButton) {
        enviarCorreoSoporte()
    }

    func enviarCorreoSoporte() {
        guard MFMailComposeViewController.canSendMail() else {
            alertaError()
            return
        }
        
        let correo = MFMailComposeViewController()
        correo.mailComposeDelegate = self
        
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        
        var userID = ""
        
        if let firebaseUserID = Auth.auth().currentUser {
            userID = "FireBaseID: \(firebaseUserID.uid)"
        } else {
            let deviceID = UIDevice.current.identifierForVendor?.uuidString ?? "Desconocido"
            userID = "GuestDeviceID: \(deviceID)"
        }

        correo.setToRecipients(["soporte@doculens.com"])
        correo.setSubject("Soporte Tecnico - DocuLens iOS (\(version))")

        let mensajeBody = """
        Hola equipo de soporte de Doculens,
        
        [Escribe tu mensaje aqui]
        
        -----------------------------------
        INFORMACION DEL USUARIO:
        Usuario: \(userID)
        Version: \(version)
        Dispositivo: \(UIDevice.current.model) - iOS \(UIDevice.current.systemVersion)
        -----------------------------------
        """
        
        correo.setMessageBody(mensajeBody, isHTML: false)
        present(correo, animated: true)
    }
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true, completion: nil)
    }
    
    func alertaError() {
        let alerta = UIAlertController(
            title: "Correo no disponible",
            message: "Por favor, configura tu correo para poder enviar un reporte de error",
            preferredStyle: .alert
        )
        alerta.addAction(UIAlertAction(title: "Aceptar", style: .default))
        present(alerta, animated: true)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
