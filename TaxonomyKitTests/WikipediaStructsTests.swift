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

        let sample = "<p class=\"mw-empty-elt\">\n\n\n</p>\n<p>The <b>red panda</b> (<i>Ailurus fulgens</i>), also called the <b>lesser panda</b>, the <b>red bear-cat</b>, and the <b>red cat-bear</b> is a mammal native to the eastern Himalayas and southwestern China. It has reddish-brown fur, a long, shaggy tail, and a waddling gait due to its shorter front legs; it is roughly the size of a domestic cat, though with a longer body and somewhat heavier. It is arboreal, feeds mainly on bamboo, but also eats eggs, birds, and insects. It is a solitary animal, mainly active from dusk to dawn, and is largely sedentary during the day.\n</p><p>The red panda has been classified as endangered by the IUCN, because its wild population is estimated at less than 10,000 mature individuals and continues to decline due to habitat loss and fragmentation, poaching, and inbreeding depression, although red pandas are protected by national laws in their range countries.</p><p>The red panda is the only living species of the genus <i>Ailurus</i> and the family Ailuridae. It has been previously placed in the raccoon and bear families, but the results of phylogenetic analysis provide strong support for its taxonomic classification in its own family, Ailuridae, which is part of the superfamily Musteloidea, along with the weasel, raccoon and skunk families. Two subspecies are recognized. It is not closely related to the giant panda, which is a basal ursid.\n</p>"
        let parsed = try! sample.parseHTML(setting: UIFont.systemFont(ofSize: 12))
        XCTAssert(true)

    }



}
