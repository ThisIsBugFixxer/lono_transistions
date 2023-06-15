//
//  DynamicViewController.swift
//  lono transistions
//
//  Created by Priyam Mehta on 15/06/23.
//



import UIKit
import AVFoundation


struct CategoryTemplate {
    let title: String
    let templates: [Template]
}




class DynamicViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    
    
    @IBOutlet weak var tableView: UITableView!
    
//    let categories: [Category] = [
//        Category(name: "Category 1", data: ["Data 1-1", "Data 1-2", "Data 1-3"]),
//        Category(name: "Category 2", data: ["Data 2-1", "Data 2-2"]),
//        Category(name: "Category 3", data: ["Data 3-1", "Data 3-2", "Data 3-3", "Data 3-4"])
//    ]
    
    var categoriesList = [CategoryTemplate]()
    
    var selectedImages: [UIImage] = []
    var vc = VideoCreatorGeneralised()
    var lastPath: String? = nil
    
    var pickerSelectionLimit = 10
    
    var fgBGRemoved = [Bool]()
    var fgFramesRemoved = [Int]()
    
    //    override func viewDidLoad() {
    //        super.viewDidLoad()
    //
    //        // Do any additional setup after loading the view.
    //    }
    
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destination.
     // Pass the selected object to the new view controller.
     }
     */
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.UISetUpFromJSON()
        
        tableView.dataSource = self
        tableView.register(UINib(nibName: "CustomTableViewCell", bundle: nil), forCellReuseIdentifier: "CustomCell")
        
        //           tableView.frame = view.bounds
//        tableView.dataSource = self
        //           view.addSubview(tableView)
        
        //           tableView.register(self, forCellReuseIdentifier: "GroupedCell")
        
    }
    
    // MARK: - UITableViewDataSource
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return categoriesList.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if categoriesList[section].templates.count / 2 == 0 {
            return 1
        }
        
        return categoriesList[section].templates.count / 2 // Divide by 2 to display 2 cells per row
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CustomCell", for: indexPath) as! CustomTableViewCell
        
        let category = categoriesList[indexPath.section]
        let startIndex = indexPath.row * 2
        let endIndex = min(startIndex + 1, category.templates.count - 1)
        
        let data1 = category.templates[startIndex]
        let data2 = category.templates[endIndex]

        cell.titleLabel1.text = data1.template_name
        cell.titleLabel2.text = data2.template_name
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return categoriesList[section].title
    }
    
    
    /// MARK: JSON handlers
    ///
    ///
    
    func UISetUpFromJSON() {
        let templateGenerator = templateGenerator.shared
        
        let newTemplatesList = templateGenerator.JSONExtractorTesting(fileName: "jsontestFile")
        
        /// only for 1 template
        
        let templateCat = newTemplatesList
        
        for templateCatList in templateCat {
            self.categoriesList.append(CategoryTemplate(title: templateCatList.category_title, templates: templateCatList.Templates))
        }
    }
    
    func transsitionConverter(trn: String) -> Transistions {
        switch (trn) {
        case "LeftToRight":
            return Transistions.leftToRight
        case "RightToLeft":
            return Transistions.rightToLeft
        case "TopToBottom":
            return Transistions.topToBottom
        case "BottomToTop":
            return Transistions.bottomToTop
        default:
            return Transistions.bottomToTop
        }
    }
    
    func setTranssitionsFromURL() {
        
        self.vc.fgFPS = []
        self.vc.transistion = []
        self.fgBGRemoved = []
        self.fgFramesRemoved = []
        
        let templateGenerator = templateGenerator.shared
        
        let newTemplatesList = templateGenerator.JSONExtractorTesting(fileName: "jsontestFile")
        
        /// only for 1 template
        
        let template1 = newTemplatesList.first?.Templates.first!
        
//        self.counterLabel.text = "Data is \(template1)"
        
        
        
        /// Mark: Modifying the params
        ///
        
        pickerSelectionLimit = template1!.n_images
        self.vc.imagesPerSecond = Double(template1!.bg_duration)// might have to remoe this since it might casue errors, in code “imagesPerSecond”
        
        let br = BackgroundRemoval()
        
        for frame in template1!.frames {
            
            //            self.vc.fgFrameDur = template1?.frames.first?.transition_duration
            self.vc.fgFPS.append(frame.transition_duration)
            self.vc.transistion.append(transsitionConverter(trn: frame.transition))
            
            self.fgBGRemoved.append(frame.isBgToBeRemoved)
            self.fgFramesRemoved.append(frame.fg_frame_index)
            
            
        }
    }
    
    
    /// MARK: calls
    ///
    ///
    
    
    func makeTemplate(categoryIndex: Int,index: Int) {
        self.vc.bgPhotosArray = []
        self.vc.fgPhotosArray = []
        self.vc.transistion = []
        print("=== \(selectedImages) \(selectedImages.count)")
        
        
        self.setTranssitionsFromURL()
        
        self.vc.bgPhotosArray = selectedImages
//        self.vc.fgPhotosArray = selectedImages
        
//       self.vc.buildVideoFromImageArray() { url in
//
//           let u = url
//
//            print("=== initially \(u)")
//            sleep(1)
//
//            var timeoutCounter = 0
//
//            while (self.vc.hasExported && timeoutCounter<10){
//                print("=== waiting for export")
//                sleep(3)
//                timeoutCounter += 1
//            }
//           DispatchQueue.main.async {
//               self.playVideo(url: u)
//           }
//
//        }
        var br: BackgroundRemoval? = nil
        DispatchQueue.global(qos: .background).async {
            br = BackgroundRemoval()
        }
        
//        self.spinner.startAnimating()
        
        while br == nil {
            print("=== waiting")
            
            sleep(3)
                
        }
        
        for i in 0..<selectedImages.count {
//            self.vc.bgPhotosArray.append(self.vc.transparentImageAdapter())
            print("=== \(i)")
            
            if !self.fgBGRemoved[i] {
                
                self.vc.fgPhotosArray.append(self.vc.bgPhotosArray[self.fgFramesRemoved[i]])
            }
            else {
                self.vc.fgPhotosArray.append(br!.removeBackground(image: self.vc.bgPhotosArray[self.fgFramesRemoved[i]]) )
            }
        }
//        self.vc.asset = AVAsset(url: <#T##URL#>)
        self.vc.buildVideoFromImageArray(completion: { [self] url in
            self.vc.asset = AVAsset(url: self.vc.imageArrayToVideoURL as URL)
            self.vc.exportVideoWithAnimation()
            while !self.vc.hasExported {
                print("=== waiting to complete export")
                sleep(3)
            }
            self.vc.hasExported = false
//            self.vc.asset = AVAsset(url: self.vc.animatedVideoURL.absoluteURL!)
//            self.vc.exportVideoWithAnimation()
//
//            while !self.vc.hasExported {
//                print("=== waiting to complete export")
//                sleep(3)
//            }
            DispatchQueue.main.async {
//                self.spinner.stopAnimating()
//                self.counterLabel.text = "done"
            }
            
            
            DispatchQueue.main.async {
//                self.playVideo(url: self.vc.animatedVideoURL.absoluteURL!)
            }
            
        })
    }
}
