import Foundation
import reddift

// https://cloud.google.com/natural-language/docs/reference/rest/
// https://language.googleapis.com/$discovery/rest?version=v1beta2
// https://developers.google.com/apis-explorer/?hl=en_GB#p/language/v1/language.documents.analyzeEntities?fields=entities(name%252Ctype)&_h=2&resource=%257B%250A++%2522document%2522%253A+%250A++%257B%250A++++%2522content%2522%253A+%2522Gavin+you're+a+genius%2522%252C%250A++++%2522language%2522%253A+%2522en%2522%252C%250A++++%2522type%2522%253A+%2522PLAIN_TEXT%2522%250A++%257D%252C%250A++%2522encodingType%2522%253A+%2522UTF16%2522%250A%257D&

struct Entity {
  let word: String
  let type: String
}

class NLPService {
  func fetchNouns(content: String, completion: @escaping (Result<[Entity]>) -> Void) {
    let anonErrorResult = Result<[Entity]>(error: nil)
    
    guard let requestURL = NLPService.requestURL() else {
      completion(anonErrorResult)
      return
    }
    
    var request = URLRequest(url: requestURL)
    let session = URLSession.shared
    request.httpMethod = "POST"
    request.addValue("application/json", forHTTPHeaderField: "Content-Type")
    request.addValue("application/json", forHTTPHeaderField: "Accept")
    
    let requestParams = NLPService.requestParams(content: content)
    guard let data = try? JSONSerialization.data(withJSONObject: requestParams) else {
      completion(anonErrorResult)
      return
    }
    request.httpBody = data
    
    // Check encoding is correct.
    let requestParamsString = String(data: data, encoding: String.Encoding.utf8)!
    print("Request: \(String(describing: requestParamsString))")

    let task = session.dataTask(with: request, completionHandler: {data, response, error -> Void in
      if let error = error {
        completion(Result<[Entity]>(error: error as NSError))
        return
      }
      
      guard let data = data else {
        completion(anonErrorResult)
        return
      }
      
      guard let json = try? JSONSerialization.jsonObject(with: data, options: []) else {
        completion(anonErrorResult)
        return
      }
      
      // Example JSON :
      /*
       {
         "entities": [
           {
             "name": "Gavin",
             "type": "PERSON"
           },
           {
             "name": "genius",
             "type": "OTHER"
           }
         ]
       }
       */
      guard let jsonDict = json as? [String: Any] else {
        completion(anonErrorResult)
        return
      }
      
      guard let jsonEntities = jsonDict["entities"] as? [[String:String]] else {
        completion(anonErrorResult)
        return
      }
      
      let entities = jsonEntities.flatMap({ (entity) -> Entity in
        return Entity(word: entity["name"]!, type: entity["type"]!)
      })
      
      let successResult = Result<[Entity]>(value: entities)
      completion(successResult)
    })
    
    task.resume()
  }
  
  private class func requestParams(content: String) -> [String:Any] {
    let params: [String:Any] = [
      "document": [
        "content": content,
        "language": "en",
        "type": "PLAIN_TEXT"
      ],
      "encodingType": "UTF16"
    ]
    return params
  }
  
  private class func requestURL() -> URL? {
    guard let apiKey = self.googleAPIKey() else {
      return nil
    }

    let requestURLString = "https://language.googleapis.com/v1/documents:analyzeEntities?fields=entities(name%2Ctype)&key=\(apiKey)"
    let requestURL = URL(string: requestURLString)
    return requestURL
  }
  
  private class func googleAPIKey() -> String? {
    guard let url = Bundle.main.url(forResource: "GoogleService-Info", withExtension: "plist") else {
      return nil
    }

    guard let data = try? Data(contentsOf: url) else {
      return nil
    }
    
    guard let datasourceDictionary = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil) as! [String:Any] else {
      return nil
    }
    
    guard let apiKey = datasourceDictionary["API_KEY"] as! String? else {
      return nil
    }
    
    return apiKey;
  }
}
