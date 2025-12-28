//
//  SmartSplitTests.swift
//  SmartSplitTests
//
//  Created by Shanik Dassenaike on 19/11/2023.
//

import XCTest
@testable import SmartSplit

final class SmartSplitTests: XCTestCase {

    func testReceiptTotalSumsValuesAndIgnoresNil() {
        let receipt = Receipt(items: [
            ReceiptItem(itemName: "Pizza", value: Decimal(string: "10.50")),
            ReceiptItem(itemName: "Fries", value: Decimal(string: "3.50")),
            ReceiptItem(itemName: "Water", value: nil)
        ])

        XCTAssertEqual(receipt.receiptTotal(), Decimal(string: "14.00"))
    }

    func testReceiptTotalIsZeroWhenEmpty() {
        let receipt = Receipt(items: [])

        XCTAssertEqual(receipt.receiptTotal(), Decimal.zero)
    }

    func testServiceChargeDefaultsToZero() {
        let receipt = Receipt(items: [ReceiptItem(itemName: "Burger", value: 12.00)])

        XCTAssertEqual(receipt.serviceCharge, Decimal.zero)
    }

    func testReceiptTotalWithServiceChargeUsesPercentage() {
        var receipt = Receipt(items: [
            ReceiptItem(itemName: "Steak", value: Decimal(string: "20.00")),
            ReceiptItem(itemName: "Soda", value: Decimal(string: "2.50"))
        ])
        receipt.serviceCharge = Decimal(string: "0.125")! // 12.5%

        XCTAssertEqual(receipt.receiptTotalWithServiceCharge(), Decimal(string: "25.31"))
    }
}
