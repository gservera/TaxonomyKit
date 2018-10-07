//
//  WikipediaStructsTests.swift
//  TaxonomyKitTests
//
//  Created by Guillem Servera Negre on 07/10/2018.
//  Copyright © 2018 Guillem Servera. All rights reserved.
//

import XCTest

class WikipediaStructsTests: XCTestCase {



    func testHtmlParsing() {

        let sample = "<p class=\"mw-empty-elt\">\n</p>\n<p><b>Thomson\'s gazelle</b> (<i>Eudorcas thomsonii</i>) is one of the best-known gazelles. It is named after explorer Joseph Thomson and is sometimes referred to as a \"<b>tommie</b>\". It is considered by some to be a subspecies of the red-fronted gazelle and was formerly considered a member of the genus <i>Gazella</i> within the subgenus <i>Eudorcas</i>, before <i>Eudorcas</i> was elevated to genus status. Thomson\'s gazelles can be found in numbers exceeding 550,000 in Africa and are recognized as the most common type of gazelle in East Africa.  Thomson\'s gazelles can reach speeds of 50–55 miles per hour (80–90 km/h). It is the fifth-fastest land animal, after the cheetah, also it’s main predator, pronghorn, springbok and wildebeest.</p>"
        let parsed = try! sample.parseHTML(setting: UIFont.systemFont(ofSize: 12))
        XCTAssert(true)

    }



}
