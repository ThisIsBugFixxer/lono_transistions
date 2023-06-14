//
//  NetworkAPITemplateHandler.swift
//  lono transistions
//
//  Created by Priyam Mehta on 12/06/23.
//

/// Mark: JSON template generator
///  transistion template only
///
///  [
/// {
/// "template_name":"template 1",
/// "n_images":2,
/// "n_duration":30000,
/// "frames":[
///  {
///    "duration":10000,
///    "transion":"LR|RL|TB",
///    "transition_duration":12,
///    "isBgToBeRemoved":false
///  },
/// {
///    "duration":10000,
///    "transion":"LR|RL|TB",
///    "transition_duration":12,
///    "isBgToBeRemoved":false
///  },
/// ]
/// },
///
/// }
/// ]


import Foundation

//struct newTemplateStructure: Codable {
//    var template_name: String
//    var n_images: Int
//    var bg_duration: Int
//    var frames: [frame]
//}
//
//struct frame: Codable {
//    var transition: String
//    var transition_duration: Int
//    var isBgToBeRemoved: Bool
//}


struct TemplateCategory: Codable {
    var category_title: String
    var category_slug: String
    var Priority: Int
    var Version: Double
    var Templates: [Template]
}

struct Template: Codable {
    var template_name: String
    var display_url: String
    var Order: Int
    var Version: Double
    var n_images: Int
    var bg_duration: Int
    var frames: [Frame]
}

struct Frame: Codable {
    var transition: String
    var transition_duration: Double
    var isBgToBeRemoved: Bool
    var fg_frame_index: Int
}

class templateGenerator {
    static let shared = templateGenerator()
    
    var templateCategory = [TemplateCategory]()
    var template = [Template]()
    
    func JSONExtractor(urlString: String) -> [TemplateCategory]? {
        
            if let url = URL(string: urlString) {
                if let data = try? Data(contentsOf: url) {
                    print("=== data is \(data)")
                    
                    let parsedData = self.parse(json: data)
                   
                    if parsedData.isEmpty {
                        return nil
                    }
                    
                    return parsedData
                }
            }
        return nil
    }
    
    
    func parse(json: Data) -> [TemplateCategory] {
        
//       let json = """
//        [
//            {
//                "template_name": "template 1",
//                "n_images": 5,
//                "bg_duration": 1,
//                "frames": [
//                    {
//                        "transition": "LeftToRight",
//                        "transition_duration": 1,
//                        "isBgToBeRemoved": true
//                    },
//                    {
//                        "transition": "BottomToTop",
//                        "transition_duration": 1,
//                        "isBgToBeRemoved": true
//                    }
//                ]
//            }
//        ]
//    """.data(using: .utf8)!


        do {
            let decoder = JSONDecoder()
            
            let jsonTemplates = try decoder.decode([TemplateCategory].self, from: json)
            var template_ = jsonTemplates.first
                print("=== final parse is \(template_)")
                
            for templateStructure in template_!.Templates.first!.frames {
                let frames = templateStructure
                
                                print("=== frames are \(frames)")
                            }
                
                return jsonTemplates
            
            
        }
        catch {
            print("=== error in decoding \(error)")
        }
        return []
    }
    
    ///  Mark: Testing APIs
    ///
    
    func JSONExtractorTesting(fileName: String) -> [TemplateCategory] {
        if let fileURL = Bundle.main.url(forResource: fileName, withExtension: "json") {
            if let data = try? Data(contentsOf: fileURL) {
                print("=== data is \(data)")
                return parse(json: data)
            }
        }
        return []
    }

  
}
