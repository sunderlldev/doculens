//
//  HomeViewController.swift
//  doculens
//
//  Created by sunderll on 2/12/25.
//

import UIKit

class HomeViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var tablaRecientes: UITableView!
    
    struct TestDocument {
        let titulo: String
        let fecha: String
        let peso: String
        let thumbnail: UIImage?
    }
    
    var recientes: [TestDocument] = [
        TestDocument(titulo: "T01 D01 - Doc 55",
                     fecha: "28.12.2025",
                     peso: "970 KB",
                     thumbnail: UIImage(systemName: "document.fill")),
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tablaRecientes.delegate = self
        tablaRecientes.dataSource = self
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        recientes.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let celda = tableView.dequeueReusableCell(withIdentifier: "RecentCell", for: indexPath) as! RecentCell
        
        let doc = recientes[indexPath.row]
        
        celda.lblTitulo.text = doc.titulo
        celda.lblFecha.text = doc.fecha
        celda.lblPeso.text = doc.peso
        celda.thumbnail.image = doc.thumbnail ?? UIImage(systemName: "document.fill")
        
        celda.thumbnail.contentMode = .scaleAspectFit
        
        return celda
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
//      performSegue(withIdentifier: "verDocumento", sender: self)
    }
}
