//
//  OutputConfigurationTableViewController.swift
//  Particle
//
//  Created by James Adams on 10/29/15.
//  Copyright © 2015 spark. All rights reserved.
//

import Foundation

let pixelTypeDescriptions = ["WS2812 (Neopixel Strips)", "WS2812B (Newer Neopixel Strips)", "WS2812B2 (Newest Neopixel Strips)", "WS2811 (Bullet/Flat Style)", "TM1803 (Radio Shack Tri-Color Strip)", "TM1829"];
var pixelTypeValues = [0, 1, 2, 3, 4, 5];

enum TextFieldTypeOutput: Int {
    case NumberOfPixels = 0
    case StartUniverse
    case EndUniverse
}

enum TableViewSectionNormal: Int {
    case Save = 0
    case Name
    case Configure
    case PixelType
    case NumberOfPixels
    case StartUniverse
    case StartChannel
    case EndUniverse
    case EndChannel
}

enum TableViewSectionAbsolute: Int {
    case Save = 0
    case Name
    case Configure
    case PixelType
    case NumberOfPixels
    case StartChannel
    case EndChannel
}

enum TableViewRowType: Int {
    case Save = 0
    case Name
    case Configure
    case PixelType
    case PixelTypePicker
    case NumberOfPixels
    case StartUniverse
    case StartChannel
    case StartChannelPicker
    case StartChannelAbsolute
    case EndUniverse
    case EndChannel
    case EndChannelPicker
    case EndChannelAbsolute
}

enum OutputSettings: Int {
    case PixelType = 0
    case NumberOfPixels
    case StartUniverse
    case StartChannel
    case EndUniverse
    case EndChannel
}

enum PickerTags: Int {
    case PixelTypePicker = 1
    case StartChannelPicker = 2
    case EndChannelPicker = 3
}

class OutputConfigurationTableViewController: UITableViewController, UITextFieldDelegate, UIPickerViewDelegate, UIPickerViewDataSource {
    
    // These need to be set by the configuration table
    var device : SparkDevice!
    var output: Int!
    var universeSize: Int!
    
    // General variables
    var numberOfTableSectionsNormal = 9
    var numberOfTableSectionsAbsolute = 7
    var tableSectionNamesNormal = ["", "Name", "Configure", "Pixel Type", "Number Of Pixels", "Start Universe", "Start Channel", "End Universe", "End Channel"]
    var tableSectionNamesAbsolute = ["", "Name", "Configure", "Pixel Type", "Number Of Pixels", "Start Channel", "End Channel"]
    var numberOfItemsToRefresh = 1
    var itemRefreshCount = 0
    var isAbsoluteChannelNumbering = true
    var pickerCellHeight: CGFloat!
    var pixelTypePickerIsVisible = false
    var pixelTypePicker: UIPickerView?
    var startChannelPickerIsVisible = false
    var startChannelPicker: UIPickerView?
    var endChannelPickerIsVisible = false
    var endChannelPicker: UIPickerView?
    
    // Pin mapping variables
    var outputSettings: [Int?] = [nil, nil, nil, nil, nil, nil, nil, nil]
    var outputName: String?
    
    //MARK: - Initialization
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.backgroundColor = UIColor(patternImage: self.imageResize(UIImage(named: "imgTrianglifyBackgroundBlue")!, newRect: UIScreen.mainScreen().bounds))
        
        self.refreshControl?.addTarget(self, action: "loadDevices", forControlEvents: UIControlEvents.ValueChanged)
        self.refreshControl?.tintColor = UIColor.blackColor()
        
        let bar:UINavigationBar! =  self.navigationController?.navigationBar
        bar.setBackgroundImage(UIImage(named: "imgTrianglifyBackgroundBlue"), forBarMetrics: UIBarMetrics.Default)
        
        self.title = "Output " + String(output + 1)
        
        let cell:IPAddressPickerkTableViewCell = self.tableView.dequeueReusableCellWithIdentifier("ipAddressPickerCell") as! IPAddressPickerkTableViewCell
        self.pickerCellHeight = cell.frame.size.height
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
            
            self.itemRefreshCount = 0
            
            self.device.getVariable("outputConfig", completion: { (theResult:AnyObject!, error:NSError?) -> Void in
                if let outputSetting = theResult as? String
                {
                    let outputSettings = outputSetting.componentsSeparatedByString(";")
                    if outputSettings.count > self.output
                    {
                        // Only find the settings for this output
                        let stringPinMap = (outputSettings[self.output]).componentsSeparatedByString(",")
                        for var i = 0; i < stringPinMap.count; ++i
                        {
                            if stringPinMap[i].characters.count > 0
                            {
                                if let intValue = Int(stringPinMap[i])
                                {
                                    self.outputSettings[i] = intValue
                                }
                                // String values always come after all of the int values
                                else
                                {
                                    self.outputName = stringPinMap[i];
                                }
                            }
                        }
                    }
                    else
                    {
                        TSMessage.showNotificationWithTitle("Error", subtitle: "Error loading channel settings. Please check internet connection.", type: .Error)
                    }
                }
                else
                {
                    TSMessage.showNotificationWithTitle("Error", subtitle: "Error loading channel settings. Please check internet connection.", type: .Error)
                }
                
                // Finish the refresh after all variables have loaded
                if(++self.itemRefreshCount >= self.numberOfItemsToRefresh)
                {
                    self.refreshControl?.endRefreshing()
                    dispatch_async(dispatch_get_main_queue()) {
                        self.tableView.reloadData()
                    }
                }
            })
        }
    }
    
    // MARK: - TextField
    
    func textFieldDidEndEditing(textField: UITextField) {
        // change name, ip, universe size
        if let tag = TableViewRowType(rawValue: textField.tag)
        {
            switch tag.rawValue
            {
            case TableViewRowType.Name.rawValue:
                // Auto update the end channel based on the number of pixels
                if let text = textField.text
                {
                    if text.characters.count > 0
                    {
                        if text.characters.count > 32
                        {
                            
                            self.outputName = text.substringToIndex(text.startIndex.advancedBy(32))
                        }
                        else
                        {
                            self.outputName = text
                        }
                        
                        // Update the endChannel
                        self.device.callFunction("updateParams", withArguments: [UpdateParameterCommands.NameForOutput.rawValue, self.output, self.outputName!], completion: { (theResult:NSNumber!, error:NSError?) -> Void in
                            if theResult != nil && theResult.integerValue == 1
                            {
                                TSMessage.showNotificationWithTitle("Success", subtitle: "Updated name to " + self.outputName!, type:TSMessageNotificationType.Success)
                            }
                            else
                            {
                                TSMessage.showNotificationWithTitle("Error", subtitle: "Error updating name, please check internet connection.", type: .Error)
                            }
                        })
                    }
                }
            case TableViewRowType.NumberOfPixels.rawValue:
                // Auto update the end channel based on the number of pixels
                if let text = textField.text
                {
                    if text.characters.count > 0
                    {
                        if self.outputSettings[OutputSettings.NumberOfPixels.rawValue] != Int(text)!
                        {
                            self.outputSettings[OutputSettings.NumberOfPixels.rawValue] = Int(text)!
                            if let startChannel = self.outputSettings[OutputSettings.StartChannel.rawValue]
                            {
                                if let startUniverse = self.outputSettings[OutputSettings.StartUniverse.rawValue]
                                {
                                    // Bounds check
                                    var numberOfPixels: Int!
                                    if Int(text)! >= 0
                                    {
                                        numberOfPixels = Int(text)!
                                    }
                                    else
                                    {
                                        numberOfPixels = 0
                                    }
                                    
                                    // Update the end channel info
                                    let theoreticalEndChannel = startUniverse * self.universeSize + startChannel + numberOfPixels * 3 - (numberOfPixels > 0 ? 1 : 0) // -1 since channels actually start at 0, but are visually displayed as starting at 1
                                    self.outputSettings[OutputSettings.EndUniverse.rawValue] = Int(theoreticalEndChannel / self.universeSize)
                                    self.outputSettings[OutputSettings.EndChannel.rawValue] = Int(theoreticalEndChannel % self.universeSize)
                                    
                                    // Update the parameters
                                    self.updateParticleChannelMap()
                                    
                                    if self.isAbsoluteChannelNumbering == true
                                    {
                                        self.tableView.reloadRowsAtIndexPaths([NSIndexPath.init(forRow: 0, inSection: TableViewSectionAbsolute.EndChannel.rawValue)], withRowAnimation: UITableViewRowAnimation.Automatic)
                                    }
                                    else
                                    {
                                        self.tableView.reloadRowsAtIndexPaths([NSIndexPath.init(forRow: 0, inSection: TableViewSectionNormal.EndUniverse.rawValue), NSIndexPath.init(forRow: 0, inSection: TableViewSectionNormal.EndChannel.rawValue)], withRowAnimation: UITableViewRowAnimation.Automatic)
                                    }
                                }
                            }
                        }
                    }
                }
            case TableViewRowType.StartChannelAbsolute.rawValue:
                // Auto update the end channel based on the number of pixels
                if let text = textField.text
                {
                    if text.characters.count > 0
                    {
                        // Bounds check
                        var startChannel: Int!
                        if Int(text)! > 0
                        {
                            startChannel = Int(text)!
                        }
                        else
                        {
                            startChannel = 1
                        }
                        
                        if self.outputSettings[OutputSettings.StartChannel.rawValue] != startChannel % self.universeSize - 1
                        {
                            // Update Start info
                            self.outputSettings[OutputSettings.StartUniverse.rawValue] = startChannel / self.universeSize + 1 // Add 1 since universes start at 1 not 0
                            self.outputSettings[OutputSettings.StartChannel.rawValue] = startChannel % self.universeSize - 1 // -1 since channels actually start at 0, but are visually displayed as starting at 1
                            
                            // Update end info if we have pixels
                            if let numberOfPixels = self.outputSettings[OutputSettings.NumberOfPixels.rawValue]
                            {
                                let theoreticalEndChannel = self.outputSettings[OutputSettings.StartUniverse.rawValue]! * self.universeSize + self.outputSettings[OutputSettings.StartChannel.rawValue]! + numberOfPixels * 3 - (numberOfPixels > 0 ? 1 : 0) // -1 since channels actually start at 0, but are visually displayed as starting at 1
                                self.outputSettings[OutputSettings.EndUniverse.rawValue] = theoreticalEndChannel / self.universeSize
                                self.outputSettings[OutputSettings.EndChannel.rawValue] = theoreticalEndChannel % self.universeSize
                                
                                self.tableView.reloadRowsAtIndexPaths([NSIndexPath.init(forRow: 0, inSection: TableViewSectionAbsolute.EndChannel.rawValue)], withRowAnimation: UITableViewRowAnimation.Automatic)
                            }
                            
                            // Update the parameters
                            self.updateParticleChannelMap()
                        }
                    }
                }
            case TableViewRowType.StartUniverse.rawValue:
                // Auto update the end channel based on the number of pixels
                if let text = textField.text
                {
                    if text.characters.count > 0
                    {
                        // Bounds check
                        var startUniverse: Int!
                        if Int(text)! > 0
                        {
                            startUniverse = Int(text)!
                        }
                        else
                        {
                            startUniverse = 1
                        }
                        
                        if self.outputSettings[OutputSettings.StartUniverse.rawValue] != startUniverse
                        {
                            // Update the start data
                            self.outputSettings[OutputSettings.StartUniverse.rawValue] = startUniverse
                            
                            // Update the end info if we have pixels
                            if let numberOfPixels = self.outputSettings[OutputSettings.NumberOfPixels.rawValue]
                            {
                                let theoreticalEndChannel = self.outputSettings[OutputSettings.StartUniverse.rawValue]! * self.universeSize + self.outputSettings[OutputSettings.StartChannel.rawValue]! + numberOfPixels * 3 - (numberOfPixels > 0 ? 1 : 0) // -1 since channels actually start at 0, but are visually displayed as starting at 1
                                self.outputSettings[OutputSettings.EndUniverse.rawValue] = theoreticalEndChannel / self.universeSize
                                
                                self.tableView.reloadRowsAtIndexPaths([NSIndexPath.init(forRow: 0, inSection: TableViewSectionNormal.EndUniverse.rawValue), NSIndexPath.init(forRow: 0, inSection: TableViewSectionNormal.EndChannel.rawValue)], withRowAnimation: UITableViewRowAnimation.Automatic)
                            }
                            
                            // Update the parameters
                            self.updateParticleChannelMap()
                        }
                    }
                }
            case TableViewRowType.EndChannelAbsolute.rawValue:
                // Auto update the end channel based on the number of pixels
                if let text = textField.text
                {
                    if text.characters.count > 0
                    {
                        // Bounds check
                        var endChannel: Int!
                        if Int(text)! > 0
                        {
                            endChannel = Int(text)!
                        }
                        else
                        {
                            endChannel = 1
                        }
                        
                        if self.outputSettings[OutputSettings.EndChannel.rawValue] != endChannel % self.universeSize - 1
                        {
                            // Update Start info
                            self.outputSettings[OutputSettings.EndUniverse.rawValue] = endChannel / self.universeSize + 1 // Add 1 since universes start at 1 not 0
                            self.outputSettings[OutputSettings.EndChannel.rawValue] = endChannel % self.universeSize - 1 // -1 since channels actually start at 0, but are visually displayed as starting at 1
                            
                            // Update the parameters
                            self.updateParticleChannelMap()
                        }
                    }
                }
            case TableViewRowType.EndUniverse.rawValue:
                // Auto update the end channel based on the number of pixels
                if let text = textField.text
                {
                    if text.characters.count > 0
                    {
                        // Bounds check
                        var endUniverse: Int!
                        if Int(text)! > 0
                        {
                            endUniverse = Int(text)!
                        }
                        else
                        {
                            endUniverse = 1
                        }
                        
                        if self.outputSettings[OutputSettings.EndUniverse.rawValue] != endUniverse
                        {
                            // Update the start data
                            self.outputSettings[OutputSettings.EndUniverse.rawValue] = endUniverse
                            
                            // Update the parameters
                            self.updateParticleParameterWith(.EndUniverseForOutput, outputSetting: .EndUniverse, string: "endUniverse")
                        }
                    }
                }
            default: break
            }
        }
    }
    
    //MARK: - TableView Methods
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        if self.isAbsoluteChannelNumbering == true
        {
            return numberOfTableSectionsAbsolute
        }
        else
        {
            return numberOfTableSectionsNormal
        }
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if self.isAbsoluteChannelNumbering == true
        {
            if section == TableViewSectionAbsolute.PixelType.rawValue && self.pixelTypePickerIsVisible
            {
                return 2
            }
            else
            {
                return 1
            }
        }
        else
        {
            if section == TableViewSectionNormal.PixelType.rawValue && self.pixelTypePickerIsVisible
            {
                return 2
            }
            else if section == TableViewSectionNormal.StartChannel.rawValue && self.startChannelPickerIsVisible
            {
                return 2
            }
            else if section == TableViewSectionNormal.EndChannel.rawValue && self.endChannelPickerIsVisible
            {
                return 2
            }
            else
            {
                return 1
            }
        }
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if self.isAbsoluteChannelNumbering == true
        {
            return tableSectionNamesAbsolute[section]
        }
        else
        {
            return tableSectionNamesNormal[section]
        }
    }
    
    override func tableView(tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        
        let header: UITableViewHeaderFooterView = view as! UITableViewHeaderFooterView
        header.textLabel?.textColor = UIColor.blackColor()
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if indexPath.row == 1
        {
            return self.pickerCellHeight
        }
        else
        {
            return self.tableView.rowHeight
        }
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        var masterCell : UITableViewCell?
        
        let rowType = self.tableViewRowTypeForIndexPath(indexPath)
        
        switch rowType.rawValue
        {
        case TableViewRowType.Save.rawValue:
            let cell = self.tableView.dequeueReusableCellWithIdentifier("basicCell")! as UITableViewCell
            cell.textLabel?.text = "Save"
            cell.textLabel?.textAlignment = NSTextAlignment.Center;
            cell.textLabel?.backgroundColor = UIColor.clearColor();
            masterCell = cell
        case TableViewRowType.Name.rawValue:
            let cell:TextFieldTableViewCell = self.tableView.dequeueReusableCellWithIdentifier("textFieldCell") as! TextFieldTableViewCell
            if let text = self.outputName
            {
                cell.textField.text = text
            }
            cell.textField.delegate = self
            cell.textField.keyboardType = UIKeyboardType.Default
            cell.textField.tag = rowType.rawValue
            cell.textField.enabled = (self.itemRefreshCount == self.numberOfItemsToRefresh ? true : false)
            masterCell = cell
            
        case TableViewRowType.Configure.rawValue:
            let cell:LabelAndSwitchTableViewCell = self.tableView.dequeueReusableCellWithIdentifier("labelAndSwitchCell") as! LabelAndSwitchTableViewCell
            masterCell = cell
        case TableViewRowType.PixelType.rawValue:
            let cell:UITableViewCell = self.tableView.dequeueReusableCellWithIdentifier("basicCell")! as UITableViewCell
            if self.pixelTypePickerIsVisible == true
            {
                cell.textLabel!.text = "Done"
            }
            else
            {
                if let pixelType = self.outputSettings[OutputSettings.PixelType.rawValue]
                {
                    cell.textLabel!.text = pixelTypeDescriptions[pixelType]
                }
            }
            cell.textLabel!.backgroundColor = UIColor.clearColor()
            masterCell = cell
            
        case TableViewRowType.PixelTypePicker.rawValue:
            let cell:IPAddressPickerkTableViewCell = self.tableView.dequeueReusableCellWithIdentifier("ipAddressPickerCell") as! IPAddressPickerkTableViewCell
            cell.pickerView.delegate = self
            cell.pickerView.dataSource = self
            cell.pickerView.tag = PickerTags.PixelTypePicker.rawValue
            self.pixelTypePicker = cell.pickerView
            masterCell = cell
            
        case TableViewRowType.NumberOfPixels.rawValue:
            if let numberOfPixels = self.outputSettings[OutputSettings.NumberOfPixels.rawValue]
            {
                masterCell = self.prepareTextFieldCellWithText(String(numberOfPixels), tag: rowType.rawValue)
            }
            
        case TableViewRowType.StartUniverse.rawValue:
            if let startUniverse = self.outputSettings[OutputSettings.StartUniverse.rawValue]
            {
                masterCell = self.prepareTextFieldCellWithText(String(startUniverse), tag: rowType.rawValue)
            }
            
        case TableViewRowType.StartChannel.rawValue:
            let cell:UITableViewCell = self.tableView.dequeueReusableCellWithIdentifier("basicCell")! as UITableViewCell
            cell.textLabel?.textAlignment = NSTextAlignment.Left
            if self.startChannelPickerIsVisible == true
            {
                cell.textLabel!.text = "Done"
            }
            else
            {
                if let startChannel = self.outputSettings[OutputSettings.StartChannel.rawValue]
                {
                    cell.textLabel!.text = String(startChannel + 1)
                }
                else
                {
                    cell.textLabel!.text = "Undefined Start Channel"
                }
            }
            cell.textLabel!.backgroundColor = UIColor.clearColor()
            masterCell = cell
        case TableViewRowType.StartChannelPicker.rawValue:
            let cell:IPAddressPickerkTableViewCell = self.tableView.dequeueReusableCellWithIdentifier("ipAddressPickerCell") as! IPAddressPickerkTableViewCell
            cell.pickerView.delegate = self
            cell.pickerView.dataSource = self
            cell.pickerView.tag = PickerTags.StartChannelPicker.rawValue
            self.startChannelPicker = cell.pickerView
            masterCell = cell
            
        case TableViewRowType.StartChannelAbsolute.rawValue:
            if let startUniverse = self.outputSettings[OutputSettings.StartUniverse.rawValue]
            {
                if let startChannel = self.outputSettings[OutputSettings.StartChannel.rawValue]
                {
                    masterCell = self.prepareTextFieldCellWithText(String((startUniverse - 1) * self.universeSize + startChannel + 1), tag: rowType.rawValue) // -1 since universes actually start at 1 not 0 // +1 since channels visually start at 1. Index wise though they start at 0
                }
            }
            
        case TableViewRowType.EndUniverse.rawValue:
            if let endUniverse = self.outputSettings[OutputSettings.EndUniverse.rawValue]
            {
                masterCell = self.prepareTextFieldCellWithText(String(endUniverse), tag: rowType.rawValue)
            }
            
        case TableViewRowType.EndChannel.rawValue:
            let cell:UITableViewCell = self.tableView.dequeueReusableCellWithIdentifier("basicCell")! as UITableViewCell
            cell.textLabel?.textAlignment = NSTextAlignment.Left;
            if self.endChannelPickerIsVisible == true
            {
                cell.textLabel!.text = "Done"
            }
            else
            {
                if let endChannel = self.outputSettings[OutputSettings.EndChannel.rawValue]
                {
                    cell.textLabel!.text = String(endChannel + 1)
                }
                else
                {
                    cell.textLabel!.text = "Undefined End Channel"
                }
            }
            cell.textLabel!.backgroundColor = UIColor.clearColor()
            masterCell = cell
        case TableViewRowType.EndChannelPicker.rawValue:
            let cell:IPAddressPickerkTableViewCell = self.tableView.dequeueReusableCellWithIdentifier("ipAddressPickerCell") as! IPAddressPickerkTableViewCell
            cell.pickerView.delegate = self
            cell.pickerView.dataSource = self
            cell.pickerView.tag = PickerTags.EndChannelPicker.rawValue
            self.endChannelPicker = cell.pickerView
            masterCell = cell
            
        case TableViewRowType.EndChannelAbsolute.rawValue:
            if let endUniverse = self.outputSettings[OutputSettings.EndUniverse.rawValue]
            {
                if let endChannel = self.outputSettings[OutputSettings.EndChannel.rawValue]
                {
                    masterCell = self.prepareTextFieldCellWithText(String((endUniverse - 1) * self.universeSize + endChannel + 1), tag: rowType.rawValue) // -1 since universes actually start at 1 not 0 // +1 since channels visually start at 1. Index wise though they start at 0
                }
            }
            
        default: break
        }
        
        if masterCell == nil
        {
            masterCell = self.prepareTextFieldCellWithText("Loading...", tag: rowType.rawValue)
        }
        
        masterCell?.backgroundColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 0.3)
        
        return masterCell!
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        //self.performSegueWithIdentifier("outputs", sender: self)
        self.tableView.deselectRowAtIndexPath(indexPath, animated: true)
        
        let rowType = self.tableViewRowTypeForIndexPath(indexPath)
        
        switch rowType.rawValue
        {
        case TableViewRowType.Save.rawValue:
            self.device.callFunction("updateParams", withArguments: [UpdateParameterCommands.Save.rawValue], completion: { (theResult:NSNumber!, error:NSError?) -> Void in
                if theResult != nil && theResult.integerValue == 1
                {
                    TSMessage.showNotificationWithTitle("Success", subtitle: "Saved changes to EEPROM", type:TSMessageNotificationType.Success)
                }
                else
                {
                    TSMessage.showNotificationWithTitle("Error", subtitle: "Error saving changes, please check internet connection.", type: .Error)
                }
            })
        case TableViewRowType.PixelType.rawValue:
            self.tableView.beginUpdates()
            if(self.pixelTypePickerIsVisible == false)
            {
                self.pixelTypePickerIsVisible = true
                self.tableView.insertRowsAtIndexPaths([NSIndexPath.init(forRow: 1, inSection: TableViewSectionNormal.PixelType.rawValue)], withRowAnimation: UITableViewRowAnimation.Fade)
            }
            else
            {
                self.pixelTypePickerIsVisible = false
                if self.outputSettings[OutputSettings.PixelType.rawValue] != (self.pixelTypePicker?.selectedRowInComponent(0))!
                {
                    self.outputSettings[OutputSettings.PixelType.rawValue] = (self.pixelTypePicker?.selectedRowInComponent(0))!;
                    
                    // Update the pixel type
                    self.updateParticleParameterWith(.PixelTypeForOutput, outputSetting: .PixelType, string: "pixelType")
                }
                self.tableView.deleteRowsAtIndexPaths([NSIndexPath.init(forRow: 1, inSection: TableViewSectionNormal.PixelType.rawValue)], withRowAnimation: UITableViewRowAnimation.Fade)
            }
            self.tableView.reloadRowsAtIndexPaths([NSIndexPath.init(forRow: 0, inSection: TableViewSectionNormal.PixelType.rawValue)], withRowAnimation: UITableViewRowAnimation.Automatic)
            self.tableView.endUpdates()
            
            // Select the current row in the picker
            if let pixelType = self.outputSettings[OutputSettings.PixelType.rawValue]
            {
                self.pixelTypePicker?.selectRow(pixelType, inComponent: 0, animated: false)
            }
            
        case TableViewRowType.StartChannel.rawValue:
            self.tableView.beginUpdates()
            if(self.startChannelPickerIsVisible == false)
            {
                self.startChannelPickerIsVisible = true
                self.tableView.insertRowsAtIndexPaths([NSIndexPath.init(forRow: 1, inSection: TableViewSectionNormal.StartChannel.rawValue)], withRowAnimation: UITableViewRowAnimation.Fade)
            }
            else
            {
                self.startChannelPickerIsVisible = false
                // Update Start info
                if self.outputSettings[OutputSettings.StartChannel.rawValue] != (self.startChannelPicker?.selectedRowInComponent(0))!
                {
                    self.outputSettings[OutputSettings.StartChannel.rawValue] = (self.startChannelPicker?.selectedRowInComponent(0))!;
                    
                    self.tableView.beginUpdates()
                    // Update end info if we have pixels
                    if let numberOfPixels = self.outputSettings[OutputSettings.NumberOfPixels.rawValue]
                    {
                        let theoreticalEndChannel = self.outputSettings[OutputSettings.StartUniverse.rawValue]! * self.universeSize + self.outputSettings[OutputSettings.StartChannel.rawValue]! + numberOfPixels * 3 - (numberOfPixels > 0 ? 1 : 0) // -1 since channels actually start at 0, but are visually displayed as starting at 1
                        self.outputSettings[OutputSettings.EndUniverse.rawValue] = theoreticalEndChannel / self.universeSize
                        self.outputSettings[OutputSettings.EndChannel.rawValue] = theoreticalEndChannel % self.universeSize
                        
                        self.tableView.reloadRowsAtIndexPaths([NSIndexPath.init(forRow: 0, inSection: TableViewSectionAbsolute.EndChannel.rawValue)], withRowAnimation: UITableViewRowAnimation.Automatic)
                    }
                    
                    // Update the parameters
                    self.updateParticleChannelMap()
                }
                
                self.tableView.deleteRowsAtIndexPaths([NSIndexPath.init(forRow: 1, inSection: TableViewSectionNormal.StartChannel.rawValue)], withRowAnimation: UITableViewRowAnimation.Fade)
                self.tableView.endUpdates()
            }
            self.tableView.reloadRowsAtIndexPaths([NSIndexPath.init(forRow: 0, inSection: TableViewSectionNormal.StartChannel.rawValue)], withRowAnimation: UITableViewRowAnimation.Automatic)
            self.tableView.endUpdates()
            
            // Select the current row in the picker
            if let startChannel = self.outputSettings[OutputSettings.StartChannel.rawValue]
            {
                self.startChannelPicker?.selectRow(startChannel, inComponent: 0, animated: false)
            }
            
        case TableViewRowType.EndChannel.rawValue:
            self.tableView.beginUpdates()
            if(self.endChannelPickerIsVisible == false)
            {
                self.endChannelPickerIsVisible = true
                self.tableView.insertRowsAtIndexPaths([NSIndexPath.init(forRow: 1, inSection: TableViewSectionNormal.EndChannel.rawValue)], withRowAnimation: UITableViewRowAnimation.Fade)
            }
            else
            {
                self.endChannelPickerIsVisible = false
                if self.outputSettings[OutputSettings.EndChannel.rawValue] != (self.endChannelPicker?.selectedRowInComponent(0))!
                {
                    self.outputSettings[OutputSettings.EndChannel.rawValue] = (self.endChannelPicker?.selectedRowInComponent(0))!;
                    // Update the endChannel
                    self.updateParticleParameterWith(.EndChannelForOutput, outputSetting: .EndChannel, string: "endChannel")
                }
                
                self.tableView.deleteRowsAtIndexPaths([NSIndexPath.init(forRow: 1, inSection: TableViewSectionNormal.EndChannel.rawValue)], withRowAnimation: UITableViewRowAnimation.Fade)
            }
            self.tableView.reloadRowsAtIndexPaths([NSIndexPath.init(forRow: 0, inSection: TableViewSectionNormal.EndChannel.rawValue)], withRowAnimation: UITableViewRowAnimation.Automatic)
            self.tableView.endUpdates()
            
            // Select the current row in the picker
            if let endChannel = self.outputSettings[OutputSettings.EndChannel.rawValue]
            {
                self.endChannelPicker?.selectRow(endChannel, inComponent: 0, animated: false)
            }
            
        default: break
        }
    }
    
    // MARK: - Other
    
    func tableViewRowTypeForIndexPath(indexPath: NSIndexPath!) -> TableViewRowType {
        var rowType: TableViewRowType!
        if self.isAbsoluteChannelNumbering == true
        {
            switch indexPath.section
            {
            case TableViewSectionAbsolute.Save.rawValue:
                rowType = TableViewRowType.Save
            case TableViewSectionAbsolute.Name.rawValue:
                rowType = TableViewRowType.Name
            case TableViewSectionAbsolute.Configure.rawValue:
                rowType = TableViewRowType.Configure
            case TableViewSectionAbsolute.PixelType.rawValue:
                if indexPath.row == 0
                {
                    rowType = TableViewRowType.PixelType
                }
                else
                {
                    rowType = TableViewRowType.PixelTypePicker
                }
            case TableViewSectionAbsolute.NumberOfPixels.rawValue:
                rowType = TableViewRowType.NumberOfPixels
            case TableViewSectionAbsolute.StartChannel.rawValue:
                rowType = TableViewRowType.StartChannelAbsolute
            case TableViewSectionAbsolute.EndChannel.rawValue:
                rowType = TableViewRowType.EndChannelAbsolute
            default: break
            }
        }
        else
        {
            switch indexPath.section
            {
            case TableViewSectionNormal.Save.rawValue:
                rowType = TableViewRowType.Save
            case TableViewSectionNormal.Name.rawValue:
                rowType = TableViewRowType.Name
            case TableViewSectionNormal.Configure.rawValue:
                rowType = TableViewRowType.Configure
            case TableViewSectionNormal.PixelType.rawValue:
                if indexPath.row == 0
                {
                    rowType = TableViewRowType.PixelType
                }
                else
                {
                    rowType = TableViewRowType.PixelTypePicker
                }
            case TableViewSectionNormal.NumberOfPixels.rawValue:
                rowType = TableViewRowType.NumberOfPixels
            case TableViewSectionNormal.StartUniverse.rawValue:
                rowType = TableViewRowType.StartUniverse
            case TableViewSectionNormal.StartChannel.rawValue:
                if indexPath.row == 0
                {
                    rowType = TableViewRowType.StartChannel
                }
                else
                {
                    rowType = TableViewRowType.StartChannelPicker
                }
            case TableViewSectionNormal.EndUniverse.rawValue:
                rowType = TableViewRowType.EndUniverse
            case TableViewSectionNormal.EndChannel.rawValue:
                if indexPath.row == 0
                {
                    rowType = TableViewRowType.EndChannel
                }
                else
                {
                    rowType = TableViewRowType.EndChannelPicker
                }
            default: break
            }
        }
        
        return rowType;
    }
    
    func prepareTextFieldCellWithText(text:String?, tag:Int?) -> TextFieldTableViewCell {
        let cell:TextFieldTableViewCell = self.tableView.dequeueReusableCellWithIdentifier("textFieldCell") as! TextFieldTableViewCell
        if let theText = text
        {
            cell.textField.text = theText
        }
        cell.textField.delegate = self
        cell.textField.keyboardType = UIKeyboardType.NumberPad
        if let theTag = tag
        {
            cell.textField.tag = theTag
        }
        cell.textField.enabled = (self.itemRefreshCount == self.numberOfItemsToRefresh ? true : false)
        
        return cell
    }
    
    func updateParticleParameterWith(command: UpdateParameterCommands!, outputSetting: OutputSettings!, string: String!)
    {
        // Update the endChannel
        self.device.callFunction("updateParams", withArguments: [command.rawValue, self.output, self.outputSettings[outputSetting.rawValue]!], completion: { (theResult:NSNumber!, error:NSError?) -> Void in
            if theResult != nil && theResult.integerValue == 1
            {
                TSMessage.showNotificationWithTitle("Success", subtitle: "Updated " + string + " to " + String(self.outputSettings[outputSetting.rawValue]!), type:TSMessageNotificationType.Success)
            }
            else
            {
                TSMessage.showNotificationWithTitle("Error", subtitle: "Error updating " + string + ", please check internet connection.", type: .Error)
            }
        })
    }
    
    func updateParticleChannelMap()
    {
        // Update the endChannel
        self.device.callFunction("updateParams", withArguments: [UpdateParameterCommands.ChannelMapForOutput.rawValue, self.output, self.outputSettings[OutputSettings.PixelType.rawValue]!, self.outputSettings[OutputSettings.NumberOfPixels.rawValue]!, self.outputSettings[OutputSettings.StartUniverse.rawValue]!, self.outputSettings[OutputSettings.StartChannel.rawValue]!, self.outputSettings[OutputSettings.EndUniverse.rawValue]!, self.outputSettings[OutputSettings.EndChannel.rawValue]!], completion: { (theResult:NSNumber!, error:NSError?) -> Void in
            if theResult != nil && theResult.integerValue == 1
            {
                TSMessage.showNotificationWithTitle("Success", subtitle: "Updated channel map", type:TSMessageNotificationType.Success)
            }
            else
            {
                TSMessage.showNotificationWithTitle("Error", subtitle: "Error updating channel map, please check internet connection.", type: .Error)
            }
        })
    }
    
    // MARK: - IPAddressPicker
    
    func pickerView(pickerView: UIPickerView, attributedTitleForRow row: Int, forComponent component: Int) -> NSAttributedString? {
        if pickerView.tag == PickerTags.PixelTypePicker.rawValue
        {
            let title = pixelTypeDescriptions[row]
            return NSAttributedString(string: title, attributes: [NSForegroundColorAttributeName:UIColor.whiteColor()])
        }
        else if pickerView.tag == PickerTags.StartChannelPicker.rawValue || pickerView.tag == PickerTags.EndChannelPicker.rawValue
        {
            let title = String(row + 1)
            return NSAttributedString(string: title, attributes: [NSForegroundColorAttributeName:UIColor.whiteColor()])
        }
        
        return NSAttributedString(string: "Error", attributes: [NSForegroundColorAttributeName:UIColor.whiteColor()])
    }
    
    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if pickerView.tag == PickerTags.PixelTypePicker.rawValue
        {
            return pixelTypeDescriptions.count
        }
        else if pickerView.tag == PickerTags.StartChannelPicker.rawValue || pickerView.tag == PickerTags.EndChannelPicker.rawValue
        {
            return self.universeSize
        }
        
        return 0
    }
    
    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
        return 1
    }
    
    // MARK: - Switch Selection
    @IBAction func absoluteButtonChange(theSwitch: UISwitch)
    {
        if theSwitch.on == true
        {
            self.isAbsoluteChannelNumbering = true
        }
        else
        {
            self.isAbsoluteChannelNumbering = false
        }
        
        self.tableView.reloadData()
    }
}