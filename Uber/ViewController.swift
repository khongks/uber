//
//  ViewController.swift
//  Uber
//
//  Created by khongks on 26/02/2016.
//  Copyright © 2016 spocktech. All rights reserved.
//

import UIKit
import Parse

class ViewController: UIViewController, UITextFieldDelegate {

    var isSignUp = true
    
    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var whoSwitch: UISwitch!
    @IBOutlet weak var submitButton: UIButton!
    @IBOutlet weak var toggleButton: UIButton!
    @IBOutlet weak var riderLabel: UILabel!
    @IBOutlet weak var driverLabel: UILabel!

    @IBAction func submit(sender: AnyObject) {
        if isSignUp {
            signUp()
        } else {
            login()
        }
    }
    
    @IBAction func toggle(sender: AnyObject) {
        
        if isSignUp {
            isSignUp = false
            submitButton.setTitle("Login", forState: .Normal)
            whoSwitch.alpha = 0.0
            riderLabel.alpha = 0.0
            driverLabel.alpha = 0.0
        } else {
            isSignUp = true
            submitButton.setTitle("Sign Up", forState: .Normal)
            whoSwitch.alpha = 1.0
            riderLabel.alpha = 1.0
            driverLabel.alpha = 1.0
        }
    }
    
    func check() -> (Bool, String, String) {
        if let username = usernameTextField.text {
            if username != "" {
                if let password = passwordTextField.text {
                    if password != "" {
                        return (true, username, password)
                    }
                }
            }
        }
        return (false, "", "")
    }
    
    func signUp() {
        
        let (isOk, username, password) = check()
        if isOk {
            let user = PFUser()
            user.username = username
            user.password = password
            user["isDriver"] = whoSwitch.on
            
            user.signUpInBackgroundWithBlock({ (isOK, error) -> Void in
                if let error = error {
                    let errorString = error.userInfo["NSLocalizedDescription"] as? String
                    self.displayAlert("Signup Error", message: errorString!)
                } else {
                    if self.whoSwitch.on {
                        self.performSegueWithIdentifier("loginDriver", sender: self)
                    } else {
                        self.performSegueWithIdentifier("loginRider", sender: self)
                    }
                }
            })
            
        } else {
            displayAlert("Missing Field(s)", message: "Please enter username/password")
        }
    }
    
    func login() {
        let (isOk, username, password) = check()
        if isOk {
            PFUser.logInWithUsernameInBackground(username, password: password, block: { (user, error) -> Void in
                if let error = error {
                    let errorString = error.userInfo["NSLocalizedDescription"] as? String
                    self.displayAlert("Login Error", message: errorString!)
                } else {
                    if user!["isDriver"]! as! Bool == true {
                        self.performSegueWithIdentifier("loginDriver", sender: self)
                    } else {
                        self.performSegueWithIdentifier("loginRider", sender: self)
                    }
                }
            })
        } else {
            displayAlert("Missing Field(s)", message: "Please enter username/password")
        }
    }
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let backgroundImage = UIImageView(frame: UIScreen.mainScreen().bounds)
        backgroundImage.image = UIImage(named: "bg.jpeg")
        self.view.insertSubview(backgroundImage, atIndex: 0)
        
        usernameTextField.delegate = self
        passwordTextField.delegate = self
        
        let tapRecognizer = UITapGestureRecognizer(target: self, action: "dismissKeyboard")
        view.addGestureRecognizer(tapRecognizer)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func dismissKeyboard() {
        view.endEditing(true)
    }
    
    func displayAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .Alert)
        alert.addAction(UIAlertAction(title: "OK", style: .Default, handler: nil))
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    override func viewDidAppear(animated: Bool) {
        // PFUser.currentUser() may not be nil -> bug
        //if PFUser.currentUser()?.username != "" {
        if PFUser.currentUser() != nil {
            if PFUser.currentUser()!["isDriver"]! as! Bool == true {
                self.performSegueWithIdentifier("loginDriver", sender: self)
            } else {
                self.performSegueWithIdentifier("loginRider", sender: self)
            }
        }
    }

}

