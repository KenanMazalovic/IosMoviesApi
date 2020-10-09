//
//  ViewController.swift
//  MoviesApi
//
//  Created by Kenan Mazalovic on 10/1/20.
//

import UIKit
import CoreData

class MovieCell: UITableViewCell {
    
    @IBOutlet weak var moviePoster: UIImageView!
    @IBOutlet weak var movieName: UILabel!
    @IBOutlet weak var movieDate: UILabel!
    @IBOutlet weak var movieOverview: UILabel!
}

class SuggestionsCell: UITableViewCell {
    static let id = "SuggestionsCell"
    
    override class func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
}


@available(iOS 13.0, *)
class MoviesViewController: UITableViewController {
    
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet var tableview: UITableView!
    var isAlert : Bool = false
    var trimmedSearch: String = ""
    var totalPages: Int!
    var page: Int = 1
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    var isSuggestions: Bool = false
    var list = [Suggestions]()
  
    
    var listOfMovies = [MovieDetail]() {
        didSet {
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }
    
    var listofSuggestions = [String] () {
        didSet {
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        searchBar.delegate = self
        tableView.register(SuggestionsCell.self, forCellReuseIdentifier: SuggestionsCell.id)
        loadSuggestion()
        
        
        
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if(isAlert){
            let alert = UIAlertController(title: "Error", message: "Searchbar is empty or there is no movie in database", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
            isAlert=false
        }
        if(!isSuggestions){
            return listOfMovies.count
        }
        else{
            return listofSuggestions.count
        }
        
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if(!isSuggestions){
            let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! MovieCell
            
            if indexPath.row == listOfMovies.count - 1 {
                self.appendMoviesOnScroll()
            }
            let movie = listOfMovies[indexPath.row]
            let posterString = movie.poster_path
            
            if posterString != nil {
                let str = "https://image.tmdb.org/t/p/w92/\(posterString!)"
                let url = URL(string: str)
                cell.moviePoster.load(url: url!)
            }
            else {
                cell.moviePoster.image = UIImage(named: "noimage")
            }
            
            if movie.release_date != "" {
                cell.movieDate.text = movie.release_date
            }
            else{
                cell.movieDate.text = "NO DATA!"
            }
            
            if movie.overview != "" {
                cell.movieOverview.text = movie.overview
            }
            else{
                cell.movieOverview.text = "NO DATA!"
            }
            cell.movieName.text = movie.title
            return cell
        }
        else{
            let cell = tableView.dequeueReusableCell(withIdentifier: SuggestionsCell.id, for: indexPath)
            
            let suggestion = listofSuggestions[indexPath.row]
            
            cell.textLabel?.text = suggestion
            return cell
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if(isSuggestions){
            self.listOfMovies.removeAll()
            self.page=1
            self.searchMovie(search: listofSuggestions[indexPath.row])
        }
    }
    
    func appendMoviesOnScroll() {
        if(self.page > 1) {
            self.searchMovie(search: trimmedSearch)
            
        }
    }
    
    
    func searchMovie(search:String) {
        
        var movieRequest = MovieRequest(movieName: search,page: self.page)
        self.isSuggestions=false
        movieRequest.getMovies { [weak self] result in
            switch result {
            case .failure(let error):
                DispatchQueue.main.async {
                    self!.isAlert = true
                    self?.listOfMovies.removeAll()
                    self?.tableView.reloadData()
                    self?.isSuggestions = true 
                }
                print(error)
            case .success(let movies):
                let newSuggestion = Suggestions(context: self!.context)
                newSuggestion.name = search
                self?.saveSuggestion()
                self?.listOfMovies.append(contentsOf: movies)
                if self!.page == self!.totalPages {
                    self?.page = 0
                }
                self!.page+=1
            }
        }
        
    }
    
    func saveSuggestion() {
        do {
            try context.save()
        } catch {
            print("Error saving context \(error)")
        }
        
    }
    
    func loadSuggestion() {
        let request : NSFetchRequest<Suggestions> = Suggestions.fetchRequest()
        let SortDescriptor = NSSortDescriptor(key: "_pk", ascending: false)
        request.sortDescriptors = [SortDescriptor]
        do{
            var array = [String]()
            list = try context.fetch(request)
            var i = 0
            while i < list.count{
                if(list[i].name != nil){
                    array.append(list[i].name!)
                }
                i+=1
            }
            if(array.count > 10){
                array.removeSubrange(10...array.count-1)
            }
            
            listofSuggestions = uniq(source: array)
        } catch{
            print("Error fetching data from context \(error)")
        }
    }
    
    
    func uniq<S : Sequence, T : Hashable>(source: S) -> [T] where S.Iterator.Element == T {
        var buffer = [T]()
        var added = Set<T>()
        for elem in source {
            if !added.contains(elem) {
                buffer.append(elem)
                added.insert(elem)
            }
        }
        return buffer
    }
    
    
    
}

@available(iOS 13.0, *)
extension MoviesViewController : UISearchBarDelegate {
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        self.listOfMovies.removeAll()
        self.page=1
        guard let searchBarText = searchBar.text else {return}
        trimmedSearch = searchBarText.trimmingCharacters(in: .whitespacesAndNewlines)
        self.searchMovie(search: self.trimmedSearch)
        
        var movieRequest = MovieRequest(movieName: trimmedSearch,page: self.page)
        movieRequest.getTotalpages { [weak self] result in
            switch result {
            case .failure(let error):
                print(error)
            case .success(let totpages):
                self?.totalPages = totpages
            }
        }
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        self.isSuggestions = true
        loadSuggestion()
        tableView.reloadData()
        
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        self.isSuggestions = true
        loadSuggestion()
        tableView.reloadData()
    }
}

extension URL {
    init(_ string: StaticString) {
        self.init(string: "\(string)")!
    }
}

extension UIImageView {
    func load(url: URL) {
        DispatchQueue.global().async { [weak self] in
            if let data = try? Data(contentsOf: url) {
                if let image = UIImage(data: data) {
                    DispatchQueue.main.async {
                        self?.image = image
                    }
                }
            }
        }
    }
}

extension Array where Element: Hashable {
    var uniques: Array {
        var buffer = Array()
        var added = Set<Element>()
        for elem in self {
            if !added.contains(elem) {
                buffer.append(elem)
                added.insert(elem)
            }
        }
        return buffer
    }
}

