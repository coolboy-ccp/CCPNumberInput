//
//  NumberInputElement.swift
//  CCPNumberInput
//
//  Created by 123 on 2020/6/10.
//  Copyright © 2020 ccp. All rights reserved.
//

import UIKit

class NumberInputElement: UIControl {
    
    typealias TargetAction = (target: Any, action: Selector)
    
    private var font: UIFont?
    private var textColor: UIColor?
    private var boardColor: UIColor = .lightGray
    private var boardColorHighlight: UIColor = .orange
    private var cursorColor: UIColor = .lightGray
    
    lazy private(set) var titleLabel: UILabel = {
        let label = UILabel()
        label.font = font ?? UIFont.systemFont(ofSize: 25)
        label.textColor = textColor
        label.textAlignment = .center
        label.text = ""
        return label
    }()
    
    lazy private var boardView: UIView = {
        let board = UIView()
        board.backgroundColor = boardColor
        return board
    }()
    
    lazy private var cursorLayer: CALayer = {
        let cursor = CALayer()
        cursor.backgroundColor = cursorColor.cgColor
        cursor.isHidden = true
        return cursor
    }()
    
    private var animation: CABasicAnimation = {
           let ani = CABasicAnimation(keyPath: "opacity")
           ani.fromValue = 1.0
           ani.toValue = 0.0
           ani.duration = 0.8
           ani.repeatCount = Float.infinity
           ani.autoreverses = true
           ani.timingFunction = CAMediaTimingFunction(name: .easeIn)
           return ani
       }()
    
    var isFocus: Bool = false {
        didSet {
            if isFocus {
                cursorLayer.isHidden = false
                cursorLayer.add(animation, forKey: "NumberInputElement.Cursor.Animation")
                boardView.backgroundColor = boardColorHighlight
            }
            else {
                cursorLayer.isHidden = true
                cursorLayer.removeAnimation(forKey: "NumberInputElement.Cursor.Animation")
                boardView.backgroundColor = boardColor
            }
        }
    }
    
    
        
    convenience init( _ font: UIFont?,
                      _ textColor: UIColor?,
                      _ boardColor: UIColor,
                      _ boardColorHighlight: UIColor,
                      _ cursorColor: UIColor,
                      _ ta: TargetAction) {
        self.init(frame: .zero)
        self.font = font
        self.textColor = textColor
        self.boardColor = boardColor
        self.boardColorHighlight = boardColorHighlight
        self.cursorColor = cursorColor
        backgroundColor = .clear
        addContents()
        layout()
        addTarget(ta.target, action: ta.action, for: .touchUpInside)
    }
    
        
    func set(_ text: String) {
        titleLabel.text = text
    }
    
    private func addContents () {
        addSubview(titleLabel)
        addSubview(boardView)
        layer.addSublayer(cursorLayer)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        cursorLayer.frame = CGRect(x: (self.bounds.width - 2) / 2, y: (self.bounds.height - font!.lineHeight + 10) / 2, width: 2, height: font!.lineHeight - 10)
    }
    
    private func layout() {
        titleLabel.snp.makeConstraints {
            $0.leading.top.trailing.equalToSuperview()
            $0.bottom.equalTo(-1)
        }
        
        boardView.snp.makeConstraints {
            $0.leading.trailing.bottom.equalToSuperview()
            $0.height.equalTo(1)
        }
    }    
}

