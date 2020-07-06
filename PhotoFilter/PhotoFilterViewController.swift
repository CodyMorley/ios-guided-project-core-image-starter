import UIKit
import CoreImage
import Photos
import CoreImage.CIFilterBuiltins


class PhotoFilterViewController: UIViewController {
    //MARK: Properties
	@IBOutlet weak var brightnessSlider: UISlider!
	@IBOutlet weak var contrastSlider: UISlider!
	@IBOutlet weak var saturationSlider: UISlider!
	@IBOutlet weak var imageView: UIImageView!
	
    let context = CIContext(options: nil)
    var originalImage: UIImage? {
        didSet {
            //We want to scale down the image to make the filter render more easily and increase performance.
            guard let image = originalImage else { return }
            
            var scaledSize = imageView.bounds.size
            let scale = UIScreen.main.scale
            
            scaledSize = CGSize(width: scaledSize.width * scale,
                                height: scaledSize.height * scale)
            
            let scaledImage = image.imageByScaling(toSize: scaledSize)
            self.scaledImage = scaledImage
        }
    }
    var scaledImage: UIImage? {
        didSet {
            imageView.image = scaledImage
        }
    }
    
    
    // MARK: Life Cycles
	override func viewDidLoad() {
		super.viewDidLoad()
        originalImage = imageView.image
	}
    
	
	// MARK: Actions
	@IBAction func choosePhotoButtonPressed(_ sender: Any) {
        presentImagePicker()
	}
	
	@IBAction func savePhotoButtonPressed(_ sender: UIButton) {
        guard let originalImage = originalImage else { return }
        
        let filteredImage = image(byFiltering: originalImage)
        
        //Request user permission to add photos to their library
        PHPhotoLibrary.requestAuthorization { status in
            guard status == .authorized else {
                NSLog("User has not authorized permissions for Photo Library usage.")
                //In production you would present an alert allowing the user to change this setting again.
                return
            }
            
            PHPhotoLibrary.shared().performChanges({
                PHAssetCreationRequest.creationRequestForAsset(from: filteredImage)
            }) { success, error in
                if let error = error {
                    NSLog("Error saving Photo Asset. Here's what went wrong: \(error) \(error.localizedDescription)")
                    return
                }
            }
        }
	}
	

	// MARK: Slider events
	@IBAction func brightnessChanged(_ sender: UISlider) {
        updateImage()
	}
	
	@IBAction func contrastChanged(_ sender: Any) {
        updateImage()
	}
	
	@IBAction func saturationChanged(_ sender: Any) {
        updateImage()
	}
    
    
    // MARK: Image Filtering
    private func updateImage() {
        if let scaledImage = scaledImage {
            imageView.image = image(byFiltering: scaledImage)
        } else {
            imageView.image = nil
        }
    }
    
    private func image(byFiltering image: UIImage) -> UIImage {
        // UIImage -> CGImage -> CIImage "recipe"
        guard let cgImage = image.cgImage else { return image }
        
        let ciImage = CIImage(cgImage: cgImage)
        
        // Create the color controls filter.
        // There are two ways to do this but the second way presented isn't always operable.
        let filter = CIFilter(name: "CIColorControls")!
        filter.setValue(ciImage, forKey: "inputImage")
        filter.setValue(saturationSlider.value, forKey: "inputSaturation")
        filter.setValue(brightnessSlider.value, forKey: "inputBrightness")
        filter.setValue(contrastSlider.value, forKey: "inputContrast")
        
        let filter2 = CIFilter.colorControls()
        filter2.inputImage = ciImage
        filter2.saturation = saturationSlider.value
        filter2.brightness = brightnessSlider.value
        filter2.contrast = contrastSlider.value
        
        guard let outputImage = filter.outputImage else { return image }
        
        // This is where image filtering happens. The GPU performs the filter on a CIContext
        guard let outputCGImage = context.createCGImage(outputImage, from: outputImage.extent) else { return image }
        
        return UIImage(cgImage: outputCGImage)
    }
    
    
    // MARK: - Methods -
    func presentImagePicker() {
        //make sure the photo library is available
        guard UIImagePickerController.isSourceTypeAvailable(.photoLibrary) else {
            NSLog("The photo library is not available.")
            return
        }
        
        let imagePicker = UIImagePickerController()
        imagePicker.sourceType = .photoLibrary
        imagePicker.delegate = self
        present(imagePicker, animated: true, completion: nil)
    }
}

extension PhotoFilterViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let selectedImage = info[.originalImage] as? UIImage {
            originalImage = selectedImage
        }
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
}



