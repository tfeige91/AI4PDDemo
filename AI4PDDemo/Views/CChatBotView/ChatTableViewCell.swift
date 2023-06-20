//
//  ChatTableViewCell.swift
//  ChatAI4PD
//
//  Created by Ricardo Rubiano Cruz on 19.06.23.
//

import UIKit

class ChatTableViewCell: UITableViewCell {

    static let identifier = "ChatTableViewCell"
    
    let chatLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 0
        
        return label
    }()
    
    let bubbleView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.cornerRadius = 10
        return view
    }()
    
    var lead: NSLayoutConstraint!
    var trail: NSLayoutConstraint!
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        configureUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func configureUI(){
        addSubview(bubbleView)
        addSubview(chatLabel)
        
        
        NSLayoutConstraint.activate([
            chatLabel.topAnchor.constraint(equalTo: topAnchor,constant: 12),
            chatLabel.bottomAnchor.constraint(equalTo: bottomAnchor,constant: -12),
            chatLabel.widthAnchor.constraint(lessThanOrEqualToConstant: 275),
        
            bubbleView.topAnchor.constraint(equalTo: chatLabel.topAnchor,constant: -8),
            bubbleView.leadingAnchor.constraint(equalTo: chatLabel.leadingAnchor, constant: -8),
            bubbleView.trailingAnchor.constraint(equalTo: chatLabel.trailingAnchor, constant:8),
            bubbleView.bottomAnchor.constraint(equalTo: chatLabel.bottomAnchor, constant:8)
        ])
        
        lead = chatLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16)
        trail = chatLabel.trailingAnchor.constraint(equalTo: trailingAnchor,constant:  -16)
        
    }
    
    func configure(text: String, isUser:Bool){
        chatLabel.text = text
        
        if isUser{
            bubbleView.backgroundColor = .systemBlue
            lead.isActive = false
            trail.isActive = true
        } else{
            bubbleView.backgroundColor = .systemGray
            lead.isActive = true
            trail.isActive = false
        }
    }
    
}
