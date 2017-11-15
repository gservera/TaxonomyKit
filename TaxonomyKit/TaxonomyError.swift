/*
 *  TaxonomyError.swift
 *  TaxonomyKit
 *
 *  Created:    Guillem Servera on 24/09/2016.
 *  Copyright:  © 2016-2017 Guillem Servera (https://github.com/gservera)
 *
 *  Permission is hereby granted, free of charge, to any person obtaining a copy
 *  of this software and associated documentation files (the "Software"), to deal
 *  in the Software without restriction, including without limitation the rights
 *  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 *  copies of the Software, and to permit persons to whom the Software is
 *  furnished to do so, subject to the following conditions:
 *
 *  The above copyright notice and this permission notice shall be included in
 *  all copies or substantial portions of the Software.
 *
 *  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 *  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 *  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 *  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 *  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 *  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 *  THE SOFTWARE.
 */

/// An error type that describes errors originated from the TaxonomyKit methods.
///
/// - networkError:            A network error. More details can be found inspecting the
///                            associated error object.
/// - parseError:              An error due to a malformed XML/JSON object.
/// - unexpectedResponseError: An unexpected server response (other than 200) from the
///                            NCBI servers.
/// - unknownError:            Any other error, including unexpected structure or missing values
///                            in the XML/JSON data that was downloaded.
public enum TaxonomyError: Error {

    /// A network error. More details can be found inspecting the associated error object.
    case networkError(underlyingError: Error)

    /// An error due to a malformed XML/JSON object.
    case parseError(message: String)

    /// An unexpected server response (other than 200) from the NCBI servers.
    case unexpectedResponse(code: Int)

    /// An unexpected taxon passed to a LineageTree method.
    case unregisteredTaxa

    /// Too few taxa passed to a LineageTree method.
    case insufficientTaxa

    /// Thrown when passed nodes are registered in different LineageTree objects.
    case incompatibleNodes

    /// Any other error, including unexpected structure or missing values in 
    /// the XML/JSON data that was downloaded.
    case unknownError
}
