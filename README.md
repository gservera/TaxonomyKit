<p align="center" >
  <img src="https://raw.githubusercontent.com/gservera/TaxonomyKit/master/banner.png" width="750" alt="TaxonomyKit" title="TaxonomyKit">
</p>

# TaxonomyKit 

![Platforms](https://img.shields.io/badge/platforms-ios%20%7C%20osx%20%7C%20watchos%20%7C%20tvos-blue.svg)
[![GitHub release](https://img.shields.io/github/release/gservera/taxonomykit.svg)](https://github.com/gservera/TaxonomyKit/releases) 
[![Build Status](https://travis-ci.org/gservera/TaxonomyKit.svg?branch=master)](https://travis-ci.org/gservera/TaxonomyKit) 
[![GitHub license](https://img.shields.io/badge/license-MIT-lightgrey.svg)](https://raw.githubusercontent.com/gservera/TaxonomyKit/master/LICENSE.md) 
[![SwiftPM compatible](https://camo.githubusercontent.com/52e3db230991dda10458295d71c859c34be466b6/68747470733a2f2f696d672e736869656c64732e696f2f62616467652f5377696674504d2d436f6d70617469626c652d627269676874677265656e2e737667)](https://swift.org/package-manager/)
![Swift version](https://img.shields.io/badge/swift-5.1-orange.svg)
[![codebeat badge](https://codebeat.co/badges/0a40e0c1-5100-4b9e-9b0c-b2b08c011eb9)](https://codebeat.co/projects/github-com-gservera-taxonomykit-master)

TaxonomyKit is a powerful, handy and cross-platform library that makes working with taxonomy data from the NCBI databases easier. It works as a client of the NCBI's [Entrez Programming Utilities](https://eutils.ncbi.nlm.nih.gov) and it is the core of the [Taxonomist](https://gservera.com/apps/taxonomist/) app.


## How To Get Started

- [Download TaxonomyKit](https://github.com/gservera/TaxonomyKit/archive/master.zip) or fecth it using Swift Package Manager.
- Check out the [Documentation](https://gservera.com/docs/TaxonomyKit/) for the Taxonomy struct or just read the following section to begin quickly.


## First steps

### 🔭 Get the NCBI's Taxonomy ID for the taxon you're looking for

```swift
let myCoolQuery = "quercus ilex"
Taxonomy.findIdentifiers(for: myCoolQuery) { result in
    switch result {
    case .success(let foundIDs):
        print("Found identifiers: \(foundIDs).")
    case .failure(let error):
        print("Oops! Something went wrong. Error was: \(error)")
    }
}
```

### ⬇️ Download your taxa

```swift
let foundIDs: [TaxonID] = [58334] // Use the one you got from previous step.
Taxonomy.downloadTaxa(identifiers: [foundIDs]) { result in
    switch result {
    case .success(let taxa):
        print("Got \(taxa.count) taxa.")
    case .failure(let error):
        print("Oops! Something went wrong. Error was: \(error)")
    }
}
```

### 📖 Get an extract from Wikipedia

```swift
Wikipedia.retrieveAbstract(for: downloadedTaxon) { result in
    switch result {
    case .success(let wikipediaResult):
        print("Got info: \(wikipediaResult.extract).")
    case .failure(let error):
        print("Oops! Something went wrong. Error was: \(error)")
    }
}
```

## Requirements

* macOS 10.14 Mojave or greater.
* **Xcode 11** or greater.

## Unit Tests

TaxonomyKit includes a suite of unit tests within the Tests subdirectory. These tests can be run simply be executed the test action on the platform framework you would like to test.

## ☕️ Author

Proudly developed by [Guillem Servera Negre](https://gservera.com) in Palma, Illes Balears.

## License

TaxonomyKit is released under the MIT license. See [LICENSE](https://github.com/gservera/TaxonomyKit/blob/master/LICENSE.md) for details.
