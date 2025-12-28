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

struct ReceiptItem: Identifiable, Equatable {
    let id = UUID()
    var itemName: String
    var value: Decimal?
}

struct Receipt {
    var items: [ReceiptItem]
    var serviceCharge: Decimal

    init(items: [ReceiptItem]) {
        self.items = items
        self.serviceCharge = .zero
    }

    func receiptTotal() -> Decimal {
        let total = self.items.reduce(Decimal.zero, { runningTotal, receiptItem in
            runningTotal + (receiptItem.value ?? .zero)
        })
        return total.rounded(toPlaces: 2)
    }

    func receiptTotalWithServiceCharge() -> Decimal {
        let totalWithCharge = self.receiptTotal() * (1 + serviceCharge)
        return totalWithCharge.rounded(toPlaces: 2)
    }
}

private extension Decimal {
    /// Returns the decimal rounded to the specified number of fractional digits using bankers rounding.
    func rounded(toPlaces scale: Int, roundingMode: NSDecimalNumber.RoundingMode = .bankers) -> Decimal {
        var value = self
        var roundedValue = Decimal()
        NSDecimalRound(&roundedValue, &value, scale, roundingMode)
        return roundedValue
    }
}

let FALLBACK_CURRENCY = Locale.Currency("GBP")

struct ContentView: View {
    @State private var receipt: Receipt = Receipt(items: [
        ReceiptItem(itemName: "", value: nil),
        ReceiptItem(itemName: "", value: nil),
        ReceiptItem(itemName: "", value: nil)
    ])
    
    @State private var currencyCode: String = Locale.current.currency?.identifier ?? FALLBACK_CURRENCY.identifier
    
    @State private var dragAmount: CGSize = CGSize.zero
    
    @State private var fieldsToAdd: Int = 0
    
    @State private var showFieldsToAddCount: Bool = false
    
    @State private var showFieldsToAddDialog: Bool = false
    
    @State private var showMaxFieldsAlert: Bool = false
    
    @State private var textPlaceholder: String = ""
    
    private var priceEntered: Bool {
        receipt.receiptTotal() > 0
    }
    
    var body: some View {
        NavigationStack() {
            VStack {
                topBlock
                receiptItemList
                bottomBlock
            }
        }
    }
    
    private var currencyLabelPicker: some View {
        HStack {
            Text("Currency: \(currencyCode)")
            Picker("", selection: $currencyCode) {
                ForEach(Locale.commonISOCurrencyCodes, id: \.self) { code in
                    Text("\(code)").tag(code)
                }
            }.pickerStyle(.menu)
        }
    }
    
    private var topBlock: some View {
        HStack {
            Spacer()
            currencyLabelPicker
            Spacer()
            NavigationLink("Next") {
                SecondView(receipt: $receipt, currencyCode: currencyCode)
            }
            .disabled(!priceEntered)
            Spacer()
        }
    }
    
    private var receiptItemList: some View {
        List {
            ForEach($receipt.items.indices, id: \.self) { index in
                HStack {
                    TextField("Item \(index)", text: $receipt.items[index].itemName).multilineTextAlignment(.leading)
                    Spacer()
                    TextField("Price", value: $receipt.items[index].value, format: .currency(code: currencyCode))
                        .keyboardType(.decimalPad).multilineTextAlignment(.trailing)
                }
            }
        }
    }
    
    private var bottomBlock: some View {
        VStack {
            runningTotalBlock
            addItemsBlock
        }
    }
    
    private var runningTotalBlock: some View {
        Text("Running Total: \(receipt.receiptTotal().formatted(.currency(code: currencyCode)))")
    }
    
    private var addItemsBlock: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                Spacer().frame(width: geometry.size.width / 12)
                
                if showFieldsToAddCount {
                    Text("Items to add: \(fieldsToAdd)")
                        .multilineTextAlignment(.center)
                        .frame(width:  geometry.size.width / 3)
                } else {
                    Text("Tap or swipe to add more items")
                        .multilineTextAlignment(.center)
                        .frame(width:  geometry.size.width / 3)
                }
                
                addItemsButton
                    .frame(width: geometry.size.width / 6)
                
                Spacer()
            }
            .frame(height: 45)
        }
        .frame(height: 45)
    }
    
    private var addItemsButton: some View {
        Button(action: addOneField) {
            Image(systemName: "plus.circle").imageScale(.large).foregroundColor(.accentColor)
        }
        .offset(x: max(dragAmount.width, 0))
        .highPriorityGesture(
            DragGesture()
                .onChanged { gesture in
                    dragAmount = gesture.translation
                    let fieldsFromDrag = calculateFieldCountFromDrag(amount: dragAmount)
                    if(!showFieldsToAddCount && fieldsFromDrag > fieldsToAdd){
                        showFieldsToAddCount.toggle()
                    }
                    if(showFieldsToAddCount && fieldsFromDrag == 0){
                        showFieldsToAddCount.toggle()
                    }
                    fieldsToAdd = min(fieldsFromDrag, 10)
                    validateNumberOfFields(requestedVal: fieldsToAdd)
                }
                .onEnded { _ in
                    if(fieldsToAdd > 9) {
                        showFieldsToAddDialog.toggle()
                    } else {
                        addFieldsAndReset()
                    }
                }
        )
        .sheet(isPresented: $showFieldsToAddDialog, onDismiss: addFieldsAndReset) {
            itemsToAddSheet.presentationDetents([.height(100.0), .fraction(0.15), .medium])
        }
        .alert(isPresented: $showMaxFieldsAlert){
            maxLimitReachedAlert
        }
    }
    
    private var itemsToAddSheet: some View {
        HStack {
            Text("Items to Add: ")
            TextField("Number", value: $fieldsToAdd, format: .number)
                .keyboardType(.numberPad)
                .onChange(of: fieldsToAdd) { newVal in
                    validateNumberOfFields(requestedVal: newVal)
                }
                .alert(isPresented: $showMaxFieldsAlert) {
                    maxLimitReachedAlert
                }
            Button("Add", action: { showFieldsToAddDialog.toggle() })
        }.padding().fixedSize()
    }
    
    private var maxLimitReachedAlert: Alert {
        Alert (
            title: Text("Maximum Limit Reached"),
            message: Text("The maximum number of fields is 50"),
            dismissButton: .default(Text("OK"))
        )
    }
    
    private func validateNumberOfFields(requestedVal: Int) {
        if(requestedVal + receipt.items.count > 50){
            fieldsToAdd = 50 - receipt.items.count
            showMaxFieldsAlert = true
        }
    }
    
    private func addFieldButtonAction() {
        validateNumberOfFields(requestedVal: 1)
        if(!showMaxFieldsAlert){
            addOneField()
        }
    }
    
    private func addOneField() {
        receipt.items.append(ReceiptItem(itemName: "", value: nil))
    }
    
    private func calculateFieldCountFromDrag(amount: CGSize) -> Int {
        return Int(max(floor(amount.width / 15), 0))
    }
    
    private func addMultipleFields(numberOfFields: Int) {
        for _ in 0..<numberOfFields {
            addOneField()
        }
    }
    
    private func addFieldsAndReset() {
        addMultipleFields(numberOfFields: fieldsToAdd)
        fieldsToAdd = 0
        dragAmount = CGSize.zero
        showFieldsToAddDialog = false
        showFieldsToAddCount = false
        showMaxFieldsAlert = false
    }
 }

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
