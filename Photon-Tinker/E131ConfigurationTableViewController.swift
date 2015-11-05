//
//  E131ConfigurationTableViewController.swift
//  Particle
//
//  Created by James Adams on 10/26/15.
//  Copyright © 2015 spark. All rights reserved.
//

import Foundation

let numbersOfTableSections = 3
let tableSectionNames = ["Configure", "Info", "Outputs"]
let tableSectionNumberOfRows = [2, 3, 16]

let numberOfItemsToRefresh = 3

enum TextFieldType: Int {
    case Name = 0
    case UniverseSize
    case IPAddress
}

enum TableViewSection: Int {
    case Configure = 0
    case Info
    case Outputs
}

enum TableViewConfigureRows: Int {
    case Name = 0
    case UniverseSize
    //case IPAddress
    //case IPAddressPicker
}

enum TableViewInfoRows: Int {
    case FirmwareVersion = 0
    case SystemVersion
    case IPAddress
}

class E131ConfigurationTableViewController: UITableViewController, UITextFieldDelegate {
    
    var device : SparkDevice!
    var itemRefreshCount = 0
    var textFieldTextColor: UIColor?
    var localIPAddress: String?
    var universeSize: Int?
    var selectedTableViewRow: Int!
    
    //MARK: - Initialization
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.backgroundColor = UIColor(patternImage: self.imageResize(UIImage(named: "imgTrianglifyBackgroundBlue")!, newRect: UIScreen.mainScreen().bounds))
        
        self.refreshControl?.addTarget(self, action: "loadDevices", forControlEvents: UIControlEvents.ValueChanged)
        self.refreshControl?.tintColor = UIColor.blackColor()
        
        let bar:UINavigationBar! =  self.navigationController?.navigationBar
        bar.setBackgroundImage(UIImage(named: "imgTrianglifyBackgroundBlue"), forBarMetrics: UIBarMetrics.Default)
        
        self.title = self.device.name
        
        let cell:LabelAndTextFieldTableViewCell = self.tableView.dequeueReusableCellWithIdentifier("labelAndTextFieldCell") as! LabelAndTextFieldTableViewCell
        self.textFieldTextColor = cell.textField.textColor
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if segue.identifier == "settings"
        {
            if let navController = segue.destinationViewController as? UINavigationController
            {
                if let vc = navController.topViewController as? SettingsTableViewController
                {
                    vc.device = self.device
                }
            }
        }
        else if segue.identifier == "outputs"
        {
            if let vc = segue.destinationViewController as? OutputConfigurationTableViewController
            {
                vc.device = self.device
                vc.universeSize = self.universeSize
                vc.output = self.selectedTableViewRow
            }
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.refreshControl?.beginRefreshing()
        self.tableView.setContentOffset(CGPointMake(0, -(self.refreshControl?.frame.size.height)!), animated:true)
        self.loadDevices()
    }
    
    func imageResize(image:UIImage, newRect:CGRect) -> UIImage {
        let scale = UIScreen.mainScreen().scale
        UIGraphicsBeginImageContext(newRect.size)
        UIGraphicsBeginImageContextWithOptions(newRect.size, false, scale);
        image.drawInRect(CGRectMake(newRect.origin.x, newRect.origin.y, newRect.size.width, newRect.size.height))
        let newImage : UIImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage
    }
    
    // MARK: - Loading/Refresh
    
    func loadDevices()
    {
        dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
            
            self.device.refresh({ (error:NSError?) -> Void in
                if let e = error
                {
                    print("error loading device for user \(SparkCloud.sharedInstance().loggedInUsername)")
                    print(e.description)
                    TSMessage.showNotificationWithTitle("Error", subtitle: "Error loading device, please check internet connection.", type: .Error)
                }
                else
                {   
                    dispatch_async(dispatch_get_main_queue()) {
                        self.tableView.reloadData()
                    }
                }
            })
        }
    }
    
    // MARK: - TextField
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return false
    }
    
    func textFieldDidEndEditing(textField: UITextField) {
        // change name, ip, universe size
        if let tag = TextFieldType(rawValue: textField.tag)
        {
            switch tag
            {
            case TextFieldType.Name:
                self.device.rename(textField.text, completion: { (error:NSError?) -> Void in
                    if let _ = error
                    {
                        TSMessage.showNotificationWithTitle("Error", subtitle: "Error renaming device, please check internet connection.", type: .Error)
                    }
                    else
                    {
                        
                        TSMessage.showNotificationWithTitle("Success", subtitle: "Renamed device to " + textField.text!, type:TSMessageNotificationType.Success)
                        //TSMessage.showNotificationInViewController(self, title: "Success", subtitle: "Renamed device to " + textField.text!, type:TSMessageNotificationType.Success, duration:1.0)
                        self.title = self.device.name
                        NSNotificationCenter.defaultCenter().postNotificationName("UpdateDeviceName", object: self.device)
                    }
                })
            case TextFieldType.UniverseSize:
                print("universe")
                // TODO: Implement universizeSize updates
            case TextFieldType.IPAddress:
                print("IP")
                // TODO: Implement IPAddress updates
            }
        }
    }
    
    //MARK: - TableView Methods
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        self.itemRefreshCount = 0
        return numbersOfTableSections;
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tableSectionNumberOfRows[section]
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return tableSectionNames[section]
    }
    
    override func tableView(tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        
        let header: UITableViewHeaderFooterView = view as! UITableViewHeaderFooterView
        header.textLabel?.textColor = UIColor.blackColor()
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return self.tableView.rowHeight
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        var masterCell : UITableViewCell?
        
        switch indexPath.section
        {
        case TableViewSection.Configure.rawValue: // Configure Section
            switch indexPath.row
            {
            case TableViewConfigureRows.Name.rawValue: // Name Row
                let cell:LabelAndTextFieldTableViewCell = self.tableView.dequeueReusableCellWithIdentifier("labelAndTextFieldCell") as! LabelAndTextFieldTableViewCell
                cell.label.text = "Name"
                cell.textField.delegate = self
                cell.textField.keyboardType = UIKeyboardType.Default
                cell.textField.tag = TextFieldType.Name.rawValue
                if let name = device.name
                {
                    cell.textField.text = name
                }
                else
                {
                    cell.textField.text = "<No Name>"
                }
                masterCell = cell
            case TableViewConfigureRows.UniverseSize.rawValue : // Universe Size Row
                let cell:LabelAndTextFieldTableViewCell = self.tableView.dequeueReusableCellWithIdentifier("labelAndTextFieldCell") as! LabelAndTextFieldTableViewCell
                cell.label.text = "Universe Size"
                cell.textField.delegate = self
                cell.textField.keyboardType = UIKeyboardType.NumberPad
                cell.textField.tag = TextFieldType.UniverseSize.rawValue
                cell.textField.enabled = false
                device.getVariable("universeSize", completion: { (theResult:AnyObject!, error:NSError?) -> Void in
                    if let universeSize: Int = theResult as? Int
                    {
                        cell.textField.text = String(universeSize)
                        self.universeSize = universeSize
                    }
                    else
                    {
                        cell.textField.text = "Undefined"
                    }
                    cell.textField.enabled = true
                    
                    // Finish the refresh after all variables have loaded
                    if(++self.itemRefreshCount >= numberOfItemsToRefresh)
                    {
                        self.refreshControl?.endRefreshing()
                    }
                })
                
                masterCell = cell
            default :
                masterCell = nil
            }
        case TableViewSection.Info.rawValue: // Info Section
            
            switch indexPath.row
            {
            case TableViewInfoRows.FirmwareVersion.rawValue : // Firmware Version Row
                let cell:UITableViewCell = self.tableView.dequeueReusableCellWithIdentifier("rightDetailCell")! as UITableViewCell
                cell.textLabel?.text = "Firmware Version";
                cell.detailTextLabel?.textColor = UIColor.whiteColor()
                device.getVariable("e131FVersion", completion: { (theResult:AnyObject!, error:NSError?) -> Void in
                    if let firmwareVersion: String = theResult as? String
                    {
                        cell.detailTextLabel!.text = firmwareVersion
                    }
                    else
                    {
                        cell.detailTextLabel!.text = "Undefined"
                    }
                    
                    // Finish the refresh after all variables have loaded
                    if(++self.itemRefreshCount >= numberOfItemsToRefresh)
                    {
                        self.refreshControl?.endRefreshing()
                    }
                })
                masterCell = cell
            case TableViewInfoRows.SystemVersion.rawValue : // Firmware Version Row
                let cell:UITableViewCell = self.tableView.dequeueReusableCellWithIdentifier("rightDetailCell")! as UITableViewCell
                cell.textLabel?.text = "System Version";
                cell.detailTextLabel?.textColor = UIColor.whiteColor()
                device.getVariable("sysVersion", completion: { (theResult:AnyObject!, error:NSError?) -> Void in
                    if let firmwareVersion: String = theResult as? String
                    {
                        cell.detailTextLabel!.text = firmwareVersion
                    }
                    else
                    {
                        cell.detailTextLabel!.text = "Undefined"
                    }
                    
                    // Finish the refresh after all variables have loaded
                    if(++self.itemRefreshCount >= numberOfItemsToRefresh)
                    {
                        self.refreshControl?.endRefreshing()
                    }
                })
                masterCell = cell
            case TableViewInfoRows.IPAddress.rawValue : // Local IP Address Row
                let cell:UITableViewCell = self.tableView.dequeueReusableCellWithIdentifier("rightDetailCell")! as UITableViewCell
                cell.textLabel?.text = "Local IP Address";
                cell.detailTextLabel?.textColor = UIColor.whiteColor()
                device.getVariable("localIP", completion: { (theResult:AnyObject!, error:NSError?) -> Void in
                    if let localIP: String = theResult as? String
                    {
                        cell.detailTextLabel!.text = localIP
                    }
                    else
                    {
                        cell.detailTextLabel?.text = "Undefined"
                    }
                    
                    // Finish the refresh after all variables have loaded
                    if(++self.itemRefreshCount >= numberOfItemsToRefresh)
                    {
                        self.refreshControl?.endRefreshing()
                    }
                })
                masterCell = cell
            default :
                masterCell = nil
            }
        case TableViewSection.Outputs.rawValue: // Outputs Section
            
            let cell:UITableViewCell = self.tableView.dequeueReusableCellWithIdentifier("basicDisclosureIndicatorCell")! as UITableViewCell
            cell.textLabel!.text = String(indexPath.row + 1)
            cell.textLabel!.backgroundColor = UIColor.clearColor()
            masterCell = cell
        default:
            masterCell = nil
        }
        
        masterCell?.backgroundColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 0.3)
        
        return masterCell!
    }
    
    override func tableView(tableView: UITableView, willSelectRowAtIndexPath indexPath: NSIndexPath) -> NSIndexPath? {
        self.tableView.deselectRowAtIndexPath(indexPath, animated: true)
        
        switch indexPath.section
        {
        case TableViewSection.Outputs.rawValue:
            self.selectedTableViewRow = indexPath.row
        default: break
            // Nothing
        }
        
        if let _ = self.device.variables["e131FVersion"]
        {
            return indexPath
        }
        else
        {
            return nil
        }
    }
}
