//
//  FilePicker.swift
//  HarmonyKit
//
//  Created by Claudio Cambra on 25/1/24.
//

#if !os(macOS)

import SwiftUI
import UniformTypeIdentifiers

public struct FilePickerRepresentable: UIViewControllerRepresentable {
    public typealias URLsPickedHandler = (_ urls: [URL]) -> Void

    public let types: [UTType]
    public let allowMultiple: Bool
    public let urlsPickedHandler: URLsPickedHandler

    public init(
        types: [UTType],
        allowMultiple: Bool,
        onPicked pickedHandler: @escaping URLsPickedHandler
    ) {
        self.types = types
        self.allowMultiple = allowMultiple
        self.urlsPickedHandler = pickedHandler
    }

    public func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: types)
        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = allowMultiple
        return picker
    }

    public func updateUIViewController(
        _ controller: UIDocumentPickerViewController,
        context: Context
    ) {
        // Nothing to do here
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator(urlsPickedHandler: urlsPickedHandler)
    }

    public class Coordinator: NSObject, UIDocumentPickerDelegate {
        private let urlsPickedHandler: (_ urls: [URL]) -> Void

        public init(urlsPickedHandler: @escaping (_ urls: [URL]) -> Void) {
            self.urlsPickedHandler = urlsPickedHandler
            super.init()
        }

        public func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            urlsPickedHandler(urls)
        }
    }
}

#endif
