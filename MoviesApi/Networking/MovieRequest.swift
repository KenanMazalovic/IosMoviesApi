//
//  MovieRequest.swift
//  MoviesApi
//
//  Created by Kenan Mazalovic on 10/1/20.
//

import Foundation

enum MovieError:Error {
    case noDataAvailable
    case canNotProcessData
}

struct MovieRequest {
    let resourceURL:URL
    init(movieName: String, page: Int) {
        
        let resourceString = "https://api.themoviedb.org/3/search/movie?api_key=2696829a81b1b5827d515ff121700838&query=\(movieName)&page=\(page)"
        
        guard let resourceURL = URL(string: resourceString) else {fatalError()}
        
        self.resourceURL = resourceURL
        
    }
    
    mutating func getMovies (completion: @escaping(Result<[MovieDetail], MovieError>) -> Void) {
        
        let dataTask = URLSession.shared.dataTask(with: resourceURL) {data, _, _ in
            guard let jsonData = data else{
                print("ERrror")
                completion(.failure((.noDataAvailable)))
                return
            }
            
            do {
                let decoder = JSONDecoder()
                let moviesResponse = try decoder.decode(MovieResponse.self, from: jsonData)
                let movieDetails = moviesResponse.results
                if moviesResponse.total_results > 0 {
                    completion(.success(movieDetails)) }
                else {
                    completion(.failure(.noDataAvailable))
                }
            }catch{
                completion(.failure(.canNotProcessData))
            }
        }
        dataTask.resume()
        
    }
    
    mutating func getTotalpages (completion: @escaping(Result<Int , MovieError>) -> Void) {
        
        let dataTask = URLSession.shared.dataTask(with: resourceURL) {data, _, _ in
            guard let jsonData = data else{
                print("Error")
                completion(.failure((.noDataAvailable)))
                return
            }
            
            do {
                let decoder = JSONDecoder()
                let moviesResponse = try decoder.decode(MovieResponse.self, from: jsonData)
                let movieDetails = moviesResponse.total_pages
                    completion(.success(movieDetails))
            }catch{
                completion(.failure(.canNotProcessData))
            }
        }
        dataTask.resume()
        
    }
    
    
}
