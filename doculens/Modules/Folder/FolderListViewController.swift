//
//  FolderListViewController.swift
//  doculens
//
//  Created by sunderll on 22/12/25.
//

import CoreData
import UIKit

class FolderListViewController: UIViewController, UITableViewDataSource,
    UITableViewDelegate, UISearchBarDelegate
{

    @IBOutlet weak var tvFolders: UITableView!

    @IBOutlet weak var emptyView: UIView!

    @IBOutlet weak var searchBar: UISearchBar!

    @IBOutlet weak var lblMensajeEmpty: UILabel!

    @IBOutlet weak var ivIconoEmpty: UIImageView!

    var folders: [Folder] = []

    var foldersFiltrados: [Folder] = []

    var isSearching = false

    lazy var context: NSManagedObjectContext = {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        return appDelegate.persistentContainer.viewContext
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        tvFolders.delegate = self
        tvFolders.dataSource = self
        searchBar.delegate = self

        configurarUI()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(recargarFolders),
            name: .folderCreado,
            object: nil
        )

        let longPress = UILongPressGestureRecognizer(
            target: self,
            action: #selector(handleLongPress(_:))
        )

        tvFolders.addGestureRecognizer(longPress)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        fetchFolders()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    private func configurarUI() {
        title = "Folders"

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .add,
            target: self,
            action: #selector(crearCarpeta)
        )
    }

    private func fetchFolders() {
        let request: NSFetchRequest<Folder> = Folder.fetchRequest()
        request.sortDescriptors = [
            NSSortDescriptor(key: "createdAt", ascending: true)
        ]

        do {
            folders = try context.fetch(request)
            tvFolders.reloadData()
            actualizarEmptyState()
        } catch {
            print("Error al buscar folders: \(error)")
        }
    }

    @objc func recargarFolders() {
        fetchFolders()
    }

    // MARK: - Empty State
    func actualizarEmptyState() {
        let total = isSearching ? foldersFiltrados.count : folders.count
        emptyView.isHidden = total > 0

        if total == 0 {
            lblMensajeEmpty.text =
                isSearching
                ? "No hay folders con ese nombre"
                : "No tienes ningun folder creado"
            ivIconoEmpty.image = UIImage(systemName: "questionmark.folder")
        }
    }

    // MARK: - Actions
    @objc func crearCarpeta() {
        let alert = UIAlertController(
            title: "Nueva carpeta",
            message: nil,
            preferredStyle: .alert
        )

        alert.addTextField { tf in
            tf.placeholder = "Nombre de la carpeta"
        }

        alert.addAction(UIAlertAction(title: "Cancelar", style: .cancel))

        alert.addAction(
            UIAlertAction(title: "Crear", style: .default) { _ in
                guard let nombre = alert.textFields?.first?.text,
                    !nombre.trimmingCharacters(in: .whitespaces).isEmpty
                else { return }

                let folder = Folder(context: self.context)
                folder.id = UUID()
                folder.name = nombre
                folder.createdAt = Date()

                do {
                    try self.context.save()
                    NotificationCenter.default.post(
                        name: .folderCreado,
                        object: nil
                    )
                } catch {
                    print("Error creando carpeta: \(error)")
                }
            }
        )

        present(alert, animated: true)
    }

    // MARK: - Long Press Menu
    @objc func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began else { return }

        let point = gesture.location(in: tvFolders)
        guard let indexPath = tvFolders.indexPathForRow(at: point) else {
            return
        }

        let folder =
            isSearching
            ? foldersFiltrados[indexPath.row] : folders[indexPath.row]
        mostrarMenu(folder: folder, indexPath: indexPath)
    }

    func mostrarMenu(folder: Folder, indexPath: IndexPath) {
        let alerta = UIAlertController(
            title: folder.name,
            message: nil,
            preferredStyle: .actionSheet
        )

        alerta.addAction(
            UIAlertAction(title: "Renombrar", style: .default) { _ in
                self.renombrarFolder(folder)
            }
        )

        alerta.addAction(
            UIAlertAction(title: "Eliminar", style: .destructive) { _ in
                self.eliminarFolder(folder, indexPath: indexPath)
            }
        )

        alerta.addAction(UIAlertAction(title: "Cancelar", style: .cancel))
        present(alerta, animated: true)
    }

    // MARK: - Acciones Folder
    func renombrarFolder(_ folder: Folder) {
        let alert = UIAlertController(
            title: "Renombrar carpeta",
            message: nil,
            preferredStyle: .alert
        )

        alert.addTextField { tf in
            tf.text = folder.name
        }

        alert.addAction(UIAlertAction(title: "Cancelar", style: .cancel))

        alert.addAction(
            UIAlertAction(title: "Guardar", style: .default) { _ in
                guard let nuevoNombre = alert.textFields?.first?.text else {
                    return
                }

                folder.name = nuevoNombre

                do {
                    try self.context.save()
                    self.fetchFolders()
                } catch {
                    print("Error renombrando folder: \(error)")
                }
            }
        )

        present(alert, animated: true)
    }

    func eliminarFolder(_ folder: Folder, indexPath: IndexPath) {
        context.delete(folder)

        do {
            try context.save()

            if isSearching {
                foldersFiltrados.remove(at: indexPath.row)
            } else {
                folders.remove(at: indexPath.row)
            }

            tvFolders.deleteRows(at: [indexPath], with: .automatic)
            actualizarEmptyState()
        } catch {
            print("Error eliminando folder: \(error)")
        }
    }

    // MARK: - SearchBar Delegate
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        guard !searchText.isEmpty else {
            isSearching = false
            tvFolders.reloadData()
            actualizarEmptyState()
            return
        }

        isSearching = true
        foldersFiltrados = folders.filter {
            ($0.name ?? "").localizedCaseInsensitiveContains(searchText)
        }

        tvFolders.reloadData()
        actualizarEmptyState()
    }

    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.text = ""
        searchBar.resignFirstResponder()
        isSearching = false
        tvFolders.reloadData()
        actualizarEmptyState()
    }

    // MARK: - TableView DataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int)
        -> Int
    {
        isSearching ? foldersFiltrados.count : folders.count
    }

    func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath
    ) -> UITableViewCell {

        let celda = tableView.dequeueReusableCell(
            withIdentifier: "FolderCell",
            for: indexPath
        )

        let folder =
            isSearching
            ? foldersFiltrados[indexPath.row]
            : folders[indexPath.row]

        celda.textLabel?.text = folder.name
        celda.imageView?.image = UIImage(systemName: "folder")
        celda.accessoryType = .disclosureIndicator

        return celda
    }

    // MARK: - TableView Delegate
    func tableView(
        _ tableView: UITableView,
        didSelectRowAt indexPath: IndexPath
    ) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let folder = isSearching ? foldersFiltrados[indexPath.row] : folders[indexPath.row]
        
        performSegue(withIdentifier: "segueFolderAFiles", sender: folder)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "segueFolderAFiles",
           let destino = segue.destination as? FilesViewController,
           let folder = sender as? Folder {
            destino.folderSeleccionado = folder
        }
    }
}
