//
//  ContentView.swift
//  SmartSplit
//
//  Created by Shanik Dassenaike on 19/11/2023.
//

import SwiftUI

struct ReceiptItem: Identifiable, Equatable {
    let id = UUID()
    var itemName: String
    var value: Decimal?
}

struct Diner: Identifiable, Equatable {
    let id = UUID()
    var name: String
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

extension Decimal {
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
    @State private var diners: [Diner] = []
    @State private var assignments: [UUID: Set<UUID>] = [:]
    @State private var isAssigning: Bool = false
    @State private var dinerValidationMessage: String?
    @State private var assignmentPopoverItem: ReceiptItem?

    @State private var currencyCode: String = Locale.current.currency?.identifier ?? FALLBACK_CURRENCY.identifier

    @State private var dragAmount: CGSize = .zero
    @State private var fieldsToAdd: Int = 0
    @State private var showFieldsToAddCount: Bool = false
    @State private var showFieldsToAddDialog: Bool = false
    @State private var showMaxFieldsAlert: Bool = false

    private var priceEntered: Bool { receipt.receiptTotal() > 0 }
    private var perPersonTotals: [DinerTotal] { receipt.perPersonTotals(diners: diners, assignments: assignments) }
    private var unassignedItems: [ReceiptItem] { receipt.items.filter { assignments[$0.id]?.isEmpty ?? true } }
    private var longestDinerNameLength: Int { diners.map { $0.name.count }.max() ?? 0 }
    private var assignmentCardWidth: CGFloat {
        let target = Double(longestDinerNameLength) * 7.5 + 140 // approximate character width plus padding
        return CGFloat(min(360, max(260, target)))
    }
    private var assignmentCardHeight: CGFloat {
        let rows = max(1, diners.count)
        let contentHeight = Double(rows) * 34.0 + 140 // row height + header/footer
        return CGFloat(min(420, max(220, contentHeight)))
    }
    private var assignmentNameFontSize: CGFloat {
        let length = longestDinerNameLength
        let size = 18.0 - Double(max(0, length - 12)) * 0.3
        return CGFloat(max(14, min(18, size)))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                VStack {
                    topBlock
                    receiptItemList
                    bottomBlock
                }
                if let item = assignmentPopoverItem {
                    assignmentOverlay(for: item)
                        .transition(.opacity)
                        .zIndex(1)
                }
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
            if isAssigning {
                Button("Back to items") { isAssigning = false }
            } else {
                Button("Assign diners") {
                    ensureAtLeastOneDiner()
                    isAssigning = true
                }
                .disabled(!priceEntered)
            }
            Spacer()
        }
    }

    private var receiptItemList: some View {
        List {
            Section("Items") {
                ForEach($receipt.items.indices, id: \.self) { index in
                    HStack {
                        if isAssigning {
                            VStack(alignment: .leading) {
                                Text("\(index + 1). \(receipt.items[index].itemName.isEmpty ? "Item \(index + 1)" : receipt.items[index].itemName)")
                                Text(assignmentsDescription(for: receipt.items[index]))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            VStack(alignment: .trailing, spacing: 4) {
                                Text(receipt.items[index].value ?? 0, format: .currency(code: currencyCode))
                                    .font(.subheadline)
                                assignmentButton(for: receipt.items[index])
                            }
                        } else {
                            TextField("Item \(index + 1)", text: $receipt.items[index].itemName)
                                .multilineTextAlignment(.leading)
                            Spacer()
                            TextField("Price", value: $receipt.items[index].value, format: .currency(code: currencyCode))
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                        }
                    }
                }
            }

            if isAssigning {
                serviceChargeSection
                dinersSection
                if !unassignedItems.isEmpty {
                    Section {
                        Text("Some items are unassigned. Assign all items before finishing.")
                            .foregroundColor(.orange)
                            .font(.footnote)
                    }
                }
            }
        }
    }

    private var bottomBlock: some View {
        VStack {
            runningTotalBlock
            if !isAssigning {
                addItemsBlock
            }
        }
    }

    private var runningTotalBlock: some View {
        VStack(spacing: 4) {
            Text("Running Total: \(receipt.receiptTotal().formatted(.currency(code: currencyCode)))")
            Text("With service: \(receipt.receiptTotalWithServiceCharge().formatted(.currency(code: currencyCode)))")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    private var addItemsBlock: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                Spacer().frame(width: geometry.size.width / 12)

                if showFieldsToAddCount {
                    Text("Items to add: \(fieldsToAdd)")
                        .multilineTextAlignment(.center)
                        .frame(width: geometry.size.width / 3)
                } else {
                    Text("Tap or swipe to add more items")
                        .multilineTextAlignment(.center)
                        .frame(width: geometry.size.width / 3)
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
        dragAmount = .zero
        showFieldsToAddDialog = false
        showFieldsToAddCount = false
        showMaxFieldsAlert = false
    }

    private func assignmentsDescription(for item: ReceiptItem) -> String {
        guard let dinerIDs = assignments[item.id], !dinerIDs.isEmpty else {
            return "Unassigned"
        }
        let names = diners.filter { dinerIDs.contains($0.id) }.map(\.name)
        return names.isEmpty ? "Unassigned" : "Assigned to: \(names.joined(separator: ", "))"
    }

    private func assignmentButton(for item: ReceiptItem) -> some View {
        Button {
            assignmentPopoverItem = item
        } label: {
            Text(assignmentButtonLabel(for: item))
        }
        .disabled(diners.isEmpty)
    }

    private func assignmentButtonLabel(for item: ReceiptItem) -> String {
        let count = assignments[item.id]?.count ?? 0
        switch count {
        case 0: return "Assign"
        case 1: return "1 diner"
        default: return "\(count) diners"
        }
    }

    private var serviceChargeSection: some View {
        Section("Service Charge") {
            Picker("Service Charge", selection: $receipt.serviceCharge) {
                ForEach([0, 5, 7.5, 10, 12.5, 15, 17.5, 20.0], id: \.self) { percent in
                    Text(Decimal(percent / 100), format: .percent)
                        .tag(Decimal(percent / 100))
                }
            }
            .pickerStyle(.menu)
            Text("Total with service: \(receipt.receiptTotalWithServiceCharge().formatted(.currency(code: currencyCode)))")
                .font(.subheadline)
        }
    }

    private var dinersSection: some View {
        Section {
            if let validation = dinerValidationMessage {
                Text(validation).font(.caption).foregroundColor(.red)
            }
            ForEach($diners) { $diner in
                HStack {
                    TextField("Name", text: $diner.name)
                    Spacer()
                    if let totals = perPersonTotals.first(where: { $0.diner.id == diner.id }) {
                        Text(totals.total, format: .currency(code: currencyCode))
                    } else {
                        Text(Decimal.zero, format: .currency(code: currencyCode))
                    }
                }
            }
        } header: {
            HStack {
                Text("Diners")
                Spacer()
                Button {
                    addDiner()
                } label: {
                    Label("Add diner", systemImage: "person.badge.plus")
                }
                .disabled(diners.count >= 20)
            }
        }
    }

    private func toggleAssignment(for item: ReceiptItem, diner: Diner) {
        var current = assignments[item.id, default: []]
        if current.contains(diner.id) {
            current.remove(diner.id)
        } else {
            current.insert(diner.id)
        }
        assignments[item.id] = current
    }

    private func ensureAtLeastOneDiner() {
        if diners.isEmpty {
            addDiner()
        }
    }

    private func addDiner() {
        dinerValidationMessage = nil
        guard diners.count < 20 else {
            dinerValidationMessage = "Maximum of 20 diners reached."
            return
        }
        let proposed = suggestedDinerName()
        let uniqueName = nextAvailableName(basedOn: proposed)
        diners.append(Diner(name: uniqueName))
    }

    private func suggestedDinerName() -> String { "Diner \(diners.count + 1)" }

    private func nextAvailableName(basedOn base: String) -> String {
        var candidate = base
        var counter = 1
        while diners.contains(where: { $0.name.caseInsensitiveCompare(candidate) == .orderedSame }) {
            counter += 1
            candidate = "\(base) \(counter)"
        }
        return candidate
    }

    private func assignmentOverlay(for item: ReceiptItem) -> some View {
        ZStack {
            Color.black.opacity(0.35)
                .ignoresSafeArea()
                .onTapGesture { assignmentPopoverItem = nil }
            
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Spacer()
                    Text(item.itemName.isEmpty ? "Assign item" : item.itemName)
                        .font(.headline)
                        .multilineTextAlignment(.center)
                    Spacer()
                    Button {
                        assignmentPopoverItem = nil
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
                Divider()
                ScrollView {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(diners) { diner in
                            let isAssigned = assignments[item.id, default: []].contains(diner.id)
                            Button {
                                toggleAssignment(for: item, diner: diner)
                            } label: {
                                HStack {
                                    Image(systemName: isAssigned ? "checkmark.circle.fill" : "circle")
                                        .foregroundColor(isAssigned ? .accentColor : .secondary)
                                    Text(diner.name)
                                        .font(.system(size: assignmentNameFontSize, weight: .regular))
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.85)
                                    Spacer()
                                }
                            }
                        }
                        if diners.isEmpty {
                            Text("Add a diner to assign items").foregroundColor(.secondary)
                        }
                    }
                }
                Divider()
                HStack {
                    Spacer()
                    Button("Done") {
                        assignmentPopoverItem = nil
                    }
                }
            }
            .padding(14)
            .frame(minWidth: 240, idealWidth: assignmentCardWidth, maxWidth: 380,
                   minHeight: 200, idealHeight: assignmentCardHeight, maxHeight: 440)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .shadow(radius: 10)
            .padding()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
