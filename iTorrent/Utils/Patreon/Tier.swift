//
//  Tier.swift
//  AltStore
//
//  Created by Riley Testut on 8/21/19.
//  Copyright © 2019 Riley Testut. All rights reserved.
//

import Foundation

extension PatreonAPI {
    struct TierResponse: Decodable {
        struct Attributes: Decodable {
            var title: String
        }
        
        struct Relationships: Decodable {
            struct Benefits: Decodable {
                var data: [BenefitResponse]
            }
            
            var benefits: Benefits
        }
        
        var id: String
        var attributes: Attributes
        
        var relationships: Relationships
    }
}

struct Tier {
    struct Rewards {
        public static let fullVersion = ["4071208", "4071210"]
    }
    
    var name: String
    var identifier: String
    
    var benefits: [Benefit] = []
    
    init(response: PatreonAPI.TierResponse) {
        self.name = response.attributes.title
        self.identifier = response.id
        self.benefits = response.relationships.benefits.data.map(Benefit.init(response:))
    }
}
