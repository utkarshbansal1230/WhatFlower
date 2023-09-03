import UIKit
import CoreML
import Vision
import Alamofire
import SwiftyJSON
import SDWebImage

import LocalAuthentication

class ViewController: UIViewController , UIImagePickerControllerDelegate , UINavigationControllerDelegate {
    
 let wikipediaUrl = "https://en.wikipedia.org/w/api.php"
    let imagePicker = UIImagePickerController()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        imagePicker.delegate = self
        imagePicker.allowsEditing = true
       
        imagePicker.sourceType = .photoLibrary
    }
    
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let userPickedImage = info[UIImagePickerController.InfoKey.editedImage] as? UIImage{
        
        guard let ciImage = CIImage(image: userPickedImage)
            else
            {
                fatalError("error")
            }
            
            detect(image: ciImage)
        
        }
        
        imagePicker.dismiss(animated: true , completion: nil)
        
    }
    
    func detect(image : CIImage)  {
        // changes
        guard let Model = try? VNCoreMLModel(for: flowerIdentifier_1().model)
                else
        {
            fatalError("error")
        }
        
        let request = VNCoreMLRequest(model: Model) { request, error in
            guard let classification = request.results?.first as? VNClassificationObservation
                    else
            {
                fatalError("error")
            }
       
            self.navigationItem.title = classification.identifier
            self.requestInfo(flowerName: classification.identifier)
        }
        
        let handler = VNImageRequestHandler(ciImage: image)
        do{
     try   handler .perform([request])
        }
        
        catch
        {
            print("error")
        }
    }
    
    func requestInfo(flowerName : String) {
        
        let parameters : [String:String] = [
        "format" : "json",
        "action" : "query",
        "prop" : "extracts|pageimages",
        "exintro" : "",
        "explaintext" : "",
        "titles" : flowerName,
        "indexpageids" : "",
        "redirects" : "1",
        "pithumbsize" : "500"
        ]
        
        
        Alamofire.request(wikipediaUrl, method: .get, parameters: parameters).responseJSON { (response) in
            
            if response.result.isSuccess
            {
                print("done")
                print(response)
                
                let flowerJson : JSON = JSON(response.result.value!)
                
                let pageid = flowerJson["query"]["pageids"][0].stringValue
                
                let flowerDescrip = flowerJson["query"]["pages"][pageid]["extract"].stringValue
                
                let flowerImageURl = flowerJson["query"]["pages"][pageid]["thumbnail"]["source"].stringValue
                
                self.imageView.sd_setImage(with: URL(string: flowerImageURl))
                
                self.label.text = flowerDescrip
            }
        }
    }
    
    @IBOutlet weak var imageView: UIImageView!
    
    @IBOutlet weak var label: UILabel!
    
    @IBAction func cameraTapped(_ sender: UIBarButtonItem) {
        
        
        let context = LAContext()
        var error : NSError? = nil
        
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
        {
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: "please authorize") { [weak self]success , error in
                
                DispatchQueue.main.async {
                    guard success , error == nil
                            else
                    {
                        
                        let alert = UIAlertController(title: "unavailable", message: "cant use", preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "dismiss", style: .cancel , handler: nil))
                        self?.present(alert,animated: true)
                                
                        return
                    }
                    
                    self?.present(self!.imagePicker , animated: true, completion: nil)
                }

            }
        }
            
        else
        {
            let alert = UIAlertController(title: "unavailable", message: "cant use", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "dismiss", style: .cancel , handler: nil))
            present(alert,animated: true)
        }
        
        
       
        
    }

}

