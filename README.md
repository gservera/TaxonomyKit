<p align="center" >
  <img src="https://gservera.com/apps/taxonomist/gh_banner.svg" width="800" alt="TaxonomyKit" title="TaxonomyKit">
</p>

# TaxonomyKit 

![Platforms](https://img.shields.io/badge/platforms-ios%20%7C%20osx%20%7C%20watchos%20%7C%20tvos-blue.svg)
[![GitHub release](https://img.shields.io/github/release/gservera/taxonomykit.svg)](https://github.com/gservera/TaxonomyKit/releases) 
[![Build Status](https://travis-ci.org/gservera/TaxonomyKit.svg?branch=master)](https://travis-ci.org/gservera/TaxonomyKit) 
[![codecov.io](https://codecov.io/github/gservera/TaxonomyKit/coverage.svg?branch=master)](https://codecov.io/github/gservera/TaxonomyKit?branch=master)
[![GitHub license](https://img.shields.io/badge/license-MIT-lightgrey.svg)](https://raw.githubusercontent.com/gservera/TaxonomyKit/master/LICENSE.md) 
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
![Swift version](https://img.shields.io/badge/swift-3.1-orange.svg)

TaxonomyKit is a powerful, handy and cross-platform library that makes working with taxonomy data from the NCBI databases easier. It works as a client of the NCBI's [Entrez Programming Utilities](https://eutils.ncbi.nlm.nih.gov) and it is the core of the [Taxonomist](https://gservera.com/apps/taxonomist/) app.


## How To Get Started

- [Download TaxonomyKit](https://github.com/gservera/TaxonomyKit/archive/master.zip) or install it using Carthage.
- Check out the [Documentation](https://gservera.com/docs/TaxonomyKit/) for the Taxonomy struct or just read the following section to begin quickly.


## First steps

### 🔭 Get the NCBI's Taxonomy ID for the taxon you are looking for

```swift
let myCoolQuery = "quercus ilex"
Taxonomy.findIdentifiers(for: myCoolQuery, callback: { result in
    switch result {
    case .success(let foundIDs):
        print("Found identifiers: \(foundIDs).")
    case .failure(let error):
        print("Oops! Something went wrong. Error was: \(error)")
    }
})
```

### ⬇️ Download your taxon

```swift
let foundID: TaxonID = "58334" // Use the one you got from previous step.
Taxonomy.downloadTaxon(withIdentifier: foundID, callback: { result in
    switch result {
    case .success(let taxon):
        print("Got taxon: \(taxon.name).")
    case .failure(let error):
        print("Oops! Something went wrong. Error was: \(error)")
    }
})
```

### 📖 Get an extract from Wikipedia

```swift
Taxonomy.retrieveWikipediaAbstract(for: downloadedTaxon) { answer in
    switch answer {
    case .success(let result):
        print("Got info: \(result.extract).")
    case .failure(let error):
        print("Oops! Something went wrong. Error was: \(error)")
    }
}
```

## Installation with Carthage

[Carthage](https://github.com/Carthage/Carthage) is a decentralized dependency manager that builds your dependencies and provides you with binary frameworks.

You can install Carthage with [Homebrew](http://brew.sh/) using the following command:

```bash
$ brew update
$ brew install carthage
```

To integrate TaxonomyKit into your Xcode project using Carthage, specify it in your `cartfile`:

```ogdl
github "tadija/AEXML"
github "gservera/TaxonomyKit" ~> 1.4
```

Run `carthage update` on your project's directory to build the framework and drag the built `TaxonomyKit.framework` into your Xcode project.

## Requirements

* macOS 10.10 Yosemite or greater.
* **Xcode 8.3** or greater.
* **AEXML >4.1**. A wonderful XML parser written in Swift. See more at [tadija/AEXML](https://github.com/tadija/AEXML).

## Unit Tests

TaxonomyKit includes a suite of unit tests within the TaxonomyKitTests subdirectory. These tests can be run simply be executed the test action on the platform framework you would like to test.

## ☕️ Author

Proudly developed by [Guillem Servera](https://gservera.com) in Palma, Illes Balears.

## License

TaxonomyKit is released under the MIT license. See [LICENSE](https://github.com/gservera/TaxonomyKit/blob/master/LICENSE.md) for details.
