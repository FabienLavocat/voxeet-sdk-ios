//
//  ConferenceTableViewCell.swift
//  VoxeetSDK Sample
//
//  Created by Coco on 31/08/16.
//  Copyright © 2016 Corentin Larroque. All rights reserved.
//

import Foundation
import VoxeetSDK

class ConferenceTableViewCell: UITableViewCell {
    // UI.
    @IBOutlet weak var userLabel: UILabel!
    @IBOutlet weak var userPhoto: UIImageView!
    @IBOutlet weak var angleSlider: UISlider!
    @IBOutlet weak var distanceSlider: UISlider!
    @IBOutlet weak var userVideoView: VideoRenderer!
    
    // Data.
    var currentUser: User!
    
    /*
     *  MARK: Set Up
     */
    
    func setUp(_ currentUser: User) {
        self.currentUser = currentUser
        
        // Cell label.
        if let name = currentUser.name {
            userLabel.text = name
        } else {
            userLabel.text = currentUser.userID
        }
        
        // Cell avatar.
        if let avatarURL = currentUser.avatarUrl {
            let imgURL: URL = URL(string: avatarURL)!
            let request: URLRequest = URLRequest(url: imgURL)
            let task = URLSession.shared.dataTask(with: request, completionHandler: { data, response, error in
                if error == nil {
                    if let data = data {
                        DispatchQueue.main.async {
                            self.userPhoto.image = UIImage(data: data)
                        }
                    }
                } else {
                    // Debug.
                    print("::DEBUG:: <avatar> \(error?.localizedDescription)")
                }
            }) 
            task.resume()
        }
        
        // Setting user distance to 0.
        VoxeetSDK.sharedInstance.conference.setUserDistance(0, userID: currentUser.userID)
        
        // Slider update.
        let position = VoxeetSDK.sharedInstance.conference.getUserPosition(userID: currentUser.userID)
        self.angleSlider.setValue(Float(position.angle), animated: false)
        self.distanceSlider.setValue(Float(position.distance), animated: false)
        
        // Background update.
        self.backgroundColor = VoxeetSDK.sharedInstance.conference.isUserMuted(userID: currentUser.userID) ? UIColor.red : UIColor.white
    }
    
    /*
     *  MARK: Action
     */
    
    @IBAction func angle(_ sender: UISlider) {
        // Debug.
        print("::DEBUG:: <angle> \(sender.value)")
        
        // Setting user position.
        VoxeetSDK.sharedInstance.conference.setUserAngle(Double(sender.value), userID: currentUser.userID)
    }
    
    @IBAction func distance(_ sender: UISlider) {
        // Debug.
        print("::DEBUG:: <distance> \(sender.value)")
        
        // Setting user position.
        VoxeetSDK.sharedInstance.conference.setUserDistance(Double(sender.value), userID: currentUser.userID)
    }
}
