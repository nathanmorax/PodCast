//
//  LibraryMenuItem.swift
//  Podcast
//
//  Created by Jonathan Mora on 09/06/26.
//

import Foundation

struct LibraryMenuItem: Identifiable {
    let id = UUID()
    let title: String
    let systemImage: String
    let destination: LibraryDestination
}

enum LibraryDestination {
    case guardados
    case descargas
//    case programas
//    case canales
//    case categorias
    case podcast(id: Int)
}
