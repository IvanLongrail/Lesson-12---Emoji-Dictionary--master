//
//  EmojiListViewController.swift
//  Emoji Dictionary
//
//  Created by Denis Bystruev on 11/04/2019.
//  Copyright © 2019 Denis Bystruev. All rights reserved.
//

import UIKit

class EmojiListViewController: UITableViewController {
    
    let cellID = "EmojiCell"
    let fileName = "usersEmojis"
    let configurator = TableViewCellConfigurator()
    var emojis = Emojis()
    var deleteMode = false
    
    override func viewDidLoad() {
        loadData()
        setupUI()
    }
    
    func setupUI() {
        setupBarButtonItem()
    }
    
}

// MARK: - Bar Button Items Edit
extension EmojiListViewController {

    func setupBarButtonItem() {
        navigationItem.title = emojis.title
        let editBarButtonItem = UIBarButtonItem(title: "Edit", style: UIBarButtonItem.Style.plain, target: self, action: #selector(editigIsActive))
        navigationItem.leftBarButtonItems = [editBarButtonItem]
    }

    @objc func editigIsActive() {
        if !isEditing {
            isEditing.toggle()
            navigationItem.leftBarButtonItems?.first?.title = "Done"
            let editingStyleBarButtonItem = UIBarButtonItem(title: "Delete", style: UIBarButtonItem.Style.plain, target: self, action: #selector(setEditingStyle))
            navigationItem.leftBarButtonItems?.append(editingStyleBarButtonItem)
        } else {
            isEditing.toggle()
            navigationItem.leftBarButtonItems?.first?.title = "Edit"
            navigationItem.leftBarButtonItems?.removeLast()
            deleteMode = false
        }

    }

    @objc func setEditingStyle() {
        deleteMode.toggle()
        navigationItem.leftBarButtonItems?.last?.title = deleteMode ? "Copy" : "Delete"
        tableView.reloadData()
    }
}

// MARK: - Table View Data Source
extension EmojiListViewController {
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return emojis.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let emoji = emojis[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: cellID) as! EmojiCell
        
        configurator.configure(cell, with: emoji)
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        let movedEmoji = emojis.remove(at: sourceIndexPath.row)
        emojis.insert(movedEmoji, at: destinationIndexPath.row)
        
        uploadData()
        tableView.reloadData()
    }
    
    override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return deleteMode ? .delete : .insert
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        switch editingStyle {
        case .delete:
            emojis.remove(at: indexPath.row)
            
            uploadData()
            tableView.deleteRows(at: [indexPath], with: .automatic)
        case .insert:
            let copyEmoji = emojis[indexPath.row]
            let endOfTableIndexPath = IndexPath(row: emojis.count, section: 0)
            emojis.append(copyEmoji)
            
            uploadData()
            tableView.insertRows(at: [endOfTableIndexPath], with: .automatic)
        default:
            break
        }
    }
}


// MARK: - Navigation
extension EmojiListViewController {
    @IBAction func unwind(segue: UIStoryboardSegue) {        
        guard segue.identifier == "SaveSegue" else { return }
        guard let controller = segue.source as? EmojiDetailViewController else { return }
        let emoji = controller.emoji
        print(#line, #function, emoji.symbol, emoji.name)
        
        if let indexPathForSelectedRow = tableView.indexPathForSelectedRow {
            emojis[indexPathForSelectedRow.row] = emoji
            
            uploadData()
            tableView.reloadData()
//            tableView.beginUpdates()
//            tableView.endUpdates()
        } else {
            let indexPath = IndexPath(row: emojis.count, section: 0)
            emojis.append(emoji)
            
            uploadData()
            tableView.insertRows(at: [indexPath], with: .automatic)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard segue.identifier == "EditSegue" else { return }
        let emojiDetailViewController = segue.destination as! EmojiDetailViewController
        emojiDetailViewController.emoji = emojis[ tableView.indexPathForSelectedRow!.row ].clone()
        emojiDetailViewController.navigationItem.title = "Editing"
    }
}


// MARK: - Load & Upload Data
extension EmojiListViewController {
    func loadData() {
        if let emojisFromFile = readEmojis(from: fileName) {
            emojis = emojisFromFile
        } else {
            emojis = Emojis.loadSample()
        }
    }
    
    func uploadData() {
        write(emojis, to: fileName)
    }
}


// MARK: - Permanent Storage In Plist File
extension EmojiListViewController {
    
    func write(_ emojis: Emojis,to fileName: String) {
        if let encodedEmojis = emojis.encode {
            let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            
            let archiveEmojisURL = documentDirectory.appendingPathComponent(fileName).appendingPathExtension("plist")
            
            try? encodedEmojis.write(to: archiveEmojisURL, options: .noFileProtection)
        }
    }
    
    func readEmojis(from fileName: String) -> Emojis? {
        let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        
        let archiveEmojisURL = documentDirectory.appendingPathComponent(fileName).appendingPathExtension("plist")
        
        guard let dataFromFile = try? Data(contentsOf: archiveEmojisURL) else { return nil }
        guard let decodedEmojis = Emojis(from: dataFromFile) else { return nil }
        
        return decodedEmojis
    }
}
