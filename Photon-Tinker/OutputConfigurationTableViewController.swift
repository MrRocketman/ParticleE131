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
    case Configure = 0
    case PixelType
    case NumberOfPixels
    case StartUniverse
    case StartChannel
    case EndUniverse
    case EndChannel
}

enum TableViewSectionAbsolute: Int {
    case Configure = 0
    case PixelType
    case NumberOfPixels
    case StartChannel
    case EndChannel
}

enum TableViewRowType: Int {
    case Configure = 0
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
    var numberOfTableSectionsNormal = 7
    var numberOfTableSectionsAbsolute = 5
    var tableSectionNamesNormal = ["Configure", "Pixel Type", "Number Of Pixels", "Start Universe", "Start Channel", "End Universe", "End Channel"]
    var tableSectionNamesAbsolute = ["Configure", "Pixel Type", "Number Of Pixels", "Start Channel", "End Channel"]
    var numberOfItemsToRefresh = 1
    var itemRefreshCount = 0
    var isAbsoluteChannelNumbering = true
    var pickerCellHeight: CGFloat!
    var pixelTypePickerIsVisible = false
    var startChannelPickerIsVisible = false
    var endChannelPickerIsVisible = false
    
    // Pin mapping variables
    var outputSettings: [Int?] = [nil, nil, nil, nil, nil, nil, nil, nil]
    
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
                        let stringPinMap = (outputSettings[self.output]).componentsSeparatedByString(",")
                        for var i = 0; i < stringPinMap.count; ++i
                        {
                            if stringPinMap[i].characters.count > 0
                            {
                                self.outputSettings[i] = Int(stringPinMap[i])!
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
                // TODO: Implement Item updates server interactions
            case TableViewRowType.NumberOfPixels.rawValue:
                // Auto update the end channel based on the number of pixels
                if let text = textField.text
                {
                    if text.characters.count > 0
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
                                let theoreticalEndChannel = startUniverse * self.universeSize + startChannel + numberOfPixels * 3 - 1 // -1 since channels actually start at 0, but are visually displayed as starting at 1
                                self.outputSettings[OutputSettings.EndUniverse.rawValue] = Int(theoreticalEndChannel / self.universeSize)
                                self.outputSettings[OutputSettings.EndChannel.rawValue] = Int(theoreticalEndChannel % self.universeSize)
                                
                                if self.isAbsoluteChannelNumbering == true
                                {
                                    self.tableView.reloadRowsAtIndexPaths([NSIndexPath.init(forRow: 0, inSection: TableViewSectionAbsolute.EndChannel.rawValue)], withRowAnimation: UITableViewRowAnimation.Automatic)
                                }
                                else
                                {
                                    self.tableView.reloadRowsAtIndexPaths([NSIndexPath.init(forRow: 0, inSection: TableViewSectionNormal.EndUniverse.rawValue)], withRowAnimation: UITableViewRowAnimation.Automatic)
                                    self.tableView.reloadRowsAtIndexPaths([NSIndexPath.init(forRow: 0, inSection: TableViewSectionNormal.EndChannel.rawValue)], withRowAnimation: UITableViewRowAnimation.Automatic)
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
                        
                        // Update Start info
                        self.outputSettings[OutputSettings.StartUniverse.rawValue] = startChannel / self.universeSize + 1 // Add 1 since universes start at 1 not 0
                        self.outputSettings[OutputSettings.StartChannel.rawValue] = startChannel % self.universeSize - 1 // -1 since channels actually start at 0, but are visually displayed as starting at 1
                        
                        // Update end info if we have pixels
                        if let numberOfPixels = self.outputSettings[OutputSettings.NumberOfPixels.rawValue]
                        {
                            let theoreticalEndChannel = self.outputSettings[OutputSettings.StartUniverse.rawValue]! * self.universeSize + self.outputSettings[OutputSettings.StartChannel.rawValue]! + numberOfPixels * 3 - 1 // -1 since channels actually start at 0, but are visually displayed as starting at 1
                            self.outputSettings[OutputSettings.EndUniverse.rawValue] = theoreticalEndChannel / self.universeSize
                            self.outputSettings[OutputSettings.EndChannel.rawValue] = theoreticalEndChannel % self.universeSize
                            
                            self.tableView.reloadRowsAtIndexPaths([NSIndexPath.init(forRow: 0, inSection: TableViewSectionAbsolute.EndChannel.rawValue)], withRowAnimation: UITableViewRowAnimation.Automatic)
                        }
                    }
                }
            /*case TableViewRowType.StartChannel.rawValue:
                // Auto update the end channel based on the number of pixels
                if let text = textField.text
                {
                    if text.characters.count > 0
                    {
                        // Bounds check
                        var startChannel: Int!
                        if Int(text)! > self.universeSize
                        {
                            startChannel = self.universeSize
                        }
                        else
                        {
                            startChannel = Int(text)!
                        }
                        
                        // Update start info
                        self.outputSettings[OutputSettings.StartUniverse.rawValue] = startChannel / self.universeSize + 1 // Add 1 since universes start at 1 not 0
                        self.outputSettings[OutputSettings.StartChannel.rawValue] = startChannel % self.universeSize - 1 // -1 since channels actually start at 0, but are visually displayed as starting at 1
                        // Update end info if we have pixels
                        if let numberOfPixels = self.outputSettings[OutputSettings.NumberOfPixels.rawValue]
                        {
                            let theoreticalEndChannel = self.outputSettings[OutputSettings.StartUniverse.rawValue]! * self.universeSize + self.outputSettings[OutputSettings.StartChannel.rawValue]! + numberOfPixels * 3 - 1 // -1 since channels actually start at 0, but are visually displayed as starting at 1
                            self.outputSettings[OutputSettings.EndUniverse.rawValue] = theoreticalEndChannel / self.universeSize
                            self.outputSettings[OutputSettings.EndChannel.rawValue] = theoreticalEndChannel % self.universeSize
                            
                            self.tableView.reloadRowsAtIndexPaths([NSIndexPath.init(forRow: 0, inSection: TableViewSectionNormal.EndUniverse.rawValue)], withRowAnimation: UITableViewRowAnimation.Automatic)
                            self.tableView.reloadRowsAtIndexPaths([NSIndexPath.init(forRow: 0, inSection: TableViewSectionNormal.EndChannel.rawValue)], withRowAnimation: UITableViewRowAnimation.Automatic)
                        }
                    }
                }*/
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
                        
                        // Update the start data
                        self.outputSettings[OutputSettings.StartUniverse.rawValue] = startUniverse
                        
                        // Update the end info if we have pixels
                        if let numberOfPixels = self.outputSettings[OutputSettings.NumberOfPixels.rawValue]
                        {
                            let theoreticalEndChannel = self.outputSettings[OutputSettings.StartUniverse.rawValue]! * self.universeSize + self.outputSettings[OutputSettings.StartChannel.rawValue]! + numberOfPixels * 3 - 1 // -1 since channels actually start at 0, but are visually displayed as starting at 1
                            self.outputSettings[OutputSettings.EndUniverse.rawValue] = theoreticalEndChannel / self.universeSize
                            
                            self.tableView.reloadRowsAtIndexPaths([NSIndexPath.init(forRow: 0, inSection: TableViewSectionNormal.EndUniverse.rawValue)], withRowAnimation: UITableViewRowAnimation.Automatic)
                            self.tableView.reloadRowsAtIndexPaths([NSIndexPath.init(forRow: 0, inSection: TableViewSectionNormal.EndChannel.rawValue)], withRowAnimation: UITableViewRowAnimation.Automatic)
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
        
        var rowType: TableViewRowType!
        if self.isAbsoluteChannelNumbering == true
        {
            switch indexPath.section
            {
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
        
        switch rowType.rawValue
        {
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
            if self.startChannelPickerIsVisible == true
            {
                cell.textLabel!.text = "Done"
            }
            else
            {
                if let startChannel = self.outputSettings[OutputSettings.StartChannel.rawValue]
                {
                    cell.textLabel!.text = String(startChannel)
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
            if self.endChannelPickerIsVisible == true
            {
                cell.textLabel!.text = "Done"
            }
            else
            {
                if let endChannel = self.outputSettings[OutputSettings.EndChannel.rawValue]
                {
                    cell.textLabel!.text = String(endChannel)
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
        
        var rowType: TableViewRowType!
        if self.isAbsoluteChannelNumbering == true
        {
            switch indexPath.section
            {
            case TableViewSectionAbsolute.PixelType.rawValue:
                if indexPath.row == 0
                {
                    rowType = TableViewRowType.PixelType
                }
                else
                {
                    rowType = TableViewRowType.PixelTypePicker
                }
            default:
                rowType = TableViewRowType.Configure
            }
        }
        else
        {
            switch indexPath.section
            {
            case TableViewSectionNormal.PixelType.rawValue:
                if indexPath.row == 0
                {
                    rowType = TableViewRowType.PixelType
                }
                else
                {
                    rowType = TableViewRowType.PixelTypePicker
                }
            case TableViewSectionNormal.StartChannel.rawValue:
                if indexPath.row == 0
                {
                    rowType = TableViewRowType.StartChannel
                }
                else
                {
                    rowType = TableViewRowType.StartChannelPicker
                }
            case TableViewSectionNormal.EndChannel.rawValue:
                if indexPath.row == 0
                {
                    rowType = TableViewRowType.EndChannel
                }
                else
                {
                    rowType = TableViewRowType.EndChannelPicker
                }
            default:
                rowType = TableViewRowType.Configure
            }
        }
        
        switch rowType.rawValue
        {
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
                self.tableView.deleteRowsAtIndexPaths([NSIndexPath.init(forRow: 1, inSection: TableViewSectionNormal.PixelType.rawValue)], withRowAnimation: UITableViewRowAnimation.Fade)
            }
            self.tableView.reloadRowsAtIndexPaths([NSIndexPath.init(forRow: 0, inSection: TableViewSectionNormal.PixelType.rawValue)], withRowAnimation: UITableViewRowAnimation.Automatic)
            self.tableView.endUpdates()
            
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
                self.tableView.deleteRowsAtIndexPaths([NSIndexPath.init(forRow: 1, inSection: TableViewSectionNormal.StartChannel.rawValue)], withRowAnimation: UITableViewRowAnimation.Fade)
            }
            self.tableView.reloadRowsAtIndexPaths([NSIndexPath.init(forRow: 0, inSection: TableViewSectionNormal.StartChannel.rawValue)], withRowAnimation: UITableViewRowAnimation.Automatic)
            self.tableView.endUpdates()
            
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
                self.tableView.deleteRowsAtIndexPaths([NSIndexPath.init(forRow: 1, inSection: TableViewSectionNormal.EndChannel.rawValue)], withRowAnimation: UITableViewRowAnimation.Fade)
            }
            self.tableView.reloadRowsAtIndexPaths([NSIndexPath.init(forRow: 0, inSection: TableViewSectionNormal.EndChannel.rawValue)], withRowAnimation: UITableViewRowAnimation.Automatic)
            self.tableView.endUpdates()
            
        default: break
        }
    }
    
    func prepareTextFieldCellWithText(text:String?, tag:Int?) -> TextFieldTableViewCell {
        let cell:TextFieldTableViewCell = self.tableView.dequeueReusableCellWithIdentifier("textFieldCell") as! TextFieldTableViewCell
        if let _ = text
        {
            cell.textField.text = text
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