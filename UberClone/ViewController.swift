/**
* Copyright (c) 2015-present, Parse, LLC.
* All rights reserved.
*
* This source code is licensed under the BSD-style license found in the
* LICENSE file in the root directory of this source tree. An additional grant
* of patent rights can be found in the PATENTS file in the same directory.
*/

import UIKit
import Parse

class ViewController: UIViewController {

    @IBOutlet var usernameTextField: UITextField!
    @IBOutlet var passwordTextField: UITextField!
    @IBOutlet var driverOrRiderSwitch: UISwitch!
    @IBOutlet var logInOrSignUpButton: UIButton!
    @IBOutlet var logInOrSignUpLabel: UILabel!
    var loggingIn = true
    var driverOrRider: String {
        return driverOrRiderSwitch.isOn ? "Rider" : "Driver"
    }
 
    @IBAction func logInOrSignUp(_ sender: UIButton) {
        
        if usernameTextField.text == "" || passwordTextField.text == "" {
            self.createAlert(title: "Invalid username/password", message: "Please enter your username and password")
            return
        }
        
        if loggingIn {
            PFUser.logInWithUsername(inBackground: usernameTextField.text!, password: passwordTextField.text!, block: { [unowned self] (user, error) in

                if error != nil {
                    print(error.debugDescription)
                    var message = "Please try again later"
                    if let errorMessage = (error as! NSError).userInfo["error"] as? String {
                        message = errorMessage
                    }
                    PFUser.logOut()
                    self.createAlert(title: "Log in Error", message: message)
                }
                else {
                    self.performSegue(withIdentifier: "to\(self.driverOrRider)", sender: self)
                }
            })
        }
        else {
            let newUser = PFUser()
            newUser["username"] = usernameTextField.text!
            newUser["password"] = passwordTextField.text!
            newUser["memberType"] = driverOrRider
            newUser.signUpInBackground(block: { [unowned self] (success, error) in
                if error != nil {
                    var message = "Please try again later"
                    if let errorMessage = (error as! NSError).userInfo["error"] as? String {
                        message = errorMessage
                    }
                    PFUser.logOut()
                    self.createAlert(title: "Parse Error", message: message)
                }
                
                if success {
                    self.performSegue(withIdentifier: "to\(self.driverOrRider)", sender: self)
                }
            })
        }
    }
    
    @IBAction func changeLogInOrSignUp(_ sender: UIButton) {
        if loggingIn {
            loggingIn = false
            sender.setTitle("Log in", for: [])
            logInOrSignUpButton.setTitle("Sign up", for: [])
            logInOrSignUpLabel.text = "Already a member?"
            
        }
        else {
            loggingIn = true
            sender.setTitle("Sign up", for: [])
            logInOrSignUpButton.setTitle("Log in", for: [])
            logInOrSignUpLabel.text = "Not a member?"
        }
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.navigationController?.navigationBar.isHidden = true
        print(PFUser.current()?.username as Any)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        self.navigationController?.navigationBar.isHidden = false
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

extension UIViewController {
    func createAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: {
            action in
            alert.dismiss(animated: true, completion: nil)
        }))
        self.present(alert, animated: true, completion: nil)
    }
}
