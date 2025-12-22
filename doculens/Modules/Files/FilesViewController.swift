//
//  FilesViewController.swift
//  doculens
//
//  Created by sunderll on 4/12/25.
//

import CoreData
import UIKit

class FilesViewController: UIViewController, UICollectionViewDelegate,
    UICollectionViewDataSource, UICollectionViewDelegateFlowLayout,
    UISearchBarDelegate
{

    @IBOutlet weak var cvDocumentos: UICollectionView!

    @IBOutlet weak var searchBar: UISearchBar!

    @IBOutlet weak var emptyView: UIView!

    @IBOutlet weak var lblMensajeEmpty: UILabel!

    @IBOutlet weak var ivIconoEmpty: UIImageView!

    var documentos: [Document] = []

    var documentosFiltrados: [Document] = []

    var folderSeleccionado: Folder?

    var tagsSeleccionados: Set<Tag> = []

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

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(recargarDocumentos),
            name: .documentoActualizado,
            object: nil
        )

        cvDocumentos.delegate = self
        cvDocumentos.dataSource = self

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "tag"),
            style: .plain,
            target: self,
            action: #selector(mostrarFiltroTags)
        )

        // Para evitar errores de autosizing
        if let layout = cvDocumentos.collectionViewLayout
            as? UICollectionViewFlowLayout
        {
            layout.estimatedItemSize = .zero
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        fetchDocumentos()
    }

    @objc private func recargarDocumentos() {
        fetchDocumentos()
    }

    @objc func mostrarFiltroTags() {
        let request: NSFetchRequest<Tag> = Tag.fetchRequest()
        let tags = (try? context.fetch(request)) ?? []

        let alert = UIAlertController(
            title: "Filtrar por tags",
            message: "Selecciona uno o mas",
            preferredStyle: .actionSheet
        )

        for tag in tags {
            let seleccionado = tagsSeleccionados.contains(tag)
            let titulo = seleccionado ? "✓ \(tag.name ?? "")" : (tag.name ?? "")

            alert.addAction(
                UIAlertAction(title: titulo, style: .default) { _ in
                    if self.tagsSeleccionados.contains(tag) {
                        self.tagsSeleccionados.remove(tag)
                    } else {
                        self.tagsSeleccionados.insert(tag)
                    }
                    self.mostrarFiltroTags()
                }
            )
        }

        alert.addAction(
            UIAlertAction(title: "Aplicar filtros", style: .default) { _ in
                self.fetchDocumentos()
            }
        )

        alert.addAction(
            UIAlertAction(title: "Limpiar filtros", style: .destructive) { _ in
                self.tagsSeleccionados.removeAll()
                self.fetchDocumentos()
            }
        )

        alert.addAction(UIAlertAction(title: "Cancelar", style: .cancel))
        present(alert, animated: true)
    }

    // MARK: - Empty State Busqueda
    func actualizarEstadoBusqueda() {
        let totalItems =
            isSearching ? documentosFiltrados.count : documentos.count

        emptyView.isHidden = totalItems > 0

        if isSearching && totalItems == 0 {
            lblMensajeEmpty.text =
                isSearching
                ? "No hay coincidencias" : "No tienes ningún escaneo"
            ivIconoEmpty.image =
                isSearching
                ? UIImage(systemName: "document.on.clipboard.fill")
                : UIImage(systemName: "document.viewfinder")
        }
    }

    // MARK: - Todos los Documentos Fetch
    func fetchDocumentos() {
        title = "Documentos"

        let request: NSFetchRequest<Document> = Document.fetchRequest()
        var predicates: [NSPredicate] = []

        if let folderSeleccionado {
            predicates.append(
                NSPredicate(
                    format: "folder == %@",
                    folderSeleccionado
                )
            )
            title = folderSeleccionado.name
        }

        if !tagsSeleccionados.isEmpty {
            predicates.append(
                NSPredicate(
                    format: "SUBQUERY(tags, $t, $t in %@).@count > 0",
                    tagsSeleccionados
                )
            )
            title =
                tagsSeleccionados
                .compactMap { $0.name }
                .joined(separator: ", ")
        }

        if !predicates.isEmpty {
            request.predicate = NSCompoundPredicate(
                andPredicateWithSubpredicates: predicates
            )
        }

        request.sortDescriptors = [
            NSSortDescriptor(key: "createdAt", ascending: false)
        ]

        // Para actualizar cada 10 archivos
        request.fetchBatchSize = 10

        do {
            documentos = try context.fetch(request)
            cvDocumentos.reloadData()
            actualizarEstadoBusqueda()
        } catch {
            print("Error al cargar los documentos: \(error)")
        }
    }

    // MARK: - SearchBar Delegate
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        guard !searchText.isEmpty else {
            isSearching = false
            cvDocumentos.reloadData()
            actualizarEstadoBusqueda()
            return
        }

        isSearching = true
        documentosFiltrados = documentos.filter {
            ($0.title ?? "").localizedCaseInsensitiveContains(searchText)
        }

        cvDocumentos.reloadData()
        actualizarEstadoBusqueda()
    }

    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.text = ""
        searchBar.resignFirstResponder()
        isSearching = false
        cvDocumentos.reloadData()
        actualizarEstadoBusqueda()
    }

    // MARK: - CollectionView DataSource
    func collectionView(
        _ collectionView: UICollectionView,
        numberOfItemsInSection section: Int
    ) -> Int {
        isSearching ? documentosFiltrados.count : documentos.count
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        let celda =
            cvDocumentos.dequeueReusableCell(
                withReuseIdentifier: "FileGridCell",
                for: indexPath
            ) as! FileGridCell

        let doc =
            isSearching
            ? documentosFiltrados[indexPath.row] : documentos[indexPath.row]

        celda.lblTitulo.text = doc.title
        celda.lblFechaPeso.text = "\(doc.formattedDate) - \(doc.formattedSize)"

        celda.thumbnail.image = UIImage(systemName: "doc.text.fill")
        celda.thumbnail.layer.cornerRadius = 10

        if let data = doc.thumbnail {
            DispatchQueue.global(qos: .userInitiated).async {
                let image = UIImage(data: data)
                DispatchQueue.main.async {
                    if let celdaActual = collectionView.cellForItem(
                        at: indexPath
                    ) as? FileGridCell {
                        celdaActual.thumbnail.image = image
                    }
                }
            }
        }

        return celda
    }

    // MARK: - CollectionView Delegate
    func collectionView(
        _ collectionView: UICollectionView,
        didSelectItemAt indexPath: IndexPath
    ) {
        let docSelec =
            isSearching
            ? documentosFiltrados[indexPath.row] : documentos[indexPath.row]

        performSegue(
            withIdentifier: "segueDocDetalleDesdeFiles",
            sender: docSelec
        )
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "segueDocDetalleDesdeFiles",
            let destino = segue.destination as? DocumentoDetalleViewController,
            let documento = sender as? Document
        {
            destino.document = documento
        }
    }

    // MARK: - CollectionView Delegate Flow Layout (Layout del grid)

    // Espacio entre columnas (Horizontal)
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        minimumInteritemSpacingForSectionAt section: Int
    ) -> CGFloat {
        20
    }

    // Espacio entre filas (Vertical)
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        minimumLineSpacingForSectionAt section: Int
    ) -> CGFloat {
        20
    }

    // Margenes del CollectionView con la pantalla
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        insetForSectionAt section: Int
    ) -> UIEdgeInsets {
        UIEdgeInsets(top: 20, left: 25, bottom: 20, right: 25)
    }

    // Size de cada celda
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        let columnas: CGFloat = 3
        let margenTotal: CGFloat = 50
        let espacioEntreCeldas: CGFloat = 25 * (columnas - 1)

        let anchoDisponible =
            cvDocumentos.frame.width - margenTotal - espacioEntreCeldas
        let anchoFinal = anchoDisponible / columnas

        return CGSize(width: anchoFinal, height: anchoFinal + 50)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Collection ContextMenu
    func collectionView(
        _ collectionView: UICollectionView,
        contextMenuConfigurationForItemAt indexPath: IndexPath,
        point: CGPoint
    ) -> UIContextMenuConfiguration? {
        let doc =
            isSearching
            ? documentosFiltrados[indexPath.row] : documentos[indexPath.row]

        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil)
        { _ in
            self.menuParaDocumento(doc, indexPath: indexPath)
        }
    }

    // MARK: - Menu Documento
    func menuParaDocumento(_ document: Document, indexPath: IndexPath) -> UIMenu
    {

        let tags = UIAction(
            title: "Asignar tags",
            image: UIImage(systemName: "tag")
        ) { _ in
            self.asignarTagsADocumento(document)
        }

        let renombrar = UIAction(
            title: "Renombrar",
            image: UIImage(systemName: "pencil")
        ) { _ in
            self.renameDocument(document)
        }

        let compartir = UIAction(
            title: "Compartir",
            image: UIImage(systemName: "square.and.arrow.up")
        ) { _ in
            self.shareDocument(document)
        }

        let quitarTags = UIAction(
            title: "Quitar todos los tags",
            image: UIImage(systemName: "tag.slash"),
            attributes: .destructive
        ) { _ in
            self.quitAllTags(document)
        }

        let eliminar = UIAction(
            title: "Eliminar",
            image: UIImage(systemName: "trash"),
            attributes: .destructive
        ) { _ in
            self.deleteDocumentFromFiles(document, indexPath: indexPath)
        }

        return UIMenu(
            title: "",
            children: [tags, renombrar, compartir, quitarTags, eliminar]
        )
    }

    // MARK: - Acciones para el Modal Menu
    func asignarTagsADocumento(_ document: Document) {
        let request: NSFetchRequest<Tag> = Tag.fetchRequest()
        let tags = (try? context.fetch(request)) ?? []

        let alert = UIAlertController(
            title: "Asignar tags",
            message: "Selecciona uno o mas",
            preferredStyle: .actionSheet
        )

        let tagsActuales = document.tags as? Set<Tag> ?? []

        for tag in tags {
            let seleccionado = tagsActuales.contains(tag)
            let titulo = seleccionado ? "✓ \(tag.name ?? "")" : (tag.name ?? "")

            alert.addAction(
                UIAlertAction(title: titulo, style: .default) { _ in
                    var nuevos = tagsActuales
                    if nuevos.contains(tag) {
                        nuevos.remove(tag)
                    } else {
                        nuevos.insert(tag)
                    }
                    document.tags = nuevos as NSSet
                    self.asignarTagsADocumento(document)
                }
            )
        }

        alert.addAction(
            UIAlertAction(title: "Guardar", style: .default) { _ in
                do {
                    try self.context.save()
                    NotificationCenter.default.post(
                        name: .documentoActualizado,
                        object: nil
                    )

                    self.alertaTags("Tags actualizados")
                } catch {
                    print("Error asignando tags: \(error)")
                }
            }
        )

        alert.addAction(UIAlertAction(title: "Cancelar", style: .cancel))
        present(alert, animated: true)
    }

    func renameDocument(_ document: Document) {
        let alerta = UIAlertController(
            title: "Renombrar documento",
            message: nil,
            preferredStyle: .alert
        )

        alerta.addTextField { $0.text = document.title }

        alerta.addAction(UIAlertAction(title: "Cancelar", style: .cancel))

        alerta.addAction(
            UIAlertAction(title: "Guardar", style: .default) { _ in
                guard let nuevoTitulo = alerta.textFields?.first?.text else {
                    return
                }

                document.title = nuevoTitulo

                do {
                    try self.context.save()
                    self.fetchDocumentos()
                } catch {
                    print("Error al renombrar: \(error)")
                }
            }
        )

        present(alerta, animated: true)
    }

    func shareDocument(_ document: Document) {
        guard let path = document.filePath else { return }
        let url = URL(fileURLWithPath: path)

        let activity = UIActivityViewController(
            activityItems: [url],
            applicationActivities: nil
        )
        present(activity, animated: true)
    }

    func quitAllTags(_ document: Document) {
        document.tags = nil

        do {
            try context.save()
            NotificationCenter.default.post(
                name: .documentoActualizado,
                object: nil
            )
            
            alertaTags("Tags eliminados")
        } catch {
            print(
                "Error al quitar tags: \(error)"
            )
        }
    }

    func deleteDocumentFromFiles(_ document: Document, indexPath: IndexPath) {

        if let path = document.filePath {
            try? FileManager.default.removeItem(atPath: path)
        }

        context.delete(document)

        do {
            try context.save()

            if isSearching {
                documentosFiltrados.remove(at: indexPath.row)
            } else {
                documentos.remove(at: indexPath.row)
            }

            cvDocumentos.deleteItems(at: [indexPath])
            actualizarEstadoBusqueda()

        } catch {
            print("Error al eliminar documento: \(error)")
        }
    }

    private func alertaTags(_ mensaje: String) {
        let alerta = UIAlertController(
            title: nil,
            message: mensaje,
            preferredStyle: .alert
        )
        present(alerta, animated: true)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
            alerta.dismiss(animated: true)
        }
    }
}
