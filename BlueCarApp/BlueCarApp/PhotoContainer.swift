/*
 *     Copyright 2016 IBM Corp.
 *     Licensed under the Apache License, Version 2.0 (the "License");
 *     you may not use this file except in compliance with the License.
 *     You may obtain a copy of the License at
 *     http://www.apache.org/licenses/LICENSE-2.0
 *     Unless required by applicable law or agreed to in writing, software
 *     distributed under the License is distributed on an "AS IS" BASIS,
 *     WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *     See the License for the specific language governing permissions and
 *     limitations under the License.
 */

import UIKit
import BMSCore
import BluemixObjectStorage
import BMSAnalytics

class PhotoContainer: UITableViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    let logger = Logger.logger(forName: "PhotoContainer")
    
    var tableTitle: String?
    
    var addButton: UIBarButtonItem?
    var deleteButton: UIBarButtonItem?
    var tapRecognizer: UITapGestureRecognizer?
    
    var objectStorage: ObjectStorage?
    var objectStorageContainer: ObjectStorageContainer?
    var objectList: [ObjectStorageObject] = []
    var contentCache: [String : UIImage] = [:]
    var credentials: [String: AnyObject]?
    
    override func viewDidLoad() {
        
        if let path = NSBundle.mainBundle().pathForResource("credentials", ofType: "plist"), credentials = NSDictionary(contentsOfFile: path) as? [String: AnyObject] {
            self.credentials = credentials
        }
        self.connect()
        self.tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.backgroundTap(_:)))
        self.addButton = UIBarButtonItem(barButtonSystemItem: .Add, target: self, action: #selector(self.addToContainer(_:)))
        self.deleteButton = UIBarButtonItem(barButtonSystemItem: .Trash, target: self, action: #selector(self.deleteFromContainer(_:)))
        self.refreshControl?.addTarget(self, action: #selector(self.refreshTableView(_:)), forControlEvents: .ValueChanged)
        self.refreshControl?.enabled = true
        self.view.addGestureRecognizer(tapRecognizer!)
        
        super.viewDidLoad()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(didBecomeActive), name: UIApplicationDidBecomeActiveNotification, object: nil)
    }
    
    func didBecomeActive(notification: NSNotification) {
        Analytics.send()
        Logger.send()
    }
    
    override func viewWillAppear(animated: Bool) {
        self.tableTitle = "Object Storage Starter"
        self.navigationItem.title = self.tableTitle
        
        if let _ = objectStorage {
            self.navigationItem.rightBarButtonItems = [self.addButton!]
        } else {
            self.navigationItem.rightBarButtonItems?.removeAll()
        }
        
        super.viewWillAppear(animated)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return objectList.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let row = indexPath.row
        let key = (self.objectList[row]).name
        let cell = tableView.dequeueReusableCellWithIdentifier("photoCell", forIndexPath: indexPath) as! PhotoCell
        
        cell.customImageView.image = nil // Until image is loaded, cell will have no content
        cell.customImageView.userInteractionEnabled = false // Disable user interaction until we have content to display
        cell.indicator.startAnimating()
        
        if contentCache.indexForKey(key) != nil { // We've loaded the image and we can set the content of the cell
            let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(self.longPress(_:)))
            
            cell.indicator.stopAnimating()
            cell.customImageView.image = contentCache[key]
            cell.customImageView.addGestureRecognizer(longPressRecognizer) // Add long press to select image once conten is available
            cell.customImageView.userInteractionEnabled = true // Once we have content to display, enable user interaction
        }
        else { // We haven't yet loaded the image. We need to do so and then added it to the content cache
            let object = self.objectList[row]
            object.load(shouldCache: false, completionHandler: { (error, data) in
                if let error = error {
                    self.logger.error("The following error occurred while loading an object from the object storage service: \(error)")
                    self.dispatchOnMainQueueAfterDelay(0) {
                        self.tableView.deleteRowsAtIndexPaths([NSIndexPath(forRow: row, inSection: 0)], withRowAnimation: .Right)
                    }
                    return
                } else {
                    let image = UIImage(data: data!)
                    self.contentCache[key] = image!
                    self.dispatchOnMainQueueAfterDelay(0) {
                        // Once we've loaded the image and added to the cache, we reload the appropriate cell in order to display the content
                        self.tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
                    }
                }
            })
        }

        return cell
    }
    
    func connect() {
        guard let credentials = self.credentials else {
            logger.error("Missing credentials.plist. Please correct this")
            let alert: UIAlertController = UIAlertController(title: "", message: "Missing credentials.plist. Please correct this.", preferredStyle: .Alert)
            alert.addAction(UIAlertAction(title: "Okay", style: .Cancel, handler: nil))
            self.presentViewController(alert, animated: true, completion: nil)
            
            return
        }
        let projectId = credentials["projectId"] as! String
        
        guard !projectId.isEmpty else {
            let alert: UIAlertController = UIAlertController(title: "", message: "Missing 'projectId' in credentials.plist. Please ensure you've correctly entered Object Storage credentials information.", preferredStyle: .Alert)
            alert.addAction(UIAlertAction(title: "Okay", style: .Cancel, handler: nil))
            self.parentViewController!.presentViewController(alert, animated: true, completion: nil)
            
            return
        }
        self.objectStorage = ObjectStorage(projectId: projectId);
        
        if let objectStorage = objectStorage {
            let userId = credentials["userId"] as! String
            
            guard !userId.isEmpty else {
                let alert: UIAlertController = UIAlertController(title: "", message: "Missing 'userId' in credentials.plist. Please ensure you've correctly entered Object Storage credentials information.", preferredStyle: .Alert)
                alert.addAction(UIAlertAction(title: "Okay", style: .Cancel, handler: nil))
                self.parentViewController!.presentViewController(alert, animated: true, completion: nil)
                
                return
            }
            let password = credentials["password"] as! String
            
            guard !password.isEmpty else {
                let alert: UIAlertController = UIAlertController(title: "", message: "Missing 'password' in credentials.plist. Please ensure you've correctly entered Object Storage credentials information.", preferredStyle: .Alert)
                alert.addAction(UIAlertAction(title: "Okay", style: .Cancel, handler: nil))
                self.parentViewController!.presentViewController(alert, animated: true, completion: nil)
                
                return
            }
            
            objectStorage.connect(userId: userId, password: password, region: ObjectStorage.REGION_DALLAS, completionHandler: { (error) in
                if let error = error {
                    self.logger.error("connect error :: \(error)")
                    let alert: UIAlertController = UIAlertController(title: "", message: "An error ocurred while connecting to the object storage service: \(error)", preferredStyle: .Alert)
                    alert.addAction(UIAlertAction(title: "Okay", style: .Cancel, handler: nil))
                    self.presentViewController(alert, animated: true, completion: nil)
                } else {
                    self.logger.info("connect success")
                    self.setContainer()
                }
            })
        }
    }
    
    func setContainer() {
        let container = self.credentials!["container"] as! String
        
        guard !container.isEmpty else {
            let alert: UIAlertController = UIAlertController(title: "", message: "Missing 'container' in credentials.plist. Please ensure you've correctly entered the Object Storage container you wish to work with.", preferredStyle: .Alert)
            alert.addAction(UIAlertAction(title: "Okay", style: .Cancel, handler: nil))
            self.parentViewController!.presentViewController(alert, animated: true, completion: nil)
            
            return
        }
    
        self.objectStorage!.retrieveContainer(name: container, completionHandler: { (error, container) in
            if let error = error {
                self.logger.error("The following error occurred while attempting to objtain the object storage container: \(error)")
                let alert: UIAlertController = UIAlertController(title: "", message: "An error ocurred while attempting to objtain the object storage container: \(error)", preferredStyle: .Alert)
                alert.addAction(UIAlertAction(title: "Okay", style: .Cancel, handler: nil))
                self.presentViewController(alert, animated: true, completion: nil)
            } else {
                self.logger.info("Successfully retrieved container")
                self.objectStorageContainer = container;
                self.refreshTableView(nil)
            }
        })
    }
    
    func refreshTableView(refreshControl: UIRefreshControl?) {
        guard let objectStorageContainer = objectStorageContainer else {
            return
        }
        
        objectStorageContainer.retrieveObjectsList { (error, objects) in
            if let error = error {
                self.logger.error("The following error occurred while retrieving the list of objects from object storage: \(error)")
                let alert: UIAlertController = UIAlertController(title: "", message: "An error ocurred while retrieving the list of objects from object storage: \(error)", preferredStyle: .Alert)
                alert.addAction(UIAlertAction(title: "Okay", style: .Cancel, handler: nil))
                self.presentViewController(alert, animated: true, completion: nil)
            } else {
                self.setupTableView(objects!)
            }
        }
        
        if let refreshControl = refreshControl {
            refreshControl.endRefreshing()
        }
    }
    
    func setupTableView(containerContents: [ObjectStorageObject]) {
        if containerContents == self.objectList {
            return
        }
        let oldSet = Set(self.objectList)
        let newSet = Set(containerContents)
        let deleteDifference = oldSet.subtract(newSet)
        let insertDifference = newSet.subtract(oldSet)
        
        self.deleteRows(deleteDifference)
        self.insertRows(insertDifference, list: containerContents)
        self.dispatchOnMainQueueAfterDelay(0) {
            self.tableView.reloadData()
            self.addButton?.enabled = true
            self.navigationItem.rightBarButtonItems = [self.addButton!]
        }
    }
    
    func insertRows(set: Set<ObjectStorageObject>, list: Array<ObjectStorageObject>) {
        if set.count == 0 {
            return
        }
        var indexPaths: [NSIndexPath] = []
        let elementsToInsert = set.sort { (object1, object2) -> Bool in
            return object1.name <= object2.name
        }
        
        for element in elementsToInsert {
            let index = list.indexOf(element)
            self.objectList.insert(element, atIndex: index!)
            indexPaths.append(NSIndexPath(forRow: (self.objectList.count - 1), inSection: 0))
        }
        self.dispatchOnMainQueueAfterDelay(0) {
            self.tableView.insertRowsAtIndexPaths(indexPaths, withRowAnimation: .Left)
        }
    }
    
    func deleteRows(set: Set<ObjectStorageObject>) {
        if set.count == 0 {
            return
        }
        var indexPaths: [NSIndexPath] = []
        var i = 1
        
        for element in set {
            let index = self.objectList.indexOf(element)
            self.objectList.removeAtIndex(index!)
            self.contentCache.removeValueForKey(element.name)
            indexPaths.append(NSIndexPath(forRow: (self.tableView.numberOfRowsInSection(0) - i), inSection: 0))
            i += 1
        }
        self.dispatchOnMainQueueAfterDelay(0) {
            self.tableView.deleteRowsAtIndexPaths(indexPaths, withRowAnimation: .Right)
        }
    }
    
    func backgroundTap(recognizer: UITapGestureRecognizer) {
        guard let indexPath = self.tableView.indexPathForSelectedRow else {
            return
        }
        self.navigationController?.setToolbarHidden(true, animated: true)
        self.navigationItem.rightBarButtonItems = [self.addButton!]
        self.tableView.deselectRowAtIndexPath(indexPath, animated: true)
        self.navigationItem.title = self.tableTitle!
    }
    
    func longPress(recognizer: UILongPressGestureRecognizer?) {
        let view = recognizer?.view as! UIImageView
        let keys = (contentCache as NSDictionary).allKeysForObject(view.image!)
        let key = keys[0] as! String
        var row: Int?
        
        for object in self.objectList {
            if object.name == key {
                row = self.objectList.indexOf(object)
            }
        }
        let indexPath = NSIndexPath(forRow: row!, inSection: 0)
        
        self.tableView.selectRowAtIndexPath(indexPath, animated: true, scrollPosition: .None)
        self.navigationController?.toolbar.setItems([UIBarButtonItem(barButtonSystemItem: .FlexibleSpace, target: nil, action: nil), self.deleteButton!, UIBarButtonItem(barButtonSystemItem: .FlexibleSpace, target: nil, action: nil)], animated: true)
        self.navigationController?.setToolbarHidden(false, animated: true)
        self.navigationItem.rightBarButtonItems?.removeAll()
        self.navigationItem.title = (key)
    }
    
    func addToContainer(sender: AnyObject?) {
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.Camera) {
            let alert = UIAlertController(title: "", message: "Where would you like to upload a photo from?", preferredStyle: .ActionSheet)
            
            alert.addAction(UIAlertAction(title: "Camera", style: .Default, handler: { (alertAction) in
                self.addFromCamera()
            }))
            alert.addAction(UIAlertAction(title: "Photo Library", style: .Default, handler: { (alertAction) in
                self.addFromPhotoLibrary()
            }))
            self.presentViewController(alert, animated: true, completion: nil)
        }
        else {
            self.addFromPhotoLibrary()
        }
    }
    
    func deleteFromContainer(image: UIImage?) {
        guard let indexPath = self.tableView.indexPathForSelectedRow else {
            return
        }
        let alert = UIAlertController(title: "", message: "Are you sure you want to do that?", preferredStyle: .Alert)
        alert.addAction(UIAlertAction(title: "Delete", style: .Default, handler: {(alertAction) in
            let imageName = (self.objectList[indexPath.row]).name
            self.deleteImage(imageName)
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
        self.presentViewController(alert, animated: true, completion: nil)
        self.navigationController?.setToolbarHidden(true, animated: true)
        self.navigationItem.rightBarButtonItem = self.addButton
        self.tableView.deselectRowAtIndexPath(indexPath, animated: true)
        self.navigationItem.title = self.tableTitle!
    }
    
    func store(image: NSData, withName: String) {
        objectStorageContainer?.storeObject(name: withName, data: UIImageJPEGRepresentation(UIImage(data: image)!, 0.5)!, completionHandler: { (error, object) in
            if let error = error {
                self.logger.error("The following error occurred while loading an image into the object storage service: \(error)")
                let alert = UIAlertController(title: "", message: "An error ocurred while uploading \(withName)", preferredStyle: .Alert)
                alert.addAction(UIAlertAction(title: "Okay", style: .Cancel, handler: nil))
                self.dispatchOnMainQueueAfterDelay(0) {
                    self.presentViewController(alert, animated: true, completion: nil)
                }
            } else {
                self.refreshTableView(nil)
            }
        })
    }
    
    func deleteImage(withName: String) {
        objectStorageContainer?.deleteObject(name: withName, completionHandler: { (error) in
            if let error = error {
                self.logger.error("The following error occurred while deleting \(withName) from the object storage service: \(error)")
                let alert = UIAlertController(title: "", message: "An error ocurred while deleting \(withName)", preferredStyle: .Alert)
                alert.addAction(UIAlertAction(title: "Okay", style: .Destructive, handler: {(alertAction) in
                    self.refreshTableView(nil)
                }))
            } else {
                self.refreshTableView(nil)
            }
        })
        
    }
    
    func addFromPhotoLibrary() {
        let imagePicker:UIImagePickerController = UIImagePickerController()
        
        imagePicker.sourceType = UIImagePickerControllerSourceType.PhotoLibrary
        imagePicker.delegate = self
        self.presentViewController(imagePicker, animated: true, completion: nil)
    }

    func addFromCamera() {
        let imagePicker:UIImagePickerController = UIImagePickerController()
        
        imagePicker.sourceType = UIImagePickerControllerSourceType.Camera
        imagePicker.delegate = self
        self.presentViewController(imagePicker, animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(picker: UIImagePickerController){
        picker.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        let image: UIImage = info[UIImagePickerControllerOriginalImage] as! UIImage
        let imageContent = UIImageJPEGRepresentation(image, 0.5)!
        let alert = UIAlertController(title: "", message: "Name?", preferredStyle: .Alert)
        alert.addTextFieldWithConfigurationHandler { (textField: UITextField!) in
            textField.placeholder = "Enter image name"
        }
        alert.addAction(UIAlertAction(title: "Okay", style: .Default, handler: { (action) in
            let textField = alert.textFields![0] as UITextField
            let imageName = textField.text!
            self.store(imageContent, withName: "\(imageName).jpg")
        }))
        
        picker.dismissViewControllerAnimated(true, completion: nil)
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    func dispatchOnMainQueueAfterDelay(delay:Double, closure:()->()) {
        dispatch_after(
            dispatch_time(
                DISPATCH_TIME_NOW,
                Int64(delay * Double(NSEC_PER_SEC))+100
            ),
            dispatch_get_main_queue(), closure)
    }
}

extension ObjectStorageObject: Hashable, Equatable {
    
    public var hashValue: Int {
        return name.hash
    }
}

public func ==(lhs: ObjectStorageObject, rhs: ObjectStorageObject) -> Bool {
    return lhs.name == rhs.name
}

