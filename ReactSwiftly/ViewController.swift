//
//  ViewController.swift
//  NSInventory
//
//  Created by Sam Youtsey on 9/30/15.
//  Copyright © 2015 samswiches. All rights reserved.
//

import UIKit
import ReactiveCocoa

class ViewController: UIViewController {
    
    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var nameLabel: UILabel!
    
    let localURL = "http://localhost:8001/hello/"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let searchStrings = self.textField.rac_textSignal().toSignalProducer()
        let searchResults = searchStrings
            .flatMap(.Latest) { query in
                let name = query as! String
                let request = NSURLRequest(URL: NSURL(string: self.localURL + name)!)
                
                return NSURLSession.sharedSession()
                    .rac_dataWithRequest(request)
                    .retry(2)
                    .flatMapError { error in
                        print("Network error occurred: \(error)")
                        return SignalProducer.empty
                }
            }
            .map({ (data: NSData, response: NSURLResponse) -> String in
                return self.parseJSONResultsFromData(data)
            })
            .observeOn(UIScheduler())
        
        searchResults.start({ results in
            self.nameLabel.text = "Hello " + results.value!
        })
    }
    
    func parseJSONResultsFromData(data: NSData) -> String {
        do {
            let jsonData = try NSJSONSerialization.JSONObjectWithData(data, options: .MutableContainers) as! NSDictionary
            let name = jsonData.objectForKey("name") as! String
            return name
        } catch let error as NSError {
            print("ERROR: \(error)")
            return ""
        }
    }
}

