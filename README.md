# TaxonomyKit 

![Platforms](https://img.shields.io/badge/platforms-ios%20%7C%20osx%20%7C%20watchos%20%7C%20tvos-lightgrey.svg)
[![GitHub release](https://img.shields.io/github/release/gservera/taxonomykit.svg)](https://github.com/gservera/TaxonomyKit/releases) 
[![Build Status](https://travis-ci.org/gservera/TaxonomyKit.svg?branch=master)](https://travis-ci.org/gservera/TaxonomyKit) 
[![codecov.io](https://codecov.io/github/gservera/TaxonomyKit/coverage.svg?branch=master)](https://codecov.io/github/gservera/TaxonomyKit?branch=master)
[![GitHub license](https://img.shields.io/badge/license-MIT-lightgrey.svg)](https://raw.githubusercontent.com/gservera/TaxonomyKit/master/LICENSE.md) 
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
![Swift version](https://img.shields.io/badge/swift-3.0-orange.svg)

TaxonomyKit is a powerful, handy and cross-platform library that makes working with taxonomy data from the NCBI databases easier. It works as a client of the NCBI's [Entrez Programming Utilities](https://eutils.ncbi.nlm.nih.gov) and it is the core of the [Taxonomist](https://gservera.com/apps/taxonomist/) app.

## How To Get Started

- [Download TaxonomyKit](https://github.com/gservera/TaxonomyKit/archive/master.zip)


## Installation with Carthage

[Carthage](https://github.com/Carthage/Carthage) is a decentralized dependency manager that builds your dependencies and provides you with binary frameworks.

You can install Carthage with [Homebrew](http://brew.sh/) using the following command:

```bash
$ brew update
$ brew install carthage
```

To integrate TaxonomyKit into your Xcode project using Carthage, specify it in your `Cartfile`:

```ogdl
github "gservera/TaxonomyKit" ~> 1.0
```

Run `carthage` to build the framework and drag the built `TaxonomyKit.framework` into your Xcode project.

## Requirements

* Xcode 8.0

## Unit Tests

TaxonomyKit includes a suite of unit tests within the TaxonomyKitTests subdirectory. These tests can be run simply be executed the test action on the platform framework you would like to test.

## License

TaxonomyKit is released under the MIT license. See LICENSE for details.
