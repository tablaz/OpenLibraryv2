//
//  MasterViewController.swift
//  openLibraryBooks
//
//  Created by Ricardo on 01/03/2016.
//  Copyright © 2016 Tablaz. All rights reserved.
//

import UIKit
import CoreData

struct Book {
    var isbn : String
    var title : String
    var cover : UIImage
    var authors : [String]
    
    
    init(isbn : String, title: String, cover : UIImage, authors : [String]){
        self.isbn  = isbn
        self.title = title
        self.cover = cover
        self.authors = authors
    }
}


class MasterViewController: UITableViewController {

    var detailViewController: DetailViewController? = nil
    var objects = [AnyObject]()
    var booksStruc = [Book]()
    
    var context : NSManagedObjectContext? = nil


    @IBAction func bookSearch(sender: UITextField) {
        
        
        let bookEntity = NSEntityDescription.entityForName("Book", inManagedObjectContext: self.context!)
        let request = bookEntity?.managedObjectModel.fetchRequestFromTemplateWithName("getBook", substitutionVariables: ["isbn" : sender.text!])
        
        do { let bookEntitySearch = try self.context?.executeFetchRequest(request!)
            if (bookEntitySearch?.count > 0){
                print("ya esta ese ISBN")
                return
            }
            
        } catch {
            
        }
        
        
        let bookResult : Book = searchOpenLibraryByISBN(sender)
        if (bookResult.title != "") {
            let newBookEntity = NSEntityDescription.insertNewObjectForEntityForName("Book", inManagedObjectContext: self.context!)
            
            newBookEntity.setValue(bookResult.isbn, forKey: "isbn")
            newBookEntity.setValue(bookResult.title, forKey: "title")
            newBookEntity.setValue(UIImagePNGRepresentation(bookResult.cover), forKey: "cover")
            newBookEntity.setValue(createAuthorsEntity(bookResult.authors), forKey: "has")
            
            do{
                try self.context?.save()
            } catch{
                
            }
            
            booksStruc.append(bookResult)
            self.tableView!.reloadData()
            sender.text = ""
            sender.resignFirstResponder()
            
            /* Trying to push the detail view programatically */
            let lastSectionIndex = self.tableView.numberOfSections-1
            let lastSectionLastRow = self.tableView.numberOfRowsInSection(lastSectionIndex) - 1
            let indexPath = NSIndexPath(forRow:lastSectionLastRow, inSection: lastSectionIndex)
            // let cell = tableView.cellForRowAtIndexPath(indexPath)
            // print(cell?.textLabel?.text)
            self.tableView.selectRowAtIndexPath(indexPath, animated: true, scrollPosition: .Middle)
            self.performSegueWithIdentifier("showDetail", sender: nil )
        }
        
    }
    
    
    @IBOutlet weak var bookSearch: UITextField!

    func createAuthorsEntity(authors : [String]) -> Set<NSObject> {
        var entities = Set<NSObject>()
        
        for author in authors {
            let authorEntity = NSEntityDescription.insertNewObjectForEntityForName("Author", inManagedObjectContext: self.context!)
            authorEntity.setValue(author, forKey: "name")
            entities.insert(authorEntity)
        }
        return entities
    }
    
    
    func searchOpenLibraryByISBN(sender: UITextField) -> Book {
        let isbn : String = sender.text!
        


        var books : Book = Book(isbn: isbn, title: "", cover: UIImage() , authors: [])

        
        let urls = "https://openlibrary.org/api/books?jscmd=data&format=json&bibkeys=ISBN:\(isbn)"
        let safeURL = urls.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())!
        let url = NSURL(string: safeURL)
        let datos:NSData? = NSData(contentsOfURL: url!)
        let texto = NSString(data:datos!, encoding: NSUTF8StringEncoding)
        if texto == "{}" || texto == "" {
            let alerta = UIAlertController(title: "Search Result", message: "No Data Found", preferredStyle: UIAlertControllerStyle.Alert)
            alerta.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Cancel, handler: nil))
            self.presentViewController(alerta, animated: true, completion: nil)
            sender.text = "";
        } else if texto == nil {
            let alerta = UIAlertController(title: "Search Result", message: "No Data Found, check Internet connection", preferredStyle: UIAlertControllerStyle.Alert)
            alerta.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Cancel, handler: nil))
            self.presentViewController(alerta, animated: true, completion: nil)
            sender.text = "";
        } else {
            books =  self.parceBooksJson(datos!, isbn: isbn)
            
        }
        
        return books
    }
    
    
    
    func parceBooksJson(nsdata: NSData, isbn: String) -> Book {
        var bookDoc : Book = Book(isbn: "", title: "", cover: UIImage() , authors: [])
        
        do {
            
            let jsonFull = try NSJSONSerialization.JSONObjectWithData(nsdata, options: NSJSONReadingOptions.MutableContainers) as! [String: AnyObject]
            let bookArray = jsonFull as NSDictionary
            for (_, value) in bookArray {
                // Process Book Title
                let title  = value["title"] as! String

                // Process Author List
                let authors = value["authors"]! != nil ? value["authors"] as! NSArray : []
                var authorsArray : [String] = [String]()
                for author in authors {
                    let authorName = author["name"] as! String
                    authorsArray.append(authorName)
                }
                
                // Process Book Cover
                var cover : UIImage = UIImage(named: "nocover")!
                
                if value["cover"] != nil {
                    let imageUrls = value["cover"]??["large"]
                    if imageUrls != nil {
                        let url = NSURL(string: imageUrls as! String)
                        let data = NSData(contentsOfURL: url!)
                        cover = UIImage(data: data!)!
                    }
                }
                
                bookDoc = Book(isbn : isbn, title: title, cover: cover , authors: authorsArray)
            }
            
            
        } catch {
            print("Error")

        }
        
        return bookDoc
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        self.context = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext
        
        // Do any additional setup after loading the view, typically from a nib.
        
        // self.navigationItem.leftBarButtonItem = self.editButtonItem()
        
         let addButton = UIBarButtonItem(barButtonSystemItem: .Add, target: self, action: "enableBookSearch:")
        //let addButton = UIBarButtonItem(barButtonSystemItem: .Add, target: self, action: "insertNewObject:")
        self.navigationItem.rightBarButtonItem = addButton
        if let split = self.splitViewController {
            let controllers = split.viewControllers
            self.detailViewController = (controllers[controllers.count-1] as! UINavigationController).topViewController as? DetailViewController
        }
        
        // LOAD DATA
        self.context = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext
        
        let seccionEntity = NSEntityDescription.entityForName("Book", inManagedObjectContext: self.context!)
        
        let request = seccionEntity?.managedObjectModel.fetchRequestTemplateForName("getBooks")
        do{
            let bookEntities = try self.context?.executeFetchRequest(request!)
            for bookEntity in bookEntities! {
                let title = bookEntity.valueForKey("title") as! String
                let isbn = bookEntity.valueForKey("isbn") as! String
                let cover : UIImage = UIImage(data: bookEntity.valueForKey("cover") as! NSData)!
                
                let authorEntities = bookEntity.valueForKey("has") as! Set<NSObject>
                var authorArray = [String]()
                for authorEntity in authorEntities {
                    let author = authorEntity.valueForKey("name") as! String
                    authorArray.append(author)
                    
                }
                self.booksStruc.append(Book(isbn: isbn, title: title, cover: cover, authors: authorArray))
                
            }
        } catch{
            
        }
        
    }

    func enableBookSearch(sender: AnyObject) {
        self.bookSearch.hidden = false
        self.bookSearch.resignFirstResponder()
    }
    
    override func viewWillAppear(animated: Bool) {
        self.clearsSelectionOnViewWillAppear = self.splitViewController!.collapsed
        super.viewWillAppear(animated)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
/*
    func insertNewObject(sender: AnyObject) {
        objects.insert(NSDate(), atIndex: 0)
        let indexPath = NSIndexPath(forRow: 0, inSection: 0)
        self.tableView.insertRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
    }
*/
    // MARK: - Segues

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "showDetail" {
            if let indexPath = self.tableView.indexPathForSelectedRow {
                let object = booksStruc[indexPath.row]
                let controller = (segue.destinationViewController as! UINavigationController).topViewController as! DetailViewController
                controller.detailItem = object
                controller.navigationItem.leftBarButtonItem = self.splitViewController?.displayModeButtonItem()
                controller.navigationItem.leftItemsSupplementBackButton = true
            }
        }
    }

    // MARK: - Table View

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        //return objects.count
        return booksStruc.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath)
        cell.textLabel!.text = booksStruc[indexPath.row].title
        return cell
        
    }

    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return false
    }

    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            objects.removeAtIndex(indexPath.row)
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        } else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
        }
    }


}

