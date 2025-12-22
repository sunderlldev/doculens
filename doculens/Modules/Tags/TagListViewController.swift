//
//  TagListViewController.swift
//  doculens
//
//  Created by sunderll on 22/12/25.
//

import CoreData
import UIKit

class TagListViewController: UIViewController, UITableViewDataSource,
    UITableViewDelegate
{

    @IBOutlet weak var tvTags: UITableView!

    @IBOutlet weak var emptyView: UIView!

    @IBOutlet weak var ivIconoEmpty: UIImageView!

    @IBOutlet weak var lblMensajeEmpty: UILabel!

    var tags: [Tag] = []

    lazy var context: NSManagedObjectContext = {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        return appDelegate.persistentContainer.viewContext
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        tvTags.delegate = self
        tvTags.dataSource = self

        configurarUI()
        fetchTags()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(fetchTags),
            name: .tagCreado,
            object: nil
        )

        let longPress = UILongPressGestureRecognizer(
            target: self,
            action: #selector(handleLongPress(_:))
        )

        tvTags.addGestureRecognizer(longPress)
    }

    // MARK: - Configuracion UI
    private func configurarUI() {
        title = "Tags"

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .add,
            target: self,
            action: #selector(crearTag)
        )
    }

    @objc func fetchTags() {
        let request: NSFetchRequest<Tag> = Tag.fetchRequest()
        request.sortDescriptors = [
            NSSortDescriptor(key: "name", ascending: true)
        ]

        do {
            tags = try context.fetch(request)
            tvTags.reloadData()
            actualizarEmptyState()
        } catch {
            print("Erro al cargar los tags: \(error)")
        }
    }

    // MARK: Evitar duplicados
    func existeTagConNombre(_ nombre: String) -> Bool {
        let request: NSFetchRequest<Tag> = Tag.fetchRequest()
        request.predicate = NSPredicate(
            format: "name == [c] %@",
            nombre
        )
        request.fetchLimit = 1

        let count = try? context.count(for: request)
        return (count ?? 0) > 0
    }

    func actualizarEmptyState() {
        emptyView.isHidden = !tags.isEmpty

        if tags.isEmpty {
            lblMensajeEmpty.text = "No tienes tags creados"
            ivIconoEmpty.image = UIImage(systemName: "tag.slash")
        }
    }

    // MARK: - Crear Tag
    @objc func crearTag() {
        let alert = UIAlertController(
            title: "Nuevo tag",
            message: nil,
            preferredStyle: .alert
        )

        alert.addTextField { tf in
            tf.placeholder = "Nombre del tag"
        }

        alert.addAction(UIAlertAction(title: "Cancelar", style: .cancel))

        alert.addAction(
            UIAlertAction(title: "Crear", style: .default) { _ in
                guard
                    let nombre = alert.textFields?.first?.text,
                    !nombre.trimmingCharacters(in: .whitespaces).isEmpty
                else { return }

                if self.existeTagConNombre(nombre) {
                    self.mostrarAlerta(
                        titulo: "Tag duplicado",
                        mensaje: "Ya existe un tag con ese nombre"
                    )
                    
                    return
                }

                let tag = Tag(context: self.context)
                tag.id = UUID()
                tag.name = nombre

                do {
                    try self.context.save()
                    NotificationCenter.default.post(
                        name: .tagCreado,
                        object: nil
                    )
                } catch {
                    print("Error creando tag: \(error)")
                }
            }
        )

        present(alert, animated: true)
    }

    // MARK: - Long Press
    @objc func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began else { return }

        let point = gesture.location(in: tvTags)
        guard let indexPath = tvTags.indexPathForRow(at: point) else { return }

        let tag = tags[indexPath.row]
        mostrarMenu(tag: tag, indexPath: indexPath)
    }

    // MARK: - Modal Menu Tag
    func mostrarMenu(tag: Tag, indexPath: IndexPath) {
        let alert = UIAlertController(
            title: tag.name,
            message: nil,
            preferredStyle: .actionSheet
        )

        alert.addAction(
            UIAlertAction(title: "Renombrar", style: .default) { _ in
                self.renombrarTag(tag)
            }
        )

        alert.addAction(
            UIAlertAction(title: "Eliminar", style: .destructive) { _ in
                self.eliminarTag(tag, indexPath: indexPath)
            }
        )

        alert.addAction(UIAlertAction(title: "Cancelar", style: .cancel))
        present(alert, animated: true)
    }

    // MARK: - Renombrar y Eliminar Tag
    func renombrarTag(_ tag: Tag) {
        let alert = UIAlertController(
            title: "Renombrar tag",
            message: nil,
            preferredStyle: .alert
        )

        alert.addTextField { tf in
            tf.text = tag.name
        }

        alert.addAction(UIAlertAction(title: "Cancelar", style: .cancel))

        alert.addAction(
            UIAlertAction(title: "Guardar", style: .default) { _ in
                guard let nuevoNombre = alert.textFields?.first?.text else {
                    return
                }

                if self.existeTagConNombre(nuevoNombre) {
                    self.mostrarAlerta(
                        titulo: "Tag duplicado",
                        mensaje: "Ya existe un tag con ese nombre"
                    )
                    
                    return
                }
                
                tag.name = nuevoNombre

                do {
                    try self.context.save()
                    self.fetchTags()
                    NotificationCenter.default.post(
                        name: .tagsActualizados,
                        object: nil
                    )
                } catch {
                    print("Error renombrando tag: \(error)")
                }
            }
        )

        present(alert, animated: true)
    }

    func eliminarTag(_ tag: Tag, indexPath: IndexPath) {
        context.delete(tag)

        do {
            try context.save()
            tags.remove(at: indexPath.row)
            tvTags.deleteRows(at: [indexPath], with: .automatic)
            actualizarEmptyState()
            NotificationCenter.default.post(
                name: .tagsActualizados,
                object: nil
            )
        } catch {
            print("Error eliminando tag: \(error)")
        }
    }

    // MARK: - TableView DataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int)
        -> Int
    {
        tags.count
    }

    func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath
    ) -> UITableViewCell {
        let celda = tableView.dequeueReusableCell(
            withIdentifier: "TagCell",
            for: indexPath
        )

        let tag = tags[indexPath.row]
        celda.textLabel?.text = tag.name
        celda.imageView?.image = UIImage(systemName: "tag")

        return celda
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - TableView Delegate
    func tableView(
        _ tableView: UITableView,
        didSelectRowAt indexPath: IndexPath
    ) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    // MARK: - Alerta
    func mostrarAlerta(titulo: String, mensaje: String) {
        let alerta = UIAlertController(
            title: titulo,
            message: mensaje,
            preferredStyle: .alert
        )

        alerta.addAction(
            UIAlertAction(title: "Aceptar", style: .default)
        )

        present(alerta, animated: true)
    }
}
