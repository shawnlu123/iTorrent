//
//  FileCell.swift
//  iTorrent
//
//  Created by  XITRIX on 15.05.2018.
//  Copyright © 2018  XITRIX. All rights reserved.
//

import Foundation
import UIKit

class FileCellOld: ThemedUITableViewCell {
    @IBOutlet var title: UILabel!
    @IBOutlet var size: UILabel!
    @IBOutlet var switcher: UISwitch!
    @IBOutlet var shareButton: UIButton!
    @IBOutlet var progress: SegmentedProgressView!

    weak var actionDelegate: FileCellActionDelegate?
    var name: String!
    var adding = false
    weak var file: FileModel!

    var hideUI: Bool = false

    @IBOutlet var titleConstraint: NSLayoutConstraint!

    override func themeUpdate() {
        super.themeUpdate()
        let theme = Themes.current
        title?.textColor = theme.mainText
        size?.textColor = theme.secondaryText

        let bgColorView = UIView()
        bgColorView.backgroundColor = theme.backgroundSecondary
        selectedBackgroundView = bgColorView
    }

    func update() {
        title.text = file?.name
        let progressValue = Float(file.downloadedBytes) / Float(file.size)
        let percent = progressValue * 100
        size.text = adding ? Utils.getSizeText(size: file.size) : Utils.getSizeText(size: file.size) + " / " + Utils.getSizeText(size: file.downloadedBytes) + " (" + String(format: "%.2f", percent) + "%)"
        progress?.setProgress(progressValue == 1 ? [1] : file.pieces.map {
            CGFloat($0)
        })

        if hideUI {
            shareButton?.isHidden = true
            switcher.isHidden = true
            titleConstraint?.constant = 13
        } else {
            titleConstraint?.constant = 70
            if percent >= 100, !adding {
                shareButton?.isHidden = false
                switcher.isHidden = true
            } else {
                shareButton?.isHidden = true
                switcher.isHidden = false
            }
        }

        switch file.priority {
        case .dontDownload:
            switcher.setOn(false, animated: true)
            switcher.onTintColor = nil
        case .lowPriority:
            switcher.setOn(true, animated: true)
            switcher.onTintColor = #colorLiteral(red: 1, green: 0.2980392157, blue: 0.168627451, alpha: 1)
        case .mediumPriority:
            switcher.setOn(true, animated: true)
            switcher.onTintColor = UIColor.orange
        case .normalPriority:
            switcher.setOn(true, animated: true)
            switcher.onTintColor = nil
        }
    }

    func canShare() -> Bool {
        let percent = Float(file.downloadedBytes) / Float(file.size) * 100
        return percent >= 100 && !adding
    }

    @IBAction func switcherAction(_ sender: UISwitch) {
        if actionDelegate != nil {
            actionDelegate?.fileCellAction(sender, file: file)
        }
    }

    @IBAction func shareAction(_ sender: UIButton) {
        let controller = ThemedUIAlertController(title: nil, message: file.name, preferredStyle: .actionSheet)
        let share = UIAlertAction(title: NSLocalizedString("Share", comment: ""), style: .default) { _ in
            let path = NSURL(fileURLWithPath: Core.rootFolder + "/" + self.file.path.path + "/" + self.file.name, isDirectory: false)
            let shareController = ThemedUIActivityViewController(activityItems: [path], applicationActivities: nil)
            if shareController.popoverPresentationController != nil {
                shareController.popoverPresentationController?.sourceView = sender
                shareController.popoverPresentationController?.sourceRect = sender.bounds
                shareController.popoverPresentationController?.permittedArrowDirections = .any
            }
            UIApplication.shared.keyWindow?.rootViewController?.present(shareController, animated: true)
        }
        //		let delete = UIAlertAction(title: "Delete", style: .destructive) { _ in
        //			let deleteController = ThemedUIAlertController(title: "Are you sure to delete?", message: self.file.fileName, preferredStyle: .actionSheet)
        //			let deleteAction = UIAlertAction(title: "Delete", style: .destructive) { _ in
//
        //			}
        //			let cancel = UIAlertAction(title: "Cancel", style: .cancel)
//
        //			deleteController.addAction(deleteAction)
        //			deleteController.addAction(cancel)
//
        //			if (deleteController.popoverPresentationController != nil) {
        //				deleteController.popoverPresentationController?.sourceView = sender
        //				deleteController.popoverPresentationController?.sourceRect = sender.bounds
        //				deleteController.popoverPresentationController?.permittedArrowDirections = .any
        //			}
//
        //			UIApplication.shared.keyWindow?.rootViewController?.present(deleteController, animated: true)
        //		}
        let cancel = UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel)
        controller.addAction(share)
        // controller.addAction(delete)
        controller.addAction(cancel)

        if controller.popoverPresentationController != nil {
            controller.popoverPresentationController?.sourceView = sender
            controller.popoverPresentationController?.sourceRect = sender.bounds
            controller.popoverPresentationController?.permittedArrowDirections = .right
        }

        UIApplication.shared.keyWindow?.rootViewController?.present(controller, animated: true)
    }
}
