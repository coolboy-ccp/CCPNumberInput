//
//  NumberInput.swift
//  CCPNumberInput
//
//  Created by 123 on 2020/6/9.
//  Copyright © 2020 ccp. All rights reserved.
//

import UIKit
import SnapKit


class NumberInput: UIView {
    @IBInspectable var elementCount: Int = 4
    @IBInspectable var fontSize: CGFloat = 30
    @IBInspectable var textColor: UIColor?
    @IBInspectable var boardColor: UIColor = .lightGray
    @IBInspectable var boardColorHighlight: UIColor = .orange
    @IBInspectable var cursorColor: UIColor = .lightGray
    @IBInspectable var space: CGFloat = 10
    
    /// the regex expression of paste, default is "\\d{elementCount}"
    @IBInspectable var validPaste: String?
    
    var completion: ((String) -> ())?
    var beganEditing: (() -> ())?
    var endEditing: (() -> ())?
    
    private lazy var text: String = ""
    private lazy var font = UIFont.systemFont(ofSize: fontSize)
    
    lazy private(set) var tf: NumberInputTextField = {
        let tf = NumberInputTextField()
        tf.keyboardType = .numberPad
        tf.isHidden = true
        addSubview(tf)
        tf.addTarget(self, action: #selector(valueChanged(_:)), for: .editingChanged)
        tf.deleteCallback = { [unowned self] in
            self.delete()
        }
        tf.paste = { [unowned self] in
            self.paste()
        }
        return tf
    }()
    
    lazy private var elements: [NumberInputElement] = {
        return (0 ..< elementCount).map { _ in
            let e = NumberInputElement(font, textColor, boardColor, boardColorHighlight, cursorColor, (self, #selector(begin)))
            return e
        }
    }()
    
    lazy private var stackView: UIStackView = {
        let stack = UIStackView(arrangedSubviews: elements)
        stack.distribution = .fillEqually
        stack.spacing = space
        return stack
    }()
    
    private func delete() {
        let count = text.count
        if count == 0 { return }
        elements[count].isFocus = false
        elements[count - 1].set("")
        elements[count - 1].isFocus = true
        text = String(text.dropLast())
    }
    
    @objc private func keyboardWillAppear() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.beganEditing?()
        }
    }
    
    @objc private func keyboardWillDisappear() {
        endEditing?()
        focusedElement?.isFocus = false
    }
    
    @objc private func valueChanged(_ tf: UITextField) {
        guard let str = tf.text else { return }
        if str.count != 1 { return }
        let count = text.count
        if count == elementCount { return }
        elements[count].isFocus = false
        elements[count].set(str)
        text.append(str)
        tf.text = ""
        if count + 1 == elementCount {
            tf.resignFirstResponder()
            completion?(text)
            return
        }
        elements[count + 1].isFocus = true
    }
    
    private func setup () {
        backgroundColor = .clear
        addSubview(tf)
        addSubview(stackView)
        stackView.snp.makeConstraints { $0.edges.equalToSuperview() }
        begin(elements.first!)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillAppear), name: UITextField.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillDisappear), name: UITextField.keyboardWillHideNotification, object: nil)
    }
            
    override func awakeFromNib() {
        super.awakeFromNib()
        setup()
        addLongPress()
    }
    
    private func addLongPress() {
        let lp = UILongPressGestureRecognizer.init(target: self, action: #selector(lpAction))
        addGestureRecognizer(lp)
    }
    
    @objc private func lpAction(_ lp: UIGestureRecognizer) {
        if lp.state == .began {
            tf.showMenu()
        }
    }
    
    private func paste() {
        guard let pasteStr = UIPasteboard.general.string else {
            return
        }
        let regex = validPaste ?? "\\d{\(elementCount)}"
        if !pasteStr.isMatch(regex) {
            return
        }
        for (idx, char) in pasteStr.enumerated() {
            elements[idx].set(String(char))
        }
        endEditing(true)
        text = pasteStr
        completion?(text)
    }
    
    private var focusedElement: NumberInputElement? {
        for e in elements {
            if e.isFocus == true {
                return e
            }
        }
        return nil
    }
    
    @objc private func begin(_ element: NumberInputElement) {
        if text.count == elementCount {
            _ = elements.map { $0.set("") }
            text = ""
            elements.first?.isFocus = true
            tf.becomeFirstResponder()
            return
        }
        if element.titleLabel.text!.count > 0 {
            return
        }
        if focusedElement == nil {
            element.isFocus = true
            tf.becomeFirstResponder()
        }
        
    }
    
    convenience init(_ frame: CGRect,
                     elementCount: Int = 4,
                     font: UIFont,
                     textColor: UIColor? = nil,
                     boardColor: UIColor,
                     boardColorHighlight: UIColor,
                     cursorColor: UIColor = .lightGray,
                     space: CGFloat = 5) {
        self.init(frame: frame)
        self.elementCount = elementCount
        self.font = font
        self.textColor = textColor
        self.boardColor = boardColor
        self.boardColorHighlight = boardColorHighlight
        self.cursorColor = cursorColor
        self.space = space
        setup()
    }
}

extension String {
    func isMatch(_ regex: String) -> Bool {
       return range(of: regex, options: .regularExpression) != nil
    }
}

class NumberInputTextField: UITextField {
    
    var deleteCallback: (() -> ())?
    var paste: (() -> ())?
    override func deleteBackward() {
        deleteCallback?()
        super.deleteBackward()
    }
    
    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
    
        if action == #selector(pasteAction) {
            return true
        }
        return false
    }
    
    @objc private func pasteAction() {
        paste?()
    }
    
    private lazy var menu: UIMenuController = {
        let menu = UIMenuController()
        let mItem = UIMenuItem(title: "Paste", action: #selector(pasteAction))
        menu.menuItems = [mItem]
        return menu
    }()
    
    func showMenu() {
        becomeFirstResponder()
        if #available(iOS 13.0, *) {
            menu.showMenu(from: self, rect: bounds.offsetBy(dx: 20, dy: 0))
        } else {
            menu.setTargetRect(self.bounds.offsetBy(dx: 20, dy: 0), in: self)
            menu.setMenuVisible(true, animated: true)
        }
    }

}
