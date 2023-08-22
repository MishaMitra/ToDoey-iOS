//
//  ViewController.swift
//  Todoey
//
//  Created by Philipp Muellauer on 02/12/2019.
//  Copyright © 2019 App Brewery. All rights reserved.
//

import UIKit
import RealmSwift
import ChameleonFramework

class TodoListViewController: SwipeTableViewController  {
    var toDoItems:Results<Item>?
    let realm = try! Realm()
    
    @IBOutlet weak var SearchBarOutlet: UISearchBar!
    var selectedCategory : Category? {
        didSet {
            loadItems()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.separatorStyle = .none
        
        
    }
    
    override func viewWillAppear(_ animated:Bool) {
        
        let appearance = UINavigationBarAppearance(idiom: .phone)

        if let colorHex = selectedCategory?.color {
            title = selectedCategory?.name
            guard let navBar = navigationController?.navigationBar else {fatalError("Navigation Controller does not exist.")}
            if let navBarColor = UIColor(hexString: colorHex) {
                navBar.tintColor = ContrastColorOf(navBarColor, returnFlat: true)
 
                appearance.largeTitleTextAttributes = [.foregroundColor: ContrastColorOf(navBarColor, returnFlat: true)]
                appearance.titleTextAttributes = [.foregroundColor:  ContrastColorOf(navBarColor, returnFlat: true)]
                appearance.backgroundColor = UIColor(hexString: colorHex)
                navigationItem.standardAppearance = appearance
                navigationItem.scrollEdgeAppearance = appearance
            }
            
        }

    }
    
    //MARK: - TableView Delegates Methods
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return toDoItems?.count ?? 1
    }
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = super.tableView(tableView, cellForRowAt: indexPath)
        if let item = toDoItems? [indexPath.row] {
            cell.textLabel?.text = item.title
            
            if let color = UIColor(hexString: selectedCategory!.color)?.darken(byPercentage:CGFloat(indexPath.row)/CGFloat(toDoItems!.count)) {
                cell.backgroundColor = color
                cell.textLabel?.textColor = UIColor(contrastingBlackOrWhiteColorOn:color, isFlat: true)
                
            }
            
            cell.accessoryType = item.done ? .checkmark : .none
        } else {
            cell.textLabel?.text = "No Items Added"
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let item = toDoItems?[indexPath.row] {
            do { try realm.write {
                item.done = !item.done
            }
                
            } catch {
                print("Error saving done status \(error)")
            }
            tableView.reloadData()
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    // MARK: - Add New Item
    
    @IBAction func addButtonPressed(_ sender: UIBarButtonItem) {
        var textField = UITextField()
        let alert = UIAlertController(title: "Add Todoey Item", message: "", preferredStyle: .alert)
        let action = UIAlertAction(title: "Add Item", style: .default) { [self](action) in
            // what will happen once the user clickthe Add Itemon our UIAlert
            
            
            if let currentCategory = self.selectedCategory {
                
                do {
                    try self.realm.write(){
                        let newItem = Item ()
                        newItem.title = textField.text!
                        newItem.dateCreated = Date()
                        currentCategory.items.append(newItem)
                    }
                } catch {
                    print("Error saving new item \(error)")
                }
            }
            
            self.tableView.reloadData()
        }
        
        alert.addTextField  { alertTextField in
            alertTextField.placeholder = "Create new Item"
            textField = alertTextField
            
        }
        alert.addAction(action)
        present(alert, animated: true)
    }
    
    // MARK: -  Model Manipulation Method
    
    func loadItems () {
        toDoItems = selectedCategory?.items.sorted(byKeyPath: "title", ascending: true)
        tableView.reloadData()
    }
    // MARK: - Delete Data From Swipe
    override func updateModel(at indexPath: IndexPath) {
        if let itemForDeletion = self.toDoItems?[indexPath.row] {
            do {
                try self.realm.write {
                    self.realm.delete(itemForDeletion)
                }} catch {
                    print("Error delete Category \(error)")
                }
        }
    }
}
//MARK: - Search Bar Methods

extension TodoListViewController : UISearchBarDelegate {
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        toDoItems = toDoItems?.filter("title CONTAINS [cd] %@", searchBar.text!).sorted(byKeyPath: "dateCreated",ascending: true)
        tableView.reloadData()
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchBar.text?.count == 0 {
            loadItems()
            DispatchQueue.main.async {
                searchBar.resignFirstResponder()
            }
        }
    }
}


