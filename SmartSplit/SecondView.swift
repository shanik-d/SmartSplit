//
//  SecondView.swift
//  SmartSplit
//
//  Created by Shanik Dassenaike on 03/06/2024.
//

import SwiftUI

struct SecondView: View {
    @Binding var receipt: Receipt
    let currencyCode: String
    let serviceChargePercentages = [
        0, 5, 7.5, 10, 12.5, 15, 17.5, 20.0
    ]
    
    var body: some View {
        VStack() {
            List {
                ForEach(receipt.items) { item in
                    HStack() {
                        Text(item.itemName).multilineTextAlignment(.leading)
                        Spacer()
                        Text(item.value ?? 0, format: .currency(code: currencyCode)).multilineTextAlignment(.trailing)
                    }
                }
            }
            Spacer()
            VStack() {
                HStack() {
                    Text("Service Charge:")
                    Picker("?", selection: $receipt.serviceCharge) {
                        Text(Decimal(0), format: .percent)
                        Text(Decimal(0.05), format: .percent)
                        Text(Decimal(0.075), format: .percent)
                        Text(Decimal(0.1), format: .percent)
                        Text(Decimal(0.125), format: .percent)
                        Text(Decimal(0.15), format: .percent)
                        Text(Decimal(0.175), format: .percent)
                        Text(Decimal(0.2), format: .percent)
                    }.pickerStyle(.menu)
                }
                Text("Running Total: \(receipt.receiptTotalWithServiceCharge().formatted(.currency(code: currencyCode)))")
            }
        }
    }
}

struct SecondView_Previews: PreviewProvider {
    @State static var receipt: Receipt = Receipt(items: [
        ReceiptItem(itemName: "Beef", value: 25.99),
        ReceiptItem(itemName: "Chips", value: 3.50),
        ReceiptItem(itemName: "Tenderstem Broccoli", value: 4.50)
        ])
    
    static var previews: some View {
        SecondView(receipt: $receipt, currencyCode: "GBP")
    }
}
