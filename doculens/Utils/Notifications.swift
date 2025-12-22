//
//  Notifications.swift
//  doculens
//
//  Created by sunderll on 18/12/25.
//

import Foundation

extension Notification.Name {
    static let documentoCreado = Notification.Name("documentoCreado")
    static let documentoActualizado = Notification.Name("documentoActualizado")
    
    static let invitadoActualizado = Notification.Name("invitadoActualizado")
    
    static let folderCreado = Notification.Name("folderCreado")
    static let folderActualizado = Notification.Name("folderActualizado")
    
    static let tagCreado = Notification.Name("tagCreado")
    static let tagsActualizados = Notification.Name("tagsActualizados")
}
