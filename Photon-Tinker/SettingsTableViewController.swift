//
//  SettingsTableViewController.swift
//  Particle
//
//  Created by Ido on 5/29/15.
//  Copyright (c) 2015 spark. All rights reserved.
//

import UIKit

class SettingsTableViewController: UITableViewController, UIPopoverPresentationControllerDelegate {

    @objc var device : SparkDevice? = nil
    
    @IBOutlet weak var deviceIDlabel: UILabel!
    
    // MARK: - Initilization
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.backgroundColor = UIColor(patternImage: self.imageResize(UIImage(named: "imgTrianglifyBackgroundBlue")!, newRect: UIScreen.mainScreen().bounds))
        
        let bar:UINavigationBar! =  self.navigationController?.navigationBar
        bar.setBackgroundImage(UIImage(named: "imgTrianglifyBackgroundBlue"), forBarMetrics: UIBarMetrics.Default)
        
        TSMessage.setDefaultViewController(self.navigationController)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.tableView.reloadData()
        self.deviceIDlabel.text = self.device!.id
    }
    
    // MARK: - TableView
    
    override func tableView(tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        if section == 2 {
            let infoDictionary = NSBundle.mainBundle().infoDictionary as [String : AnyObject]!
            let version = infoDictionary["CFBundleShortVersionString"] as! String!
            let build = infoDictionary["CFBundleVersion"] as! String!
            let label = UILabel()
            label.text = NSLocalizedString("Photon E1.31 Configuration V\(version) (\(build))", comment: "")
            label.textColor = UIColor.blackColor()
            label.textAlignment = .Center
            return label
        } else {
            return nil
        }
    }
    
    override func tableView(tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        
        let header: UITableViewHeaderFooterView = view as! UITableViewHeaderFooterView
        header.textLabel?.textColor = UIColor.blackColor()
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        self.tableView.deselectRowAtIndexPath(indexPath, animated: true)
        
        switch indexPath.section
        {
        case 0: // actions
            switch indexPath.row
            {
            case 0:
                UIPasteboard.generalPasteboard().string = self.device?.id
                TSMessage.showNotificationInViewController(self.navigationController, title: "Device ID", subtitle: "Your device ID string has been copied to clipboard", type: .Success)

            case 1:
                //self.delegate?.resetAllPinFunctions()
                self.dismissViewControllerAnimated(true, completion: nil)
//                TSMessage.showNotificationInViewController(self, title: "Pin functions", subtitle: "Your device ID string has been copied to clipboard", type: .Message)

            case 2:
                if self.device!.isFlashing == false
                {
                    let bundle = NSBundle.mainBundle()
                    let path = bundle.pathForResource(("photon_firmware_" + latestE131FVersion), ofType: "bin")
                    //var error:NSError?
                    if let binary: NSData? = NSData(contentsOfURL: NSURL(fileURLWithPath: path!))
                    {
                        let filesDict = ["e131.bin" : binary!]
                        self.device!.flashFiles(filesDict, completion: { (error:NSError!) -> Void in
                            if let e=error
                            {
                                TSMessage.showNotificationWithTitle("Flashing error", subtitle: "Error flashing device: \(e.localizedDescription)", type: .Error)
                            }
                            else
                            {
                                TSMessage.showNotificationWithTitle("Flashing successful", subtitle: "Please wait while your device is being flashed with E1.31 firmware...", type: .Success)
                                self.device!.isFlashing = true
                            }
                        })
                    }
                }
            default:
                print("default0")
            
            }
        case 1: // documenation
            var url : NSURL?
            switch indexPath.row
            {
            case 0:
                print("documentation: app")
                url = NSURL(string: "http://docs.particle.io/photon/tinker/#tinkering-with-tinker")
            case 1:
                print("documentation: setup your device")
                url = NSURL(string: "http://docs.particle.io/photon/connect/#connecting-your-device")
            case 2:
                print("documentation: make ios app")
                url = NSURL(string: "http://docs.particle.io/photon/ios/#ios-cloud-sdk")
            default:
                print("default1")
            }
            
            let webVC : WebViewController = self.storyboard!.instantiateViewControllerWithIdentifier("webview") as! WebViewController
            webVC.link = url
            webVC.linkTitle = tableView.cellForRowAtIndexPath(indexPath)?.textLabel?.text
            
            self.presentViewController(webVC, animated: true, completion: nil)
            
        case 2: // Support
            var url : NSURL?
            switch indexPath.row
            {
                case 0:
                print("support: community")
                url = NSURL(string: "http://community.particle.io/")
                
                case 1:
                print("support: email")
                url = NSURL(string: "http://support.particle.io/hc/en-us")
                
                default:
                print("default2")
            }
            
            let webVC : WebViewController = self.storyboard!.instantiateViewControllerWithIdentifier("webview") as! WebViewController
            webVC.link = url
            webVC.linkTitle = tableView.cellForRowAtIndexPath(indexPath)?.textLabel?.text

            self.presentViewController(webVC, animated: true, completion: nil)
            
        default:
            print("default")
        }
    }
    
    // MARK: - Other
    
    func imageResize(image:UIImage, newRect:CGRect) -> UIImage {
        let scale = UIScreen.mainScreen().scale
        UIGraphicsBeginImageContext(newRect.size)
        UIGraphicsBeginImageContextWithOptions(newRect.size, false, scale);
        image.drawInRect(CGRectMake(newRect.origin.x, newRect.origin.y, newRect.size.width, newRect.size.height))
        let newImage : UIImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage
    }
    
    @IBAction func closeButtonTapped(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: { () -> Void in
            //
        })
    }
}
