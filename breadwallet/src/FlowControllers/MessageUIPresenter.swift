//
//  MessageUIPresenter.swift
//  breadwallet
//
//  Created by Adrian Corscadden on 2016-12-11.
//  Copyright © 2016 breadwallet LLC. All rights reserved.
//

import UIKit
import MessageUI

class MessageUIPresenter: NSObject, Trackable {

    weak var presenter: UIViewController?

    func presentMailCompose(uri: String, image: UIImage) {
        presentMailCompose(string: uri, image: image)
    }

    func presentMailCompose(bitcoinURL: String, image: UIImage) {
        presentMailCompose(string: bitcoinURL, image: image)
    }

    func presentEmailLogs() {
        guard MFMailComposeViewController.canSendMail() else { showEmailUnavailableAlert(); return }
        guard let logData = try? Data(contentsOf: C.logFilePath) else { showErrorMessage(S.ErrorMessages.noLogsFound); return }
        originalTitleTextAttributes = UINavigationBar.appearance().titleTextAttributes
        UINavigationBar.appearance().titleTextAttributes = nil
        let emailView = MFMailComposeViewController()
        emailView.setToRecipients([C.iosEmail])
        emailView.setSubject("BTJ Logs")
        emailView.setMessageBody("BTJ Logs", isHTML: false)
        emailView.addAttachmentData(logData, mimeType: "text/plain", fileName: "btj_logs.txt")
        emailView.mailComposeDelegate = self
        present(emailView)
    }

    private func presentMailCompose(string: String, image: UIImage) {
        guard MFMailComposeViewController.canSendMail() else { showEmailUnavailableAlert(); return }
        originalTitleTextAttributes = UINavigationBar.appearance().titleTextAttributes
        UINavigationBar.appearance().titleTextAttributes = nil
        let emailView = MFMailComposeViewController()
        emailView.setMessageBody(string, isHTML: false)
        if let data = UIImagePNGRepresentation(image) {
            emailView.addAttachmentData(data, mimeType: "image/png", fileName: "bitcoinqr.png")
        }
        emailView.mailComposeDelegate = self
        present(emailView)
    }

    func presentFeedbackCompose() {
        guard MFMailComposeViewController.canSendMail() else { showEmailUnavailableAlert(); return }
        originalTitleTextAttributes = UINavigationBar.appearance().titleTextAttributes
        UINavigationBar.appearance().titleTextAttributes = nil
        let emailView = MFMailComposeViewController()
        emailView.setToRecipients([C.feedbackEmail])
        emailView.mailComposeDelegate = self
        present(emailView)
    }

    func presentMailCompose(emailAddress: String) {
        guard MFMailComposeViewController.canSendMail() else { showEmailUnavailableAlert(); return }
        originalTitleTextAttributes = UINavigationBar.appearance().titleTextAttributes
        UINavigationBar.appearance().titleTextAttributes = nil
        let emailView = MFMailComposeViewController()
        emailView.setToRecipients([emailAddress.replacingOccurrences(of: "%40", with: "@")])
        emailView.mailComposeDelegate = self
        saveEvent("receive.presentMailCompose")
        present(emailView)
    }

    func presentMessageCompose(uri: String, image: UIImage) {
        presentMessage(string: uri, image: image)
    }

    func presentMessageCompose(bitcoinURL: String, image: UIImage) {
        presentMessage(string: bitcoinURL, image: image)
    }

    private func presentMessage(string: String, image: UIImage) {
        guard MFMessageComposeViewController.canSendText() else { showMessageUnavailableAlert(); return }
        originalTitleTextAttributes = UINavigationBar.appearance().titleTextAttributes
        UINavigationBar.appearance().titleTextAttributes = nil
        let textView = MFMessageComposeViewController()
        textView.body = string
        if let data = UIImagePNGRepresentation(image) {
            textView.addAttachmentData(data, typeIdentifier: "public.image", filename: "bitcoinqr.png")
        }
        textView.messageComposeDelegate = self
        saveEvent("receive.presentMessage")
        present(textView)
    }

    fileprivate var originalTitleTextAttributes: [NSAttributedStringKey: Any]?

    private func present(_ viewController: UIViewController) {
        presenter?.view.isFrameChangeBlocked = true
        presenter?.present(viewController, animated: true, completion: {})
    }

    fileprivate func dismiss(_ viewController: UIViewController) {
        UINavigationBar.appearance().titleTextAttributes = originalTitleTextAttributes
        viewController.dismiss(animated: true, completion: {
            self.presenter?.view.isFrameChangeBlocked = false
        })
    }

    private func showEmailUnavailableAlert() {
        saveEvent("receive.emailUnavailable")
        let alert = UIAlertController(title: S.ErrorMessages.emailUnavailableTitle, message: S.ErrorMessages.emailUnavailableMessage, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: S.Button.ok, style: .default, handler: nil))
        presenter?.present(alert, animated: true, completion: nil)
    }

    private func showMessageUnavailableAlert() {
        saveEvent("receive.messagingUnavailable")
        let alert = UIAlertController(title: S.ErrorMessages.messagingUnavailableTitle, message: S.ErrorMessages.messagingUnavailableMessage, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: S.Button.ok, style: .default, handler: nil))
        presenter?.present(alert, animated: true, completion: nil)
    }

    private func showErrorMessage(_ message: String) {
        let alert = UIAlertController(title: S.Alert.error, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: S.Button.ok, style: .default, handler: nil))
        presenter?.present(alert, animated: true, completion: nil)
    }
}

extension MessageUIPresenter: MFMailComposeViewControllerDelegate {
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        dismiss(controller)
    }
}

extension MessageUIPresenter: MFMessageComposeViewControllerDelegate {
    func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
        dismiss(controller)
    }
}
