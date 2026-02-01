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
    
    func testPerPersonTotalsSplitEvenlyWithService() {
        let dinerA = Diner(name: "Alex")
        let dinerB = Diner(name: "Sam")
        
        let item = ReceiptItem(itemName: "Pasta", value: Decimal(string: "10.00"))
        var receipt = Receipt(items: [item])
        receipt.serviceCharge = Decimal(string: "0.10")! // 10%
        
        let assignments: [UUID: Set<UUID>] = [
            item.id: Set([dinerA.id, dinerB.id])
        ]
        
        let totals = receipt.perPersonTotals(diners: [dinerA, dinerB], assignments: assignments)
        let alexTotal = totals.first(where: { $0.diner.id == dinerA.id })
        let samTotal = totals.first(where: { $0.diner.id == dinerB.id })
        
        XCTAssertEqual(alexTotal?.subtotal, Decimal(string: "5.00"))
        XCTAssertEqual(alexTotal?.service, Decimal(string: "0.50"))
        XCTAssertEqual(samTotal?.subtotal, Decimal(string: "5.00"))
        XCTAssertEqual(samTotal?.service, Decimal(string: "0.50"))
    }
    
    func testServiceNotAllocatedWhenNoAssignments() {
        let dinerA = Diner(name: "Alex")
        let dinerB = Diner(name: "Sam")
        
        let item = ReceiptItem(itemName: "Pasta", value: Decimal(string: "10.00"))
        var receipt = Receipt(items: [item])
        receipt.serviceCharge = Decimal(string: "0.10")! // 10%
        
        let assignments: [UUID: Set<UUID>] = [:] // no assignments
        
        let totals = receipt.perPersonTotals(diners: [dinerA, dinerB], assignments: assignments)
        XCTAssertTrue(totals.allSatisfy { $0.service == .zero && $0.total == .zero })
    }
}
