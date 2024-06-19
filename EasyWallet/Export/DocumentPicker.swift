//
//  DocumentPicker.swift
//  EasyWallet
//
//  Created by Collin Ilgner on 18.03.24.
//

import SwiftUI
import UIKit

struct DocumentPicker: UIViewControllerRepresentable {
    var documentURL: URL
    var onPick: () -> Void

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forExporting: [documentURL])
        picker.allowsMultipleSelection = false
        picker.directoryURL = documentURL.deletingLastPathComponent()
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIDocumentPickerDelegate, UINavigationControllerDelegate {
        var parent: DocumentPicker

        init(_ documentPicker: DocumentPicker) {
            self.parent = documentPicker
        }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            parent.onPick()
        }
    }
}
