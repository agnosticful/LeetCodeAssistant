import UIKit

class SignInViewController: UIViewController {
    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var signInButton: UIButton!
    @IBOutlet weak var signInActivityIndicator: UIActivityIndicatorView!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        signInButton.isEnabled = false
        signInButton.isHidden = false
        signInActivityIndicator.isHidden = true
    }

    @IBAction func onUsernameOrPasswordTextFieldValueChanged(_ sender: UITextField) {
        let username = usernameTextField.text!.trimmingCharacters(in: .whitespaces)
        let password = passwordTextField.text!.trimmingCharacters(in: .whitespaces)
        
        signInButton.isEnabled = !username.isEmpty && !password.isEmpty
    }
    
    @IBAction func onSignInButtonTapped(_ sender: UIButton) {
        let username = usernameTextField.text!
        let password = passwordTextField.text!
        
        usernameTextField.isEnabled = false
        passwordTextField.isEnabled = false
        signInButton.isHidden = true
        signInActivityIndicator.isHidden = false
        
        LeetCodeProblemRepository.shared.signIn(username: username, password: password) { (sessionToken, error) in            
            guard let error = error else {
                let sessionToken = sessionToken!
                
                DispatchQueue.main.async {
                    LeetCodeSessionStorage.shared.save(sessionToken)
                    
                    self.performSegue(withIdentifier: "SignIn", sender: self)
                }
                
                return
            }
            
            DispatchQueue.main.async {
                self.usernameTextField.isEnabled = true
                self.passwordTextField.isEnabled = true
                self.signInButton.isHidden = false
                self.signInActivityIndicator.isHidden = true
            }

            if error is LeetCodeSigninError {
                let error = error as! LeetCodeSigninError

                if error == .wrongEmailOrPassword {
                    DispatchQueue.main.async {
                        let alert = UIAlertController(title: "Log in is failed", message: "The email/username or password you inputted are wrong.", preferredStyle: .alert)

                        alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))

                        self.present(alert, animated: true)
                    }
                    
                    return
                }
            }
            
            debugPrint(error)
        }
    }
}
