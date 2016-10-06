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
    @IBOutlet weak var screenShareView: VideoRenderer!
    @IBOutlet weak var ownCameraView: VideoRenderer!
    
    // Current conference ID.
    var conferenceID: String?
    
    // Users' data.
    var users = [User]()
    
    /*
     *  MARK: Load / Unload
     */
    
    override func viewDidLoad() {
        // Setting label.
        conferenceIDLabel.text = conferenceID
        
        // Joining / Launching demo.
        if let confID = conferenceID {
            // Conference media delegate.
            VoxeetSDK.sharedInstance.conference.mediaDelegate = self
            
            // Joining Conference.
            VoxeetSDK.sharedInstance.conference.join(conferenceAlias: confID) { (error) in
                if error != nil {
                    // Debug.
                    print("::DEBUG:: <joinConference> \(error)")
                    
                    self.dismiss(animated: true, completion: nil)
                }
            }
        } else {
            conferenceIDLabel.text = "Demo"
            
            // Creating Voxeet demo conference.
            VoxeetSDK.sharedInstance.conference.createDemo { (error) in
                if error != nil {
                    // Debug.
                    print("::DEBUG:: <createDemoConference> \(error)")
                    
                    self.dismiss(animated: true, completion: nil)
                }
            }
        }
        
        // Conference delegate.
        VoxeetSDK.sharedInstance.conference.delegate = self
    }
    
    deinit {
        // Debug.
        print("::DEBUG:: <deinitConference>")
    }
    
    /*
     *  MARK: Action
     */
    
    @IBAction func sendBroadcastMessage(_ sender: AnyObject) {
        // Alert view.
        let alertController = UIAlertController(title: "Send Message", message: "Please input the message:", preferredStyle: .alert)
        
        // Alert actions.
        let confirmAction = UIAlertAction(title: "Send", style: .default) { (_) in
            if let textField = alertController.textFields?[0],
                let message = textField.text {
                // Sending a broadcast message.
                VoxeetSDK.sharedInstance.conference.sendBroadcastMessage(message, completion: { (error) in
                    // Debug.
                    print("::DEBUG:: <sendBroadcastMessage> \(error)")
                })
            }
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (_) in }
        
        // Alert textField.
        alertController.addTextField { (textField) in
            textField.placeholder = "Message"
            textField.clearButtonMode = .whileEditing
        }
        
        alertController.addAction(confirmAction)
        alertController.addAction(cancelAction)
        self.present(alertController, animated: true, completion: nil)
    }
    
    @IBAction func switchDeviceSpeaker(_ button: UIButton) {
        VoxeetSDK.sharedInstance.conference.switchDeviceSpeaker()
        
        button.isSelected = !button.isSelected
    }
    
    @IBAction func hangUp(_ sender: AnyObject) {
        VoxeetSDK.sharedInstance.conference.leave { (error) in
            // Debug.
            print("::DEBUG:: <leaveConference> \(error)")
            
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    @IBAction func switchCamera(_ sender: AnyObject) {
        VoxeetSDK.sharedInstance.conference.flipCamera()
    }
}

/*
 *  MARK: - Voxeet SDK conference delegate
 */

extension Conference: VTConferenceDelegate {
    func userJoined(userID: String, userInfo: [String: Any]) {
        users.append(User(userID: userID, externalID: userInfo["externalId"] as? String, avatarUrl: userInfo["avatarUrl"] as? String, name: userInfo["name"] as? String))
        tableView.reloadData()
    }
    
    func userLeft(userID: String, userInfo: [String: Any]) {
        users = users.filter({ $0.userID != userID })
        tableView.reloadData()
    }
    
    func messageReceived(userID: String, userInfo: [String: Any], message: String) {
        if let name = users.filter({ $0.userID == userID }).first?.name {
            broadcastMessageTextView.text = "\(name): \(message)"
        } else {
            broadcastMessageTextView.text = "\(userID): \(message)"
        }
    }
}

/*
 *  MARK: - Voxeet SDK conference media delegate
 */

extension Conference: VTConferenceMediaDelegate {
    func streamAdded(stream: MediaStream, userID: String) {
        if let ownUserID = VoxeetSDK.sharedInstance.conference.getOwnUser()?.userID , ownUserID == userID {
            // Attaching own user's video stream.
            ownCameraView.isHidden = false
            VoxeetSDK.sharedInstance.conference.attachMediaStream(stream, renderer: ownCameraView)
        } else if let index = self.users.index(where: { $0.userID == userID }), let cell = self.tableView.cellForRow(at: IndexPath(row: index, section: 0)) as? ConferenceTableViewCell {
            // Attaching user's video stream.
            cell.userVideoView.isHidden = false
            VoxeetSDK.sharedInstance.conference.attachMediaStream(stream, renderer: cell.userVideoView)
        }
    }
    
    func streamRemoved(userID: String) {
        if let index = self.users.index(where: { $0.userID == userID }), let cell = self.tableView.cellForRow(at: IndexPath(row: index, section: 0)) as? ConferenceTableViewCell {
            cell.userVideoView.isHidden = true
        }
    }
    
    func streamScreenShareAdded(stream: MediaStream, userID: String) {
        // Attaching a video stream to a renderer.
        VoxeetSDK.sharedInstance.conference.attachMediaStream(stream, renderer: screenShareView)
    }
    
    func streamScreenShareRemoved(userID: String) {
    }
}

/*
 *  MARK: - Conference tableView dataSource & delegate
 */

extension Conference: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return users.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "tableViewCell", for: indexPath) as! ConferenceTableViewCell
        
        // Getting the current user.
        let user = users[(indexPath as NSIndexPath).row]
        
        // Setting up the cell.
        cell.setUp(user)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        // Mutes a user.
        let user = users[(indexPath as NSIndexPath).row]
        VoxeetSDK.sharedInstance.conference.muteUser(!VoxeetSDK.sharedInstance.conference.isUserMuted(userID: user.userID), userID: user.userID)
        
        // Update background color.
        if let cell = tableView.cellForRow(at: indexPath) {
            cell.backgroundColor = VoxeetSDK.sharedInstance.conference.isUserMuted(userID: user.userID) ? UIColor.red : UIColor.white
        }
    }
}
