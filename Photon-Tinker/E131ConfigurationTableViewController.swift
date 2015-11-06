//
//  E131ConfigurationTableViewController.swift
//  Particle
//
//  Created by James Adams on 10/26/15.
//  Copyright © 2015 spark. All rights reserved.
//

import Foundation

enum UpdateParameterCommands: Int {
    case SystemReset = 0
    case TestOutput
    case Save
    case UniverseSize
    case ChannelMapForOutput
    case PixelTypeForOutput
    case NumberOfPixelsForOutput
    case StartUniverseForOutput
    case StartChannelForOutput
    case EndUniverseForOutput
    case EndChannelForOutput
}

let numbersOfTableSections = 5
let tableSectionNames = ["", "Configure", "Info", "Outputs", ""]
let tableSectionNumberOfRows = [1, 2, 3, 16, 1]

let numberOfItemsToRefresh = 4

enum TextFieldType: Int {
    case Name = 0
    case UniverseSize
    case IPAddress
}

enum TableViewSection: Int {
    case Save = 0
    case Configure
    case Info
    case Outputs
    case Reboot
}

enum TableViewConfigureRows: Int {
    case Name = 0
    case UniverseSize
    case UniverseSizePicker
}

enum TableViewInfoRows: Int {
    case FirmwareVersion = 0
    case SystemVersion
    case IPAddress
}

class E131ConfigurationTableViewController: UITableViewController, UITextFieldDelegate, UIPickerViewDelegate, UIPickerViewDataSource {
    
    var device : SparkDevice!
    var itemRefreshCount = 0
    var textFieldTextColor: UIColor?
    var localIPAddress: String?
    var universeSize: Int?
    var e131FirmwareVersion: String?
    var systemVersion: String?
    
    var universeSizePickerCellHeight: CGFloat?
    var universeSizePicker: UIPickerView?
    var universeSizePickerIsVisible = false
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
        self.universeSizePickerCellHeight = cell2.frame.size.height
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
        self.itemRefreshCount = 0
        
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
                    self.device.getVariable("universeSize", completion: { (theResult:AnyObject!, error:NSError?) -> Void in
                        if let universeSize: Int = theResult as? Int
                        {
                            self.universeSize = universeSize
                        }
                        
                        // Finish the refresh after all variables have loaded
                        if(++self.itemRefreshCount >= numberOfItemsToRefresh)
                        {
                            self.refreshControl?.endRefreshing()
                            dispatch_async(dispatch_get_main_queue()) {
                                self.tableView.reloadData()
                            }
                        }
                    })
                    
                    self.device.getVariable("e131FVersion", completion: { (theResult:AnyObject!, error:NSError?) -> Void in
                        if let firmwareVersion: String = theResult as? String
                        {
                            self.e131FirmwareVersion = firmwareVersion
                        }
                        
                        // Finish the refresh after all variables have loaded
                        if(++self.itemRefreshCount >= numberOfItemsToRefresh)
                        {
                            self.refreshControl?.endRefreshing()
                            dispatch_async(dispatch_get_main_queue()) {
                                self.tableView.reloadData()
                            }
                        }
                    })
                    
                    self.device.getVariable("sysVersion", completion: { (theResult:AnyObject!, error:NSError?) -> Void in
                        if let firmwareVersion: String = theResult as? String
                        {
                            self.systemVersion = firmwareVersion
                        }
                        
                        // Finish the refresh after all variables have loaded
                        if(++self.itemRefreshCount >= numberOfItemsToRefresh)
                        {
                            self.refreshControl?.endRefreshing()
                            dispatch_async(dispatch_get_main_queue()) {
                                self.tableView.reloadData()
                            }
                        }
                    })
                    
                    self.device.getVariable("localIP", completion: { (theResult:AnyObject!, error:NSError?) -> Void in
                        if let localIP: String = theResult as? String
                        {
                            self.localIPAddress = localIP
                        }
                        
                        // Finish the refresh after all variables have loaded
                        if(++self.itemRefreshCount >= numberOfItemsToRefresh)
                        {
                            self.refreshControl?.endRefreshing()
                            dispatch_async(dispatch_get_main_queue()) {
                                self.tableView.reloadData()
                            }
                        }
                    })
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
            default: break
            }
        }
    }
    
    //MARK: - TableView Methods
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        self.itemRefreshCount = 0
        return numbersOfTableSections;
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == TableViewSection.Configure.rawValue && self.universeSizePickerIsVisible
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
        if indexPath.section == TableViewSection.Configure.rawValue && indexPath.row == TableViewConfigureRows.UniverseSizePicker.rawValue && self.universeSizePickerIsVisible == true
        {
            return self.universeSizePickerCellHeight!
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
        case TableViewSection.Save.rawValue:
            let cell = self.tableView.dequeueReusableCellWithIdentifier("basicCell")! as UITableViewCell
            cell.textLabel?.text = "Save"
            cell.textLabel?.textAlignment = NSTextAlignment.Center;
            cell.textLabel?.textColor = self.textFieldTextColor;
            cell.textLabel?.backgroundColor = UIColor.clearColor();
            masterCell = cell
            
        case TableViewSection.Reboot.rawValue:
            let cell = self.tableView.dequeueReusableCellWithIdentifier("basicCell")! as UITableViewCell
            cell.textLabel?.text = "Reboot"
            cell.textLabel?.textAlignment = NSTextAlignment.Center;
            cell.textLabel?.textColor = self.textFieldTextColor;
            cell.textLabel?.backgroundColor = UIColor.clearColor();
            masterCell = cell
            
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
                let cell:UITableViewCell = self.tableView.dequeueReusableCellWithIdentifier("rightDetailCell")! as UITableViewCell
                cell.textLabel?.text = "Universe Size";
                cell.detailTextLabel?.textColor = self.textFieldTextColor
                if self.universeSizePickerIsVisible == true
                {
                    cell.detailTextLabel?.text = "Done"
                }
                else
                {
                    if let universeSize = self.universeSize
                    {
                        cell.detailTextLabel?.text = String(universeSize)
                    }
                    else
                    {
                        cell.detailTextLabel?.text = "Undefined"
                    }
                }
                masterCell = cell
                
            case TableViewConfigureRows.UniverseSizePicker.rawValue : // Local IP Address Picker Row
                let cell:IPAddressPickerkTableViewCell = self.tableView.dequeueReusableCellWithIdentifier("ipAddressPickerCell") as! IPAddressPickerkTableViewCell
                cell.pickerView.delegate = self
                cell.pickerView.dataSource = self
                self.universeSizePicker = cell.pickerView
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
                if let firmwareVersion = self.e131FirmwareVersion
                {
                    cell.detailTextLabel!.text = firmwareVersion
                }
                else
                {
                    cell.detailTextLabel!.text = "Undefined"
                }
                masterCell = cell
            case TableViewInfoRows.SystemVersion.rawValue : // Firmware Version Row
                let cell:UITableViewCell = self.tableView.dequeueReusableCellWithIdentifier("rightDetailCell")! as UITableViewCell
                cell.textLabel?.text = "System Version";
                cell.detailTextLabel?.textColor = UIColor.whiteColor()
                if let firmwareVersion = self.systemVersion
                {
                    cell.detailTextLabel!.text = firmwareVersion
                }
                else
                {
                    cell.detailTextLabel!.text = "Undefined"
                }
                masterCell = cell
            case TableViewInfoRows.IPAddress.rawValue : // Local IP Address Row
                let cell:UITableViewCell = self.tableView.dequeueReusableCellWithIdentifier("rightDetailCell")! as UITableViewCell
                cell.textLabel?.text = "Local IP Address";
                cell.detailTextLabel?.textColor = UIColor.whiteColor()
                if let localIP = self.localIPAddress
                {
                    cell.detailTextLabel!.text = localIP
                }
                else
                {
                    cell.detailTextLabel?.text = "Undefined"
                }
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
        case TableViewSection.Save.rawValue:
            self.device.callFunction("updateParams", withArguments: [UpdateParameterCommands.UniverseSize.rawValue, self.universeSize!], completion: { (theResult:NSNumber!, error:NSError?) -> Void in
                if theResult != nil && theResult.integerValue == 1
                {
                    TSMessage.showNotificationWithTitle("Success", subtitle: "Updated universeSize to " + String(self.universeSize!), type:TSMessageNotificationType.Success)
                }
                else
                {
                    TSMessage.showNotificationWithTitle("Error", subtitle: "Error updating universeSize, please check internet connection.", type: .Error)
                }
            })
            
        case TableViewSection.Reboot.rawValue:
            self.device.callFunction("updateParams", withArguments: [UpdateParameterCommands.SystemReset.rawValue, self.universeSize!], completion: { (theResult:NSNumber!, error:NSError?) -> Void in
                
            })
            TSMessage.showNotificationWithTitle("Rebooting", subtitle: "Please wait up to 30 seconds while the system reboots. Then pull down to refresh.", type:TSMessageNotificationType.Warning)
            
        case TableViewSection.Configure.rawValue :
            switch indexPath.row
            {
            case TableViewConfigureRows.UniverseSize.rawValue :
                if(self.universeSizePickerIsVisible == false)
                {
                    self.universeSizePickerIsVisible = true
                    self.tableView.beginUpdates()
                    self.tableView.insertRowsAtIndexPaths([NSIndexPath.init(forRow: TableViewConfigureRows.UniverseSizePicker.rawValue, inSection: TableViewSection.Configure.rawValue)], withRowAnimation: UITableViewRowAnimation.Fade)
                    self.tableView.reloadRowsAtIndexPaths([NSIndexPath.init(forRow: TableViewConfigureRows.UniverseSize.rawValue, inSection: TableViewSection.Configure.rawValue)], withRowAnimation: UITableViewRowAnimation.Automatic)
                    self.tableView.endUpdates()
                    
                    self.universeSizePicker?.selectRow(self.universeSize! - 1, inComponent: 0, animated: false);
                }
                else
                {
                    self.universeSizePickerIsVisible = false
                    self.universeSize = (self.universeSizePicker?.selectedRowInComponent(0))! + 1;
                    self.tableView.beginUpdates()
                    self.tableView.deleteRowsAtIndexPaths([NSIndexPath.init(forRow: TableViewConfigureRows.UniverseSizePicker.rawValue, inSection: TableViewSection.Configure.rawValue)], withRowAnimation: UITableViewRowAnimation.Fade)
                    self.tableView.reloadRowsAtIndexPaths([NSIndexPath.init(forRow: TableViewConfigureRows.UniverseSize.rawValue, inSection: TableViewSection.Configure.rawValue)], withRowAnimation: UITableViewRowAnimation.Automatic)
                    self.tableView.endUpdates()
                }
            default: break
            }
        default: break
            // Nothing
        }
    }
    
    // MARK: - IPAddressPicker
    
    func pickerView(pickerView: UIPickerView, attributedTitleForRow row: Int, forComponent component: Int) -> NSAttributedString? {
        
        let title = String(row + 1)
        return NSAttributedString(string: title, attributes: [NSForegroundColorAttributeName:UIColor.whiteColor()])
    }
    
    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return 512
    }
    
    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
        return 1
    }
}
