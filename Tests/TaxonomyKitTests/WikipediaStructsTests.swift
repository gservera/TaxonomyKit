//
//  WikipediaStructsTests.swift
//  TaxonomyKitTests
//
//  Created by Guillem Servera Negre on 07/10/2018.
//  Copyright © 2018 Guillem Servera. All rights reserved.
//

import XCTest
@testable import TaxonomyKit

class WikipediaStructsTests: XCTestCase {

    func testHtmlParsing() {

        let sample = """
<p class=\"mw-empty-elt\">


</p>
<p>The <b>red panda</b> (<i>Ailurus fulgens</i>), also called the <b>lesser panda</b>.
</p>
"""

        #if os(iOS) || os(watchOS) || os(tvOS)
        let parsed = try? sample.parseHTML(setting: UIFont.systemFont(ofSize: 12))
        #else
        let parsed = try? sample.parseHTML(setting: NSFont.systemFont(ofSize: 12))
        #endif
        XCTAssertEqual(parsed?.string, "The red panda (Ailurus fulgens), also called the lesser panda. \n")

    }

    func testDownloadInvalidImage() {
        let invalidUrl = URL(string: "https://gservera.com/invalid-url-test")!
        XCTAssertNil(Wikipedia.downloadImage(from: invalidUrl))
    }
}
