//
//  Conference.swift
//  VoxeetSDK Sample
//
//  Created by Coco on 28/04/16.
//  Copyright © 2016 Corentin Larroque. All rights reserved.
//

import UIKit
import VoxeetSDK

/*
 *  MARK: - User structure
 */

struct User {
    var userID: String
    var externalID: String?
    var avatarUrl: String?
    var name: String?
}

/*
 *  MARK: - Conference class
 */

class Conference: UIViewController {
    // UI.
    @IBOutlet weak var conferenceIDLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var broadcastMessageTextView: UITextView!
    
    // Current conference ID.
    var conferenceID: String?
    
    // Users' ID.
    var users = [User]()
    
    /*
     *  MARK: Load
     */
    
    override func viewDidLoad() {
        // Setting label.
        conferenceIDLabel.text = conferenceID
        
        // Joining / Launching demo.
        if let confID = conferenceID {
            // Joining Conference.
            VoxeetSDK.sharedInstance.joinConference(conferenceAlias: confID) { (error) in
                if error != nil {
                    // Debug.
                    print("::DEBUG:: <joinConference> \(error)")
                    
                    self.dismissViewControllerAnimated(true, completion: nil)
                }
            }
        } else {
            conferenceIDLabel.text = "Demo"
            
            // Creating Voxeet demo conference.
            VoxeetSDK.sharedInstance.createDemoConference { (error) in
                if error != nil {
                    // Debug.
                    print("::DEBUG:: <createDemoConference> \(error)")
                    
                    self.dismissViewControllerAnimated(true, completion: nil)
                }
            }
        }
        
        // Conference delegate.
        VoxeetSDK.sharedInstance.conferenceDelegate = self
    }
    
    /*
     *  MARK: Action
     */
    
    @IBAction func sendBroadcastMessage(sender: AnyObject) {
        // Alert view.
        let alertController = UIAlertController(title: "Send Message", message: "Please input the message:", preferredStyle: .Alert)
        
        // Alert actions.
        let confirmAction = UIAlertAction(title: "Send", style: .Default) { (_) in
            if let textField = alertController.textFields?[0],
                let message = textField.text {
                // Sending a broadcast message.
                VoxeetSDK.sharedInstance.sendBroadcastMessage(message, completion: { (error) in
                    // Debug.
                    print("::DEBUG:: <sendBroadcastMessage> \(error)")
                })
            }
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel) { (_) in }
        
        // Alert textField.
        alertController.addTextFieldWithConfigurationHandler { (textField) in
            textField.placeholder = "Message"
            textField.clearButtonMode = .WhileEditing
        }
        
        alertController.addAction(confirmAction)
        alertController.addAction(cancelAction)
        self.presentViewController(alertController, animated: true, completion: nil)
    }
    
    @IBAction func hangUp(sender: AnyObject) {
        VoxeetSDK.sharedInstance.leaveConference { (error) in
            // Debug.
            print("::DEBUG:: <leaveConference> \(error)")
            
            self.dismissViewControllerAnimated(true, completion: nil)
        }
    }
}

/*
 *  MARK: - Voxeet SDK conference delegate
 */

extension Conference: VTConferenceDelegate {
    func userDidJoin(userID: String, userInfo: [String: String]) {
        users.append(User(userID: userID, externalID: userInfo["externalId"], avatarUrl: userInfo["avatarUrl"], name: userInfo["name"]))
        tableView.reloadData()
    }
    
    func userDidLeft(userID: String, userInfo: [String: String]) {
        users = users.filter({ $0.userID != userID })
        tableView.reloadData()
    }
    
    func messageReceived(userID: String, userInfo: [String: String], message: String) {
        if let name = users.filter({ $0.userID == userID }).first?.name {
            broadcastMessageTextView.text = "\(name): \(message)"
        } else {
            broadcastMessageTextView.text = "\(userID): \(message)"
        }
    }
}

/*
 *  MARK: - Conference tableView dataSource & delegate
 */

extension Conference: UITableViewDataSource, UITableViewDelegate {
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return users.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("tableViewCell", forIndexPath: indexPath) as! ConferenceTableViewCell
        
        let user = users[indexPath.row]
        
        // Cell label.
        if let name = user.name {
            cell.userLabel.text = name
        } else {
            cell.userLabel.text = user.userID
        }
        
        // Cell avatar.
        if let avatarURL = user.avatarUrl {
            let imgURL: NSURL = NSURL(string: avatarURL)!
            let request: NSURLRequest = NSURLRequest(URL: imgURL)
            let task = NSURLSession.sharedSession().dataTaskWithRequest(request) { data, response, error in
                if error == nil {
                    if let data = data {
                        dispatch_async(dispatch_get_main_queue()) {
                            cell.userPhoto.image = UIImage(data: data)
                        }
                    }
                } else {
                    // Debug.
                    print("::DEBUG:: <avatar> \(error?.localizedDescription)")
                }
            }
            task.resume()
        }
        
        // Slider update.
        if let position = VoxeetSDK.sharedInstance.getUserPosition(user.userID) {
            cell.angleSlider.setValue(position.angle, animated: false)
            cell.distanceSlider.setValue(position.distance, animated: false)
        }
        
        // Background update.
        cell.backgroundColor = VoxeetSDK.sharedInstance.isUserMuted(user.userID) ? UIColor.redColor() : UIColor.whiteColor()
        
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        
        // Mutes a user.
        let user = users[indexPath.row]
        VoxeetSDK.sharedInstance.muteUser(user.userID, mute: !VoxeetSDK.sharedInstance.isUserMuted(user.userID))
        
        // Update background color.
        if let cell = tableView.cellForRowAtIndexPath(indexPath) {
            cell.backgroundColor = VoxeetSDK.sharedInstance.isUserMuted(user.userID) ? UIColor.redColor() : UIColor.whiteColor()
        }
    }
}

/*
 *  MARK: - Conference tableView cell
 */

class ConferenceTableViewCell: UITableViewCell {
    // UI.
    @IBOutlet weak var userLabel: UILabel!
    @IBOutlet weak var userPhoto: UIImageView!
    @IBOutlet weak var angleSlider: UISlider!
    @IBOutlet weak var distanceSlider: UISlider!
    
    /*
     *  MARK: Action
     */
    
    @IBAction func angle(sender: UISlider) {
        // Debug.
        print("::DEBUG:: <angle> \(sender.value)")
        
        // Setting user position.
        VoxeetSDK.sharedInstance.setUserAngle(userLabel.text!, angle: sender.value)
    }
    
    @IBAction func distance(sender: UISlider) {
        // Debug.
        print("::DEBUG:: <distance> \(sender.value)")
        
        // Setting user position.
        VoxeetSDK.sharedInstance.setUserDistance(userLabel.text!, distance: sender.value)
    }
}