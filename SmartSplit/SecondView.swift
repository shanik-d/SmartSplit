//
//  SecondView.swift
//  SmartSplit
//
//  Created by Shanik Dassenaike on 03/06/2024.
//

import SwiftUI

struct SecondView: View {
    let receiptItems: [ReceiptItem]
    let currencyCode: String
    
    var body: some View {
        List {
            ForEach(receiptItems) { item in
                HStack() {
                    Text(item.itemName)
                    Text(item.value ?? 0, format: .currency(code: currencyCode))
                }
            }
        }
    }
}

struct SecondView_Previews: PreviewProvider {
    static var previews: some View {
        SecondView(receiptItems: [], currencyCode: "GBP")
    }
}
