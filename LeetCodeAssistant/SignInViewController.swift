import UIKit

class SignInViewController: UIViewController {
    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var signInButton: UIButton!
    @IBOutlet weak var signInActivityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var wrapperView: UIView!
    @IBOutlet weak var wrapperViewBottomConstraint: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        signInButton.isEnabled = false
        signInButton.isHidden = false
        signInActivityIndicator.isHidden = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        NotificationCenter.default.addObserver(self, selector: #selector(onKeyboardShown(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onKeyboardHidden(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    @IBAction func onUsernameOrPasswordTextFieldValueChanged(_ sender: UITextField) {
        let username = usernameTextField.text!.trimmingCharacters(in: .whitespaces)
        let password = passwordTextField.text!.trimmingCharacters(in: .whitespaces)
        
        signInButton.isEnabled = !username.isEmpty && !password.isEmpty
    }
    
    @IBAction func onUsernamePrimaryActionTriggered(_ sender: UITextField) {
        passwordTextField.becomeFirstResponder()
    }

    @IBAction func onPasswordPrimaryActionTriggered(_ sender: UITextField) {
        signIn()
    }
    
    @IBAction func onSignInButtonTapped(_ sender: UIButton) {
        signIn()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    @objc func onKeyboardShown(_ notification: Notification?) {
        self.view.layoutIfNeeded()

        guard let rect = (notification?.userInfo?[UIResponder.keyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue,
            let duration = notification?.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval else { return }
        
        wrapperViewBottomConstraint.constant = -rect.size.height
        
        UIView.animate(withDuration: duration) {
            self.view.layoutIfNeeded()
        }
    }
    
    @objc func onKeyboardHidden(_ notification: Notification?) {
        self.view.layoutIfNeeded()

        guard let duration = notification?.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval else { return }
        
        wrapperViewBottomConstraint.constant = 0
        
        UIView.animate(withDuration: duration) {
            self.view.layoutIfNeeded()
        }
    }
    
    private func signIn() {
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
