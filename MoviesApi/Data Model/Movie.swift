//
//  Movie.swift
//  MoviesApi
//
//  Created by Kenan Mazalovic on 10/1/20.
//

import Foundation


struct MovieResponse:Decodable {
    var page:Int
    var total_results:Int
    var total_pages:Int
    var results:[MovieDetail]
}

struct MovieDetail:Decodable {
    var poster_path:String?
    var title:String
    var release_date:String?
    var overview:String?
    
}
