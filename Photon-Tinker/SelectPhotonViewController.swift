//
//  SelectPhotonViewController.swift
//  Photon-Tinker
//
//  Created by Ido on 4/16/15.
//  Copyright (c) 2015 spark. All rights reserved.
//

import UIKit

let deviceNamesArr : [String] = [ "aardvark", "bacon", "badger", "banjo", "bobcat", "boomer", "captain", "chicken", "cowboy", "cracker", "cranky", "crazy", "dentist", "doctor", "dozen", "easter", "ferret", "gerbil", "hacker", "hamster", "hindu", "hobo", "hoosier", "hunter", "jester", "jetpack", "kitty", "laser", "lawyer", "mighty", "monkey", "morphing", "mutant", "narwhal", "ninja", "normal", "penguin", "pirate", "pizza", "plumber", "power", "puppy", "ranger", "raptor", "robot", "scraper", "scrapple", "station", "tasty", "trochee", "turkey", "turtle", "vampire", "wombat", "zombie" ]
let kDefaultCoreFlashingTime : Int = 30
let kDefaultPhotonFlashingTime : Int = 15
let latestE131FVersion = "0000000005"


class SelectPhotonViewController: UITableViewController, SparkSetupMainControllerDelegate {
    @IBOutlet weak var photonSelectionTableView: UITableView!
    var devices : [SparkDevice] = []
    var deviceIDflashingDict : Dictionary<String,Int> = Dictionary()
    var deviceIDflashingTimer : NSTimer? = nil
    
    var selectedDevice : SparkDevice? = nil
    var lastTappedNonTinkerDevice : SparkDevice? = nil
    
    //MARK: - Initilization
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.photonSelectionTableView.backgroundColor = UIColor(patternImage: self.imageResize(UIImage(named: "imgTrianglifyBackgroundBlue")!, newRect: UIScreen.mainScreen().bounds))
        
        srandom(arc4random())
        
        self.refreshControl?.addTarget(self, action: "loadDevices", forControlEvents: UIControlEvents.ValueChanged)
        self.refreshControl?.tintColor = UIColor.blackColor()
        
        let bar:UINavigationBar! =  self.navigationController?.navigationBar
        bar.setBackgroundImage(UIImage(named: "imgTrianglifyBackgroundBlue"), forBarMetrics: UIBarMetrics.Default)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("updateDeviceName:"), name: "UpdateDeviceName", object: nil)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        self.deviceIDflashingTimer!.invalidate()
        if segue.identifier == "tinker"
        {
            self.lastTappedNonTinkerDevice = nil
            
            if let vc = segue.destinationViewController as? E131ConfigurationTableViewController
            {
                vc.device = self.selectedDevice!
            }
        }
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.refreshControl?.beginRefreshing()
        self.tableView.setContentOffset(CGPointMake(0, -(self.refreshControl?.frame.size.height)!), animated:true)
        self.loadDevices()
        
        self.deviceIDflashingTimer = NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: "flashingTimerFunc:", userInfo: nil, repeats: true)
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
    
    //MARK: - Loading/Refresh
    
    func updateDeviceName(notification: NSNotification) {
        for var i = 0; i < self.photonSelectionTableView.numberOfRowsInSection(0); ++i
        {
            let cell = self.photonSelectionTableView.cellForRowAtIndexPath(NSIndexPath.init(forRow: i, inSection: 0)) as? DeviceTableViewCell
            let device = notification.object as! SparkDevice
            if let _ = cell
            {
                if cell!.deviceIDLabel.text == device.id.uppercaseString
                {
                    self.photonSelectionTableView.reloadRowsAtIndexPaths([NSIndexPath.init(forRow: i, inSection: 0)], withRowAnimation: UITableViewRowAnimation.Automatic)
                }
            }
        }
    }
    
    func loadDevices()
    {
        dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
            
            SparkCloud.sharedInstance().getDevices({ (devices:[AnyObject]?, error:NSError?) -> Void in
                self.handleGetDevicesResponse(devices, error: error)
                self.refreshControl?.endRefreshing()
            })
        }
    }
    
    func handleGetDevicesResponse(devices:[AnyObject]?, error:NSError?)
    {
        if let e = error
        {
            print("error listing devices for user \(SparkCloud.sharedInstance().loggedInUsername)")
            print(e.description)
            TSMessage.showNotificationWithTitle("Error", subtitle: "Error loading devices, please check internet connection.", type: .Error)
        }
        else
        {
            // Copy the currentDevices into oldDevices for comparison
            var oldDevices : [SparkDevice] = []
            for currentDevice in self.devices
            {
                var parameters = Dictionary<String, AnyObject>()
                parameters["name"] = currentDevice.name
                parameters["connected"] = currentDevice.connected
                parameters["last_app"] = currentDevice.lastApp
                parameters["device_needs_update"] = currentDevice.requiresUpdate
                parameters["product_id"] = currentDevice.type.rawValue
                if let id = currentDevice.id
                {
                    parameters["id"] = id
                }
                if let variables = currentDevice.variables
                {
                    parameters["variables"] = variables
                }
                if let functions = currentDevice.functions
                {
                    parameters["functions"] = functions
                }
                
                let device : SparkDevice = SparkDevice.init(params: parameters)
                oldDevices.append(device)
            }
            
            // See if the new devices are valid
            if let d = devices
            {
                self.devices = d as! [SparkDevice]
                
                // Sort alphabetically
                self.devices.sortInPlace({ (firstDevice:SparkDevice, secondDevice:SparkDevice) -> Bool in
                    if let n1 = firstDevice.name
                    {
                        if let n2 = secondDevice.name
                        {
                            return n1 < n2 //firstDevice.name < secondDevice.name
                        }
                    }
                    return false;
                })

                // then sort by device type
                self.devices.sortInPlace({ (firstDevice:SparkDevice, secondDevice:SparkDevice) -> Bool in
                    return firstDevice.type.rawValue > secondDevice.type.rawValue
                })

                // and then by online/offline
                self.devices.sortInPlace({ (firstDevice:SparkDevice, secondDevice:SparkDevice) -> Bool in
                    return firstDevice.connected && !secondDevice.connected
                })
                
                // and then by firmware version
                self.devices.sortInPlace({ (firstDevice:SparkDevice, secondDevice:SparkDevice) -> Bool in
                    if firstDevice.connected && secondDevice.connected
                    {
                        // First device has variables
                        if firstDevice.variables != nil
                        {
                            // Second device has variables
                            if secondDevice.variables != nil
                            {
                                // First device isn't running e131. Second is. Change the order
                                if firstDevice.variables["e131FVersion"] == nil && secondDevice.variables["e131FVersion"] != nil
                                {
                                    // First device isn't running e131. Second is. Change the order
                                    return false
                                }
                            }
                            // Second device doesn't have variables
                            else
                            {
                                // First device is potentially running e131. Second isn't. Keep the order the same
                                return true
                            }
                        }
                        // First device doesn't have variables
                        else
                        {
                            // Second device has variables
                            if secondDevice.variables != nil
                            {
                                // Second device is running e131
                                if secondDevice.variables["e131FVersion"] != nil
                                {
                                    // First device isn't running e131. Second is. Change the order
                                    return false
                                }
                            }
                            // Second device doesn't have variables
                            else
                            {
                                // Both aren't running e131. Keep the order the same
                                return true
                            }
                        }
                        
                        // First device is running e131. Second isn't. Keep the order the same
                        // Both are running e131. Keep the order the same
                        // Both aren't running e131. Keep the order the same
                        return true
                    }
                    else if firstDevice.connected && !secondDevice.connected
                    {
                        return true
                    }
                    else if !firstDevice.connected && secondDevice.connected
                    {
                        return false
                    }
                    else
                    {
                        return false
                    }
                })
            }
            
            dispatch_async(dispatch_get_main_queue()) {
                var hadAnUpdate = false
                
                let oldDevicesCount : Int = oldDevices.count
                let newDevicesCount : Int = self.devices.count
                for var i = 0; i < newDevicesCount; ++i
                {
                    let oldDeviceOptional : SparkDevice? = i < oldDevicesCount ? oldDevices[i] : nil
                    let newDeviceOptional : SparkDevice? = i < newDevicesCount ? self.devices[i] : nil
                    
                    // See if we have an oldDevice at this index
                    if let oldDevice = oldDeviceOptional
                    {
                        // See if we have a newDevice at this index
                        if let newDevice = newDeviceOptional
                        {
                            var versionChange = false
                            var infoChange = false
                            
                            // Refresh the row if the ID, name, or status changed
                            if oldDevice.id != newDevice.id || oldDevice.connected != newDevice.connected || oldDevice.name != newDevice.name
                            {
                                infoChange = true
                            }
                            
                            // If the new device is online, we need to check if it's firmware version has changed
                            if newDevice.connected
                            {
                                versionChange = true
                            }
                            
                            // Update the row if there was a change
                            if(infoChange || versionChange)
                            {
                                if !hadAnUpdate
                                {
                                    hadAnUpdate = true
                                    self.photonSelectionTableView.beginUpdates()
                                }
                                self.photonSelectionTableView.reloadRowsAtIndexPaths([NSIndexPath.init(forItem: i, inSection: 0)], withRowAnimation: UITableViewRowAnimation.Automatic)
                            }
                        }
                    }
                    // If a new device has been added (oldDevice at this index is nil), insert the new device
                    else
                    {
                        if !hadAnUpdate
                        {
                            hadAnUpdate = true
                            self.photonSelectionTableView.beginUpdates()
                        }
                        self.photonSelectionTableView.insertRowsAtIndexPaths([NSIndexPath.init(forItem: i, inSection: 0)], withRowAnimation: UITableViewRowAnimation.Automatic)
                    }
                }
                // Delete rows if we have fewer rows now
                if newDevicesCount < oldDevicesCount
                {
                    NSLog("deleteRow")
                    for var i = newDevicesCount - 1; i < oldDevicesCount; ++i
                    {
                        if !hadAnUpdate
                        {
                            hadAnUpdate = true
                            self.photonSelectionTableView.beginUpdates()
                        }
                        self.photonSelectionTableView.deleteRowsAtIndexPaths([NSIndexPath.init(forItem: i, inSection: 0)], withRowAnimation: UITableViewRowAnimation.Automatic)
                    }
                }
                
                self.photonSelectionTableView.endUpdates()
                
                //self.photonSelectionTableView.reloadData()
            }
        }
    }
    
    // MARK: - TableView
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.devices.count+2
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        var masterCell : UITableViewCell?
        
        if indexPath.row < self.devices.count
        {
            let device: SparkDevice = self.devices[indexPath.row]
            let cell:DeviceTableViewCell = self.photonSelectionTableView.dequeueReusableCellWithIdentifier("device_cell") as! DeviceTableViewCell
            
            if let name = device.name
            {
                cell.deviceNameLabel.text = name
            }
            else
            {
                cell.deviceNameLabel.text = "<no name>"
            }
            
            switch (device.type)
            {
            case .Core:
                cell.deviceImageView.image = UIImage(named: "imgCore")
                cell.deviceTypeLabel.text = "Core"

            case .Photon: // .Photon
                fallthrough
            default:
                cell.deviceImageView.image = UIImage(named: "imgPhoton")
                cell.deviceTypeLabel.text = "Photon"

            }

            cell.deviceIDLabel.text = device.id.uppercaseString
            
            let online = device.connected
            switch online
            {
            case true :
                cell.deviceStateLabel.text = "Loading..."
                
                device.getVariable("e131FVersion", completion: { (theResult:AnyObject!, error:NSError?) -> Void in
                    if let firmwareVersion = theResult as? String
                    {
                        device.e131FirmwareVersion = firmwareVersion
                        if firmwareVersion == latestE131FVersion
                        {
                            cell.deviceStateLabel.text = "Online"
                            cell.deviceStateImageView.image = UIImage(named: "imgGreenCircle")
                        }
                        else if firmwareVersion != latestE131FVersion
                        {
                            cell.deviceStateLabel.text = "Online, Outdated Firmware"
                            cell.deviceStateImageView.image = UIImage(named: "imgYellowCircle")
                        }
                    }
                    else
                    {
                        cell.deviceStateLabel.text = "Online, non-E1.31"
                        cell.deviceStateImageView.image = UIImage(named: "imgYellowCircle")
                    }
                })
            default :
                cell.deviceStateLabel.text = "Offline"
                cell.deviceStateImageView.image = UIImage(named: "imgRedCircle") // red circle
                
            }
            
            // override everything else
            if device.isFlashing || self.deviceIDflashingDict.keys.contains(device.id)
            {
                cell.deviceStateLabel.text = "Flashing"
                cell.deviceStateImageView.image = UIImage(named: "imgPurpleCircle") // gray circle
            }
            
            masterCell = cell
        }
        else if indexPath.row == self.devices.count
        {
            masterCell = self.photonSelectionTableView.dequeueReusableCellWithIdentifier("setup_photon_cell") as UITableViewCell!
        }
        else if indexPath.row == self.devices.count+1
        {
            masterCell = self.photonSelectionTableView.dequeueReusableCellWithIdentifier("setup_core_cell") as UITableViewCell!
        }
        
        // make cell darker if it's even
        if (indexPath.row % 2) == 0
        {
            masterCell?.backgroundColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 0.3)
        }
        else // lighter if even
        {
            masterCell?.backgroundColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0)
        }
        
        return masterCell!
    }
    
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        // user swiped left
        if editingStyle == .Delete
        {
            TSMessage.showNotificationInViewController(self, title: "Unclaim confirmation", subtitle: "Are you sure you want to remove this device from your account?", image: UIImage(named: "imgQuestionWhite"), type: .Error, duration: -1, callback: { () -> Void in
                // callback for user dismiss by touching inside notification
                TSMessage.dismissActiveNotification()
                tableView.editing = false
                } , buttonTitle: " Yes ", buttonCallback: { () -> Void in
                    // callback for user tapping YES button - need to delete row and update table
                    self.devices[indexPath.row].unclaim() { (error: NSError?) -> Void in
                        if let err = error
                        {
                            TSMessage.showNotificationWithTitle("Error", subtitle: err.localizedDescription, type: .Error)
                            self.photonSelectionTableView.reloadData()
                        }
                    }
                    
                    self.devices.removeAtIndex(indexPath.row)
                    tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
                    let delayTime = dispatch_time(DISPATCH_TIME_NOW, Int64(0.25 * Double(NSEC_PER_SEC)))
                    // update table view display to show dark/light cells with delay so that delete animation can complete nicely
                    dispatch_after(delayTime, dispatch_get_main_queue()) {
                        tableView.reloadData()
                }}, atPosition: .Top, canBeDismissedByUser: true)
            }
        }
        
    override func tableView(tableView: UITableView, titleForDeleteConfirmationButtonForRowAtIndexPath indexPath: NSIndexPath) -> String? {
        return "Unclaim"
    }
    
    override func tableView(tableView: UITableView, didEndEditingRowAtIndexPath indexPath: NSIndexPath) {
        // user touches elsewhere
        TSMessage.dismissActiveNotification()
    }
    
    // prevent "Setup new photon" row from being edited/deleted
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return indexPath.row < self.devices.count
    }
    
    
    func sparkSetupViewController(controller: SparkSetupMainController!, didFinishWithResult result: SparkSetupMainControllerResult, device: SparkDevice!) {
        if result == .Success
        {
            if (device.name == nil)
            {
                let deviceName = self.generateDeviceName()
                device.rename(deviceName, completion: { (error:NSError!) -> Void in
                    if let _=error
                    {
                        TSMessage.showNotificationWithTitle("Device added", subtitle: "You successfully added a new device to your account but there was a problem communicating with it. Device has been named \(deviceName).", type: .Warning)
                    }
                    else
                    {
                        dispatch_async(dispatch_get_main_queue()) {
                            TSMessage.showNotificationWithTitle("Success", subtitle: "You successfully added a new device to your account. Device has been named \(deviceName).", type: .Success)
                            self.photonSelectionTableView.reloadData()
                        }
                    }
                })
            }
            else
            {
                TSMessage.showNotificationWithTitle("Success", subtitle: "You successfully added a new device to your account. Device is named \(device.name).", type: .Success)
                self.photonSelectionTableView.reloadData()

            }
        }
        else
        {
            TSMessage.showNotificationWithTitle("Warning", subtitle: "Device setup did not complete, new device was not added to your account.", type: .Warning)
        }
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        TSMessage.dismissActiveNotification()
        tableView.deselectRowAtIndexPath(indexPath, animated: true)

        if self.devices.count == 0
        {
            switch indexPath.row
            {
            case 0:
                self.invokeDeviceSetup()
            default:
                self.showSparkCoreAppPopUp()
            }
            
        }
        else
        {
            let device: SparkDevice = self.devices[indexPath.row]
            var deviceE131FirmwareVersion: String
            if let fVersion = device.e131FirmwareVersion
            {
                deviceE131FirmwareVersion = fVersion
            }
            else
            {
                deviceE131FirmwareVersion = "Not"
            }
            
            switch indexPath.row
            {
            case 0...self.devices.count-1 :
                tableView.deselectRowAtIndexPath(indexPath, animated: false)
                
                if device.isFlashing || self.deviceIDflashingDict.keys.contains(device.id)
                {
                    TSMessage.showNotificationWithTitle("Device is being flashed", subtitle: "Device is currently being flashed, please wait for the process to finish.", type: .Warning)

                }
                else if device.connected
                {
                    if deviceE131FirmwareVersion == latestE131FVersion
                    {
                        self.selectedDevice = device
                        self.performSegueWithIdentifier("tinker", sender: self)
                    }
                    else
                    {
                        if let ntd = self.lastTappedNonTinkerDevice where device.id == ntd.id
                        {
                            self.selectedDevice = device
                            self.performSegueWithIdentifier("tinker", sender: self)
                        }
                        else
                        {
                            self.lastTappedNonTinkerDevice = device
                            NSTimer.scheduledTimerWithTimeInterval(10.0, target: self, selector: "resetLastTappedDevice:", userInfo: nil, repeats: false)
                            
                            // Show the option to flash the firmware if the firmware is outdated, or non-E1.31
                            if deviceE131FirmwareVersion != latestE131FVersion || deviceE131FirmwareVersion == "Not"
                            {
                                TSMessage.showNotificationInViewController(self, title: (device.e131FirmwareVersion == nil ? "Device not running E1.31" : "Device firmware outdated"), subtitle: "Do you want to flash E1.31 firmware to this device? Tap device again to configure it anyway", image: UIImage(named: "imgQuestionWhite"), type: .Message, duration: -1, callback: { () -> Void in
                                    // callback for user dismiss by touching inside notification
                                    TSMessage.dismissActiveNotification()
                                    } , buttonTitle: " Flash ", buttonCallback: { () -> Void in
                                        self.lastTappedNonTinkerDevice = nil
                                        
                                        let bundle = NSBundle.mainBundle()
                                        let path = bundle.pathForResource(("photon_firmware_" + latestE131FVersion), ofType: "bin")
                                        if let binary: NSData? = NSData(contentsOfURL: NSURL(fileURLWithPath: path!))
                                        {
                                            let filesDict = ["e131.bin" : binary!]
                                            device.flashFiles(filesDict, completion: { (error:NSError!) -> Void in
                                                if let e=error
                                                {
                                                    TSMessage.showNotificationWithTitle("Flashing error", subtitle: "Error flashing device: \(e.localizedDescription)", type: .Error)
                                                }
                                                else
                                                {
                                                    TSMessage.showNotificationWithTitle("Flashing successful", subtitle: "Please wait while your device is being flashed with E1.31 firmware...", type: .Success)
                                                    device.isFlashing = true
                                                    switch (device.type)
                                                    {
                                                    case .Core:
                                                        self.deviceIDflashingDict[device.id] = kDefaultCoreFlashingTime
                                                    case .Photon:
                                                        self.deviceIDflashingDict[device.id] = kDefaultPhotonFlashingTime
                                                    }
                                                    self.photonSelectionTableView.reloadData()
                                                    
                                                }
                                            })
                                        }
                                    }, atPosition: .Top, canBeDismissedByUser: true)
                            }
                        }
                    }
                }
                else
                {
                    self.lastTappedNonTinkerDevice = nil
                    TSMessage.showNotificationWithTitle("Device offline", subtitle: "This device is offline, please turn it on and refresh in order to configure it.", type: .Error)
                }
            case self.devices.count :
                self.invokeDeviceSetup()
            case self.devices.count+1 :
                self.showSparkCoreAppPopUp()
            default :
                break
        }
        }
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 70
    }
    
    // MARK: - Device Setup/Other
    
    func invokeDeviceSetup()
    {
        if let vc = SparkSetupMainController()
        {
            vc.delegate = self
            self.presentViewController(vc, animated: true, completion: nil)
        }
        
    }
    
    func showSparkCoreAppPopUp()
    {
        let popup = Popup(title: "Core setup", subTitle: "Setting up a Core requires the Spark Core app. Do you want to install/open it now?", cancelTitle: "No", successTitle: "Yes", cancelBlock: {()->() in }, successBlock: {()->() in
            let sparkCoreAppStoreLink = "itms://itunes.apple.com/us/app/apple-store/id760157884?mt=8";
            UIApplication.sharedApplication().openURL(NSURL(string: sparkCoreAppStoreLink)!)
        })
        popup.incomingTransition = .SlideFromBottom
        popup.outgoingTransition = .FallWithGravity
        popup.backgroundBlurType = .Dark
        popup.roundedCorners = true
        popup.tapBackgroundToDismiss = true
        popup.backgroundColor = UIColor.clearColor()// UIColor(red: 0, green: 123.0/255.0, blue: 181.0/255.0, alpha: 1.0) //UIColor(patternImage: UIImage(named: "imgTrianglifyBackgroundBlue")!)
        popup.titleColor = UIColor.whiteColor()
        popup.subTitleColor = UIColor.whiteColor()
        popup.successBtnColor = UIColor(red: 0, green: 186.0/255.0, blue: 236.0/255.0, alpha: 1.0)
        popup.successTitleColor = UIColor.whiteColor()
        popup.cancelBtnColor = UIColor.clearColor()
        popup.cancelTitleColor = UIColor.whiteColor()
        popup.borderColor = UIColor.clearColor()
        popup.showPopup()
        
    }
    
    func resetLastTappedDevice(timer : NSTimer)
    {
        print("lastTappedNonTinkerDevice reset")
        self.lastTappedNonTinkerDevice = nil
    }
    
    func flashingTimerFunc(timer : NSTimer)
    {
        for (deviceid, timeleft) in self.deviceIDflashingDict
        {
            if timeleft > 0
            {
                self.deviceIDflashingDict[deviceid]=timeleft-1
            }
            else
            {
                self.deviceIDflashingDict.removeValueForKey(deviceid)
                self.loadDevices()
            }
        }
    }
    
    @IBAction func logoutButtonTapped(sender: UIButton) {
        SparkCloud.sharedInstance().logout()
        if let navController = self.navigationController {
            navController.popViewControllerAnimated(true)
        }

    }
    
    func generateDeviceName() -> String
    {
        let name : String = deviceNamesArr[Int(arc4random_uniform(UInt32(deviceNamesArr.count)))] + "_" + deviceNamesArr[Int(arc4random_uniform(UInt32(deviceNamesArr.count)))]
        
        return name
    }
}
