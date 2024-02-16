/// Copyright (c) 2021 Razeware LLC
///
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to deal
/// in the Software without restriction, including without limitation the rights
/// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
/// copies of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:
///
/// The above copyright notice and this permission notice shall be included in
/// all copies or substantial portions of the Software.
///
/// Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
/// distribute, sublicense, create a derivative work, and/or sell copies of the
/// Software in any work that is designed, intended, or marketed for pedagogical or
/// instructional purposes related to programming, coding, application development,
/// or information technology.  Permission for such use, copying, modification,
/// merger, publication, distribution, sublicensing, creation of derivative works,
/// or sale is expressly withheld.
///
/// This project and source code may use libraries or frameworks that are
/// released under various Open-Source licenses. Use of those libraries and
/// frameworks are governed by their own individual licenses.
///
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE.

import UIKit
import Firebase
import MessageKit
import InputBarAccessoryView
import FirebaseFirestore

final class ChatViewController: MessagesViewController {
  private let user: User
  private let channel: Channel
  private var messages: [Message] = []
  private var messageListener: ListenerRegistration?
  
  init(user: User, channel: Channel) {
    self.user = user
    self.channel = channel
    super.init(nibName: nil, bundle: nil)
    
    title = channel.name
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    navigationItem.largeTitleDisplayMode = .never
    setUpMessageView()
    removeMessageAvatarsAndAdjustMessageLabelAlignment()
  }
  
  // MARK: - Helpers
  private func insertNewMessage(_ message: Message) {
    if messages.contains(message) {
      assertionFailure("Theo: This should not happen..")
      return
    }
    
    messages.append(message)
    messages.sort()
    
    let isLatestMessage = messages.firstIndex(of: message) == messages.count - 1
    let shouldScrollToBottom = messagesCollectionView.isAtBottom && isLatestMessage
    
    messagesCollectionView.reloadData()
    
    if shouldScrollToBottom {
      messagesCollectionView.scrollToLastItem(animated: true)
    }
  }
  
  private func setUpMessageView() {
    maintainPositionOnKeyboardFrameChanged = true
    messageInputBar.inputTextView.tintColor = .primary
    messageInputBar.sendButton.setTitleColor(.primary, for: .normal)
    
    messageInputBar.delegate = self
    messagesCollectionView.messagesDataSource = self
    messagesCollectionView.messagesLayoutDelegate = self
    messagesCollectionView.messagesDisplayDelegate = self
  }
  
  private func removeMessageAvatarsAndAdjustMessageLabelAlignment() {
    guard let layout = messagesCollectionView.collectionViewLayout as? MessagesCollectionViewFlowLayout else {
      return
    }
    
    layout.textMessageSizeCalculator.outgoingAvatarSize = .zero
    layout.textMessageSizeCalculator.incomingMessageLabelInsets = .zero
    layout.setMessageIncomingAvatarSize(.zero)
    layout.setMessageOutgoingAvatarSize(.zero)
    let incomingLabelAlignment = LabelAlignment(
      textAlignment: .left,
      textInsets: UIEdgeInsets(top: 0, left: 15, bottom: 0, right: 0))
    layout.setMessageIncomingMessageTopLabelAlignment(incomingLabelAlignment)
    let outgoingLabelAlignment = LabelAlignment(
      textAlignment: .right,
      textInsets: UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 15))
    layout.setMessageOutgoingMessageTopLabelAlignment(outgoingLabelAlignment)
  }
}

// MARK: - MessagesDisplayDelegate
extension ChatViewController: MessagesDisplayDelegate {
  func backgroundColor(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UIColor {
    isFromCurrentSender(message: message) ? .primary : .incomingMessage
  }
  
  func configureAvatarView(_ avatarView: AvatarView, for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) {
    avatarView.isHidden = true
  }
  
  func messageStyle(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageStyle {
    let corner: MessageStyle.TailCorner = isFromCurrentSender(message: message) ? .bottomRight : .bottomLeft
    return .bubbleTail(corner, .curved)
  }
}

// MARK: - MessagesLayoutDelegate
extension ChatViewController: MessagesLayoutDelegate {
  func footerViewSize(for section: Int, in messagesCollectionView: MessagesCollectionView) -> CGSize {
    CGSize(width: 0, height: 8)
  }
  
  func messageTopLabelHeight(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGFloat {
    20
  }
}

// MARK: - MessagesDataSource
extension ChatViewController: MessagesDataSource {
  func numberOfSections(in messagesCollectionView: MessagesCollectionView) -> Int {
    messages.count
  }
  
  func currentSender() -> SenderType {
    Sender(senderId: user.uid, displayName: AppSettings.displayName)
  }
  
  func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {
    messages[indexPath.section]
  }
  
  func messageTopLabelAttributedText(for message: MessageType, at indexPath: IndexPath) -> NSAttributedString? {
    let name = message.sender.displayName
    return NSAttributedString(string: name, attributes: [
      .font: UIFont.preferredFont(forTextStyle: .caption1),
      .foregroundColor: UIColor(white: 0.3, alpha: 1)
    ])
  }
}

// MARK: - InputBarAccessoryViewDelegate
extension ChatViewController: InputBarAccessoryViewDelegate {}

// MARK: - UIImagePickerControllerDelegate
extension ChatViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {}
