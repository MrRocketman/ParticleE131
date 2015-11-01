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
let tableSectionNumberOfRows = [3, 1, 16]

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
    case IPAddress
    case IPAddressPicker
}

enum TableViewInfoRows: Int {
    case FirmwareVersion = 0
}

class E131ConfigurationTableViewController: UITableViewController, UITextFieldDelegate, UIPickerViewDelegate, UIPickerViewDataSource {
    
    var device : SparkDevice!
    var itemRefreshCount = 0
    var textFieldTextColor: UIColor?
    var ipAddressPickerIsVisible = false
    var localIPAddress: String?
    var localIPComponents: [String] = []
    var ipAddressPickerCellHeight: CGFloat?
    var ipPicker: UIPickerView?
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
        
        let cell2:IPAddressPickerkTableViewCell = self.tableView.dequeueReusableCellWithIdentifier("ipAddressPickerCell") as! IPAddressPickerkTableViewCell
        self.ipAddressPickerCellHeight = cell2.frame.size.height
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
        if section == TableViewSection.Configure.rawValue && self.ipAddressPickerIsVisible
        {
            return (tableSectionNumberOfRows[section] + 1)
        }
        
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
        if indexPath.row == TableViewConfigureRows.IPAddressPicker.rawValue && self.ipAddressPickerIsVisible == true
        {
            return self.ipAddressPickerCellHeight!
        }
        else
        {
            return self.tableView.rowHeight
        }
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
            case TableViewConfigureRows.IPAddress.rawValue : // Local IP Address Row
                let cell:UITableViewCell = self.tableView.dequeueReusableCellWithIdentifier("rightDetailCell")! as UITableViewCell
                cell.textLabel?.text = "Local IP Address";
                cell.detailTextLabel?.textColor = self.textFieldTextColor
                if self.ipAddressPickerIsVisible == true
                {
                    cell.detailTextLabel?.text = "Done"
                }
                else
                {
                    device.getVariable("localIP", completion: { (theResult:AnyObject!, error:NSError?) -> Void in
                        if let localIP: String = theResult as? String
                        {
                            self.localIPAddress = localIP
                            self.localIPComponents = self.localIPAddress!.componentsSeparatedByString(".")
                            cell.detailTextLabel?.text = localIP
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
                }
                masterCell = cell
            case TableViewConfigureRows.IPAddressPicker.rawValue : // Local IP Address Picker Row
                let cell:IPAddressPickerkTableViewCell = self.tableView.dequeueReusableCellWithIdentifier("ipAddressPickerCell") as! IPAddressPickerkTableViewCell
                cell.pickerView.delegate = self
                cell.pickerView.dataSource = self
                self.ipPicker = cell.pickerView
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
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        self.tableView.deselectRowAtIndexPath(indexPath, animated: true)
        
        switch indexPath.section
        {
        case TableViewSection.Configure.rawValue :
            switch indexPath.row
            {
            case TableViewConfigureRows.IPAddress.rawValue :
                if(self.ipAddressPickerIsVisible == false)
                {
                    self.ipAddressPickerIsVisible = true
                    self.tableView.insertRowsAtIndexPaths([NSIndexPath.init(forRow: TableViewConfigureRows.IPAddressPicker.rawValue, inSection: TableViewSection.Configure.rawValue)], withRowAnimation: UITableViewRowAnimation.Automatic)
                    self.tableView.reloadRowsAtIndexPaths([NSIndexPath.init(forRow: TableViewConfigureRows.IPAddress.rawValue, inSection: TableViewSection.Configure.rawValue)], withRowAnimation: UITableViewRowAnimation.Automatic)
                }
                else
                {
                    self.ipAddressPickerIsVisible = false
                    self.tableView.deleteRowsAtIndexPaths([NSIndexPath.init(forRow: TableViewConfigureRows.IPAddressPicker.rawValue, inSection: TableViewSection.Configure.rawValue)], withRowAnimation: UITableViewRowAnimation.Automatic)
                    self.tableView.reloadRowsAtIndexPaths([NSIndexPath.init(forRow: TableViewConfigureRows.IPAddress.rawValue, inSection: TableViewSection.Configure.rawValue)], withRowAnimation: UITableViewRowAnimation.Automatic)
                }
            default: break
            }
        default: break
            // Nothing
        }
    }
    
    // MARK: - IPAddressPicker
    
    func pickerView(pickerView: UIPickerView, attributedTitleForRow row: Int, forComponent component: Int) -> NSAttributedString? {
        
        
        let title = String(localIPComponents[0]) + "." + String(localIPComponents[1]) + "." + String(localIPComponents[2]) + "." + String((row + 2))
        return NSAttributedString(string: title, attributes: [NSForegroundColorAttributeName:UIColor.whiteColor()])
    }
    
    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return 253
    }
    
    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
        return 1
    }
}
