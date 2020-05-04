//
//  TorrentListController+AddTorrentFunc.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 03.04.2020.
//  Copyright © 2020  XITRIX. All rights reserved.
//

import UIKit

extension TorrentListController {
    func addTorrent(_ sender: UIBarButtonItem) {
        let addController = ThemedUIAlertController(title: nil, message: NSLocalizedString("Add from...", comment: ""), preferredStyle: .actionSheet)

        let addURL = UIAlertAction(title: "URL", style: .default) { _ in
            let addURLController = ThemedUIAlertController(title: NSLocalizedString("Add from URL", comment: ""), message: NSLocalizedString("Please enter the existing torrent's URL below", comment: ""), preferredStyle: .alert)
            addURLController.addTextField(configurationHandler: { textField in
                textField.placeholder = "https://"

                if #available(iOS 10.0, *),
                    UIPasteboard.general.hasStrings,
                    let text = UIPasteboard.general.string,
                    (text.starts(with: "https://") ||
                    text.starts(with: "http://")) {
                    textField.text = UIPasteboard.general.string
                }
                
                let theme = Themes.current
                textField.keyboardAppearance = theme.keyboardAppearence
            })
            let ok = UIAlertAction(title: "OK", style: .default) { _ in
                let textField = addURLController.textFields![0]

                Utils.checkFolderExist(path: Core.configFolder)

                if let url = URL(string: textField.text!) {
                    Downloader.load(url: url, to: URL(fileURLWithPath: Core.configFolder + "/_temp.torrent"), completion: {
                        let hash = TorrentSdk.getTorrentFileHash(torrentPath: Core.configFolder + "/_temp.torrent")
                        if hash == nil || hash == "-1" {
                            let controller = ThemedUIAlertController(title: Localize.get("Error has been occured"),
                                                                     message: Localize.get("Torrent file is broken or this URL has some sort of DDOS protection, you can try to open this link in Safari"),
                                                                     preferredStyle: .alert)
                            let safari = UIAlertAction(title: NSLocalizedString("Open in Safari", comment: ""), style: .default) { _ in
                                UIApplication.shared.openURL(url)
                            }
                            let close = UIAlertAction(title: NSLocalizedString("Close", comment: ""), style: .cancel)
                            controller.addAction(safari)
                            controller.addAction(close)
                            Utils.topViewController?.present(controller, animated: true)
                            return
                        }
                        if Core.shared.torrents[hash!] != nil {
                            let controller = ThemedUIAlertController(title: Localize.get("This torrent already exists"),
                                                                     message: "\(Localize.get("Torrent with hash:")) \"\(hash!)\" \(Localize.get("already exists in download queue"))",
                                                                     preferredStyle: .alert)
                            let close = UIAlertAction(title: NSLocalizedString("Close", comment: ""), style: .cancel)
                            controller.addAction(close)
                            Utils.topViewController?.present(controller, animated: true)
                            return
                        }
                        let controller = UIStoryboard(name: "Main", bundle: Bundle.main).instantiateViewController(withIdentifier: "AddTorrent")
                        ((controller as? UINavigationController)?.topViewController as? AddTorrentController)?.initialize(filePath: Core.configFolder + "/_temp.torrent")
                        self.present(controller, animated: true)
                    }, errorAction: {
                        let alertController = ThemedUIAlertController(title: Localize.get("Error has been occured"),
                                                                      message: Localize.get("Please, open this link in Safari, and send .torrent file from there"),
                                                                      preferredStyle: .alert)
                        let close = UIAlertAction(title: NSLocalizedString("Close", comment: ""), style: .cancel)
                        alertController.addAction(close)
                        self.present(alertController, animated: true)
                    })
                } else {
                    let alertController = ThemedUIAlertController(title: Localize.get("Error"),
                                                                  message: Localize.get("Wrong link, check it and try again!"),
                                                                  preferredStyle: .alert)
                    let close = UIAlertAction(title: NSLocalizedString("Close", comment: ""), style: .cancel)
                    alertController.addAction(close)
                    self.present(alertController, animated: true)
                }
            }
            let cancel = UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel)

            addURLController.addAction(ok)
            addURLController.addAction(cancel)

            self.present(addURLController, animated: true)
        }
        let addMagnet = UIAlertAction(title: "Magnet", style: .default) { _ in
            let addMagnetController = ThemedUIAlertController(title: Localize.get("Add from magnet"),
                                                              message: Localize.get("Please enter the magnet link below"),
                                                              preferredStyle: .alert)
            addMagnetController.addTextField(configurationHandler: { textField in
                textField.placeholder = "magnet:"

                if #available(iOS 10.0, *),
                    UIPasteboard.general.hasStrings,
                    UIPasteboard.general.string?.starts(with: "magnet:") ?? false {
                    textField.text = UIPasteboard.general.string
                }

                let theme = Themes.current
                textField.keyboardAppearance = theme.keyboardAppearence
            })
            let ok = UIAlertAction(title: "OK", style: .default) { _ in
                let textField = addMagnetController.textFields![0]

                Utils.checkFolderExist(path: Core.configFolder)
                if let hash = TorrentSdk.getMagnetHash(magnetUrl: textField.text!),
                    Core.shared.torrents[hash] != nil {
                    let alert = ThemedUIAlertController(title: Localize.get("This torrent already exists"),
                                                        message: "\(Localize.get("Torrent with hash:")) \"\(hash)\" \(Localize.get("already exists in download queue"))",
                                                        preferredStyle: .alert)
                    let close = UIAlertAction(title: NSLocalizedString("Close", comment: ""), style: .cancel)
                    alert.addAction(close)
                    self.present(alert, animated: true)
                }

                Core.shared.addMagnet(textField.text!)
            }
            let cancel = UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel)

            addMagnetController.addAction(ok)
            addMagnetController.addAction(cancel)

            self.present(addMagnetController, animated: true)
        }
        let cancel = UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel)

        addController.addAction(addMagnet)
        addController.addAction(addURL)

        let webview = UIAlertAction(title: "Web", style: .default) { _ in
            let webviewAlert = ThemedUIAlertController(title: Localize.get("Open in Web View"),
                                                       message: nil,
                                                       preferredStyle: .alert)

            webviewAlert.addTextField(configurationHandler: { textField in
                textField.placeholder = "https://google.com/"
                let theme = Themes.current
                textField.keyboardAppearance = theme.keyboardAppearence
            })

            let ok = UIAlertAction(title: "OK", style: .default) { _ in
                let textField = webviewAlert.textFields![0]
                if !textField.text!.isEmpty {
                    if let url = URL(string: textField.text!),
                        UIApplication.shared.canOpenURL(url) {
                        WebViewController.present(in: self.splitViewController!, with: url)
                    } else {
                        WebViewController.present(in: self.splitViewController!, with: URL(string: "http://google.com/search?q=\(textField.text!.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")")!)
                    }
                } else {
                    WebViewController.present(in: self.splitViewController!, with: URL(string: "http://google.com/")!)
                }
            }

            webviewAlert.addAction(ok)
            webviewAlert.addAction(UIAlertAction(title: Localize.get("Cancel"), style: .cancel))

            self.present(webviewAlert, animated: true)
        }
        // addController.addAction(webview)

        if #available(iOS 11.0, *) {
            let files = UIAlertAction(title: NSLocalizedString("Files", comment: ""), style: .default) { _ in
                self.present(FilesBrowserController(), animated: true)
            }
            addController.addAction(files)
        }

        addController.addAction(cancel)

        if addController.popoverPresentationController != nil {
            addController.popoverPresentationController?.barButtonItem = sender
            addController.popoverPresentationController?.permittedArrowDirections = .down
        }

        present(addController, animated: true)
    }
}
