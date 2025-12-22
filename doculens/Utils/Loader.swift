//
//  Loader.swift
//  doculens
//
//  Created by sunderll on 22/12/25.
//

import UIKit

final class Loader {

    private static var overlayView: UIView?

    static func show(in view: UIView, message: String? = nil) {
        
        if overlayView != nil { return }

        let overlay = UIView(frame: view.bounds)
        overlay.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        overlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        let indicator = UIActivityIndicatorView(style: .large)
        indicator.color = .white
        indicator.startAnimating()
        indicator.translatesAutoresizingMaskIntoConstraints = false

        overlay.addSubview(indicator)

        var label: UILabel?
        if let message {
            let lbl = UILabel()
            lbl.text = message
            lbl.textColor = .white
            lbl.font = .systemFont(ofSize: 15, weight: .medium)
            lbl.translatesAutoresizingMaskIntoConstraints = false
            overlay.addSubview(lbl)
            label = lbl
        }

        NSLayoutConstraint.activate([
            indicator.centerXAnchor.constraint(equalTo: overlay.centerXAnchor),
            indicator.centerYAnchor.constraint(equalTo: overlay.centerYAnchor)
        ])

        if let label {
            NSLayoutConstraint.activate([
                label.topAnchor.constraint(equalTo: indicator.bottomAnchor, constant: 12),
                label.centerXAnchor.constraint(equalTo: overlay.centerXAnchor)
            ])
        }

        view.addSubview(overlay)
        overlayView = overlay
    }

    static func hide() {
        overlayView?.removeFromSuperview()
        overlayView = nil
    }
}
