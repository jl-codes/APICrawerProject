//
//  ViewController.swift
//  APICrawlerProject
//
//  Created by MAC on 7/16/19.
//  Copyright © 2019 John Loehr. All rights reserved.
//

import UIKit

final class ViewController: UIViewController {
  
  @IBOutlet weak var crawlerTableView: UITableView!
  
  @IBOutlet weak var forwardButton: UIBarButtonItem!
  @IBOutlet weak var navTitle: UINavigationItem!
  
  var dictionary: [String: Any] = [:]
  var array: [Any] = []
  var url = URL(string: "https://pokeapi.co/api/v2")
  var titleCurrent = "Pokemon Crawler"
  
  enum APITypes {
    case dictionary
    case array
    case number
    case string
    case boolean
    case null
    
    init?(value: Any) {
      if value is [String: Any] {
        self = .dictionary
      } else if value is NSNumber {
        self = .number
      } else if value is String {
        self = .string
      } else if value is Bool {
        self = .boolean
      } else if value is [Any] {
        self = .array
      } else if value is NSNull {
        self = .null
      } else {
        return nil
      }
    }
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    crawlerTableView.dataSource = self
    crawlerTableView.delegate = self
    crawlerTableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
    navTitle.title = titleCurrent
    
    if let url = url {
    URLSession.shared.dataTask(with: url) { (data, _, _) in
      guard let data = data,
        let jsonObject = try? JSONSerialization.jsonObject(with: data, options: []),
        let jsonDictionary = jsonObject as? [String: Any] else { return }
      self.dictionary = jsonDictionary
      DispatchQueue.main.async {
        self.crawlerTableView.reloadData()
      }
      }.resume()
    } else {
      self.crawlerTableView.reloadData()
    }
  }
}

extension ViewController: UITableViewDataSource {
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    if let url = url {
      return dictionary.count
    } else if array.count > 0 {
      return array.count
    }
    return dictionary.count
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "cell")
    //Update the labels here
    if dictionary.count == 0 && array.count > 0 {
      cell.textLabel?.text = "Array Index \(indexPath.row)"
    }
    else {
      let keys = Array(dictionary.keys)
      cell.textLabel?.text = keys[indexPath.row]
      guard let type = APITypes(value: dictionary[keys[indexPath.row]]) else { return cell }
      
      switch type {
      case .array:
        guard let array = dictionary[keys[indexPath.row]] as? [Any] else { return cell }
        cell.detailTextLabel?.text = "Array of size: \(array.count)"
      case .boolean:
        guard let details = dictionary[keys[indexPath.row]] as? Bool else { return cell }
        cell.detailTextLabel?.text = "\(details)"
      case .dictionary:
        guard var dictionary = dictionary[keys[indexPath.row]] as? [String: Any?] else { return cell }
        if let urlString = dictionary["url"] as? String {
          let url = URL(string: urlString)
          URLSession.shared.dataTask(with: url!) { (data, _, _) in
            guard let data = data,
              let json = try? JSONSerialization.jsonObject(with: data, options: []),
              let jsonDictionary = json as? [String: Any] else { return }
            dictionary = jsonDictionary
            DispatchQueue.main.async {
              cell.detailTextLabel?.text = "Dictionary of size: \(dictionary.keys.count)"
            }
          }.resume()
        }
        else {
          cell.detailTextLabel?.text = "Dictionary of size: \(dictionary.keys.count)"
        }
      case .null:
        guard let details = dictionary[keys[indexPath.row]] as? NSNull else { return cell }
        cell.detailTextLabel?.text = "\(details)"
      case .number:
        guard let details = dictionary[keys[indexPath.row]] as? Int else { return cell }
        cell.detailTextLabel?.text = "\(details)"
      case .string:
        guard let details = dictionary[keys[indexPath.row]] as? String else { return cell }
        cell.detailTextLabel?.text = "\(details)"
      }
      
    }
    return cell
  }
}

extension ViewController: UITableViewDelegate {
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    let storyboard = UIStoryboard(name: "Main", bundle: nil)
    let nextViewController = storyboard.instantiateViewController(withIdentifier: "ViewController") as! ViewController
    
    if array.count > 0 {
      if let value = array[indexPath.row] as? [String: Any] {
        if (value["url"] != nil) {
          nextViewController.url = URL(string: value["url"] as! String)
          
          navigationController?.pushViewController(nextViewController, animated: true)
        } else {
          nextViewController.dictionary = value
          nextViewController.url = URL(string: "")
          nextViewController.titleCurrent = "Array Index \(indexPath.row)"
          navigationController?.pushViewController(nextViewController, animated: true)
        }
      } else { return }
    }
    else {
      let keys = Array(dictionary.keys)
      if let value = dictionary[keys[indexPath.row]] as? String {
        if value.hasPrefix("https://pokeapi.co/") {
          let url = URL(string: value)
          nextViewController.url = url
          nextViewController.titleCurrent = keys[indexPath.row]
          navigationController?.pushViewController(nextViewController, animated: true)
        } else { return }
      }
      else if let value = dictionary[keys[indexPath.row]] as? [String: Any] {
        if let urlString = value["url"] as? String {
          let url = URL(string: urlString)
          
          nextViewController.url = url
          nextViewController.titleCurrent = keys[indexPath.row]
          navigationController?.pushViewController(nextViewController, animated: true)
        } else {
          nextViewController.dictionary = value
          nextViewController.titleCurrent = keys[indexPath.row]
          navigationController?.pushViewController(nextViewController, animated: true)
        }
      }
      else if let value = dictionary[keys[indexPath.row]] as? [Any] {
        nextViewController.array = value
        nextViewController.url = URL(string: "")
        nextViewController.titleCurrent = keys[indexPath.row]
        navigationController?.pushViewController(nextViewController, animated: true)
      }
      
    }
  }
  
  @IBAction func forwardButton(_ sender: Any) {
    navigationController?.popToRootViewController(animated: true)
  }
}
