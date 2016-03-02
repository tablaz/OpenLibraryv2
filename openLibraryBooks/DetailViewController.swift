//
//  DetailViewController.swift
//  openLibraryBooks
//
//  Created by Ricardo on 01/03/2016.
//  Copyright © 2016 Tablaz. All rights reserved.
//

import UIKit

class DetailViewController: UIViewController {

    
    
    @IBOutlet weak var detailDescriptionLabel: UILabel!

    @IBOutlet weak var coverImage: UIImageView!
    
    
    @IBOutlet weak var authorsList: UITextView!
    
    

    var detailItem: Book? {

        didSet {
            // Update the view.
            self.configureView()
        }
    }

    func configureView() {
        // Update the user interface for the detail item.
        if let detail = self.detailItem {
            if let label = self.detailDescriptionLabel {
                label.text = detail.title
            }
            if let cover = self.coverImage{
                cover.image = detail.cover
            }
            if let authors = self.authorsList{
                var authorsList: String = "Authors:\n"
                for author in detail.authors {
                    authorsList = authorsList+"\(author)\n"
                }
                authors.text = authorsList as String
            }

        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.configureView()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

