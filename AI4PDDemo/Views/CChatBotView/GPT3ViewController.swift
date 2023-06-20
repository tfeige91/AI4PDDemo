//
//  GP3ViewController.swift
//  ChatAI4PD
//
//  Created by Ricardo Rubiano Cruz on 18.06.23.
//

import UIKit

class GPT3ViewController: UIViewController {

    let gptLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 24, weight: .regular)
        label.textColor = .systemBlue
        label.text = "AI4PD: Willkommen!"
        label.textAlignment = .center
        label.layer.cornerRadius = 10
        label.backgroundColor = .systemBackground
        label.clipsToBounds = true
        return label
    }()
    
    lazy var tableView: UITableView = {
        let table = UITableView()
        table.translatesAutoresizingMaskIntoConstraints = false
        table.register(ChatTableViewCell.self, forCellReuseIdentifier: ChatTableViewCell.identifier)
        table.delegate = self
        table.dataSource = self
        table.separatorStyle = .none
        return table
    }()
    
    let promptTextField: UITextField = {
        let field = UITextField()
        field.translatesAutoresizingMaskIntoConstraints = false
        field.leftViewMode = .always
        field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 0))
        field.autocapitalizationType = .none
        field.autocorrectionType = .no
        field.layer.cornerRadius = 10
        field.clipsToBounds = true
        field.backgroundColor = .systemGray6
        field.layer.borderWidth = 1
        field.layer.borderColor = UIColor.secondaryLabel.cgColor
        field.returnKeyType = .done
        field.placeholder = "Hallo! Schön, dass du da bist. Wie könnte ich dir heute helfen?"
        field.contentVerticalAlignment = .top
        return field
    }()
    
    lazy var submitButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Eingeben", for: .normal)
        button.backgroundColor = .systemMint
        button.layer.cornerRadius = 10
        button.addTarget(self, action: #selector(didTapSubmit), for: .touchUpInside)
        return button
    }()
    
    var chat = [String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        view.backgroundColor = .systemBlue
        
        //Task{
        //    let res = try await APIService().sendPromptToGPT(prompt: "What is better, IOS or Android?")
        //    print(res)
        //}
        configureUI()
    }
    
    private func configureUI () {
        view.addSubview(gptLabel)
        view.addSubview(tableView)
        view.addSubview(promptTextField)
        view.addSubview(submitButton)
        
        NSLayoutConstraint.activate([
            gptLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 75),
            gptLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            gptLabel.widthAnchor.constraint(equalToConstant: 300),
            gptLabel.heightAnchor.constraint(equalToConstant: 100),
            
            tableView.topAnchor.constraint(equalTo: gptLabel.bottomAnchor, constant: 20),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 0),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 0),
            tableView.heightAnchor.constraint(equalToConstant: 400),
            
            promptTextField.topAnchor.constraint(equalTo: tableView.bottomAnchor, constant: 20),
            promptTextField.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            promptTextField.widthAnchor.constraint(equalToConstant: 300),
            promptTextField.heightAnchor.constraint(equalToConstant: 100),
            
            submitButton.topAnchor.constraint(equalTo: promptTextField.bottomAnchor, constant: 20),
            submitButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            submitButton.widthAnchor.constraint(equalToConstant: 300),
            submitButton.heightAnchor.constraint(equalToConstant: 60),
        ])
    }
    
    private func fetchGPTChatResponse(prompt: String){
        Task{
            do {
                let gptText = try await APIService().sendPromptToGPT(prompt: prompt)
                await MainActor.run {
                    chat.append(prompt)
                    chat.append(gptText.replacingOccurrences(of: "\n\n", with: ""))
                    tableView.reloadData()
                }
            }   catch {
                    

            }
        }
    }
    
    @objc func didTapSubmit() {
        promptTextField.resignFirstResponder()
        
        if let promptText = promptTextField.text, promptText.count > 3 {
            fetchGPTChatResponse(prompt: promptText)
        } else {
            print("please check textfield")
        }
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

extension GPT3ViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return chat.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ChatTableViewCell.identifier, for: indexPath) as! ChatTableViewCell
        let text = chat[indexPath.row]
        
        
        if indexPath.row % 2 == 0 {
            cell.configure(text: text, isUser: true)
        } else {
            cell.configure(text: text, isUser: false)
        }
        
        return cell
    }
    
    
    
        
}
