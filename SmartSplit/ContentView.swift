//
//  ContentView.swift
//  SmartSplit
//  Displays a list of text fields, representing a receipt
//  Sums the total to ensure the user has entered everything correctly
//  Displays in the user's local currency.
//
//  Created by Shanik Dassenaike on 19/11/2023.
//

import SwiftUI

struct ReceiptItem: Identifiable {
    let id = UUID()
    var itemName: String
    var value: Decimal?
}

let FALLBACK_CURRENCY = Locale.Currency("GBP")

struct ContentView: View {
    @State private var receiptItems: [ReceiptItem] = [
        ReceiptItem(itemName: "Item 1", value: nil),
        ReceiptItem(itemName: "Item 2", value: nil),
        ReceiptItem(itemName: "Item 3", value: nil)
    ]
    
    @State private var currency: Locale.Currency = Locale.current.currency ?? FALLBACK_CURRENCY
    
    private var receiptTotal: Decimal {
        receiptItems.reduce(0, { runningTotal, receiptItem in
            runningTotal + (receiptItem.value ?? 0)
        })
    }
    
    var body: some View {
        VStack {
            HStack {
                Text("Currency: \(currency.identifier)")
            }
            
            List($receiptItems) { receiptItem in
                HStack {
                    TextField("Item name", text: receiptItem.itemName)
                    TextField("Price", value: receiptItem.value, format: .currency(code: currency.identifier))
                }
            }
            
            Text("Running Total: \(receiptTotal.formatted(.currency(code: currency.identifier)))")
            
            Button(action: addField) {
                Image(systemName: "plus.circle").imageScale(.large).foregroundColor(.accentColor)
            }
        }
        
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundColor(.accentColor)
            Text("Hello, world!")
        }
        .padding()
    }
    
    private func addField() {
        receiptItems.append(ReceiptItem(itemName: "Item " + (receiptItems.count + 1).formatted(), value: nil))
    }
    
    private func updateCurrency(newCurrency: Locale.Currency) {
        currency = newCurrency
    }
 }

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
