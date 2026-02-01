//
//  SecondView.swift
//  SmartSplit
//
//  Created by Shanik Dassenaike on 03/06/2024.
//

import SwiftUI

struct SecondView: View {
    @Binding var receipt: Receipt
    @Binding var diners: [Diner]
    @Binding var assignments: [UUID: Set<UUID>] // item.id -> diner ids
    let currencyCode: String
    let serviceChargePercentages = [
        0, 5, 7.5, 10, 12.5, 15, 17.5, 20.0
    ]
    
    @State private var newDinerName: String = ""
    @State private var dinerValidationMessage: String?
    
    private var perPersonTotals: [DinerTotal] {
        receipt.perPersonTotals(diners: diners, assignments: assignments)
    }
    
    private var unassignedItems: [ReceiptItem] {
        receipt.items.filter { assignments[$0.id]?.isEmpty ?? true }
    }
    
    var body: some View {
        VStack {
            List {
                Section("Items") {
                    ForEach(receipt.items) { item in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(item.itemName.isEmpty ? "Unnamed Item" : item.itemName)
                                Text(assignmentsDescription(for: item))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            VStack(alignment: .trailing) {
                                Text(item.value ?? 0, format: .currency(code: currencyCode))
                                assignmentMenu(for: item)
                            }
                        }
                    }
                }
                
                Section("Service Charge") {
                    HStack {
                        Text("Service Charge:")
                        Picker("Service Charge", selection: $receipt.serviceCharge) {
                            ForEach(serviceChargePercentages, id: \.self) { percent in
                                Text(Decimal(percent / 100), format: .percent)
                                    .tag(Decimal(percent / 100))
                            }
                        }
                        .pickerStyle(.menu)
                    }
                    Text("Total with service: \(receipt.receiptTotalWithServiceCharge().formatted(.currency(code: currencyCode)))")
                        .font(.subheadline)
                }
                
                Section("Diners") {
                    addDinerRow
                    if let validation = dinerValidationMessage {
                        Text(validation).font(.caption).foregroundColor(.red)
                    }
                    ForEach(diners) { diner in
                        let totals = perPersonTotals.first(where: { $0.diner.id == diner.id })
                        HStack {
                            Text(diner.name)
                            Spacer()
                            Text((totals?.total ?? .zero), format: .currency(code: currencyCode))
                        }
                    }
                }
                
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
    
    private func assignmentsDescription(for item: ReceiptItem) -> String {
        guard let dinerIDs = assignments[item.id], !dinerIDs.isEmpty else {
            return "Unassigned"
        }
        let names = diners.filter { dinerIDs.contains($0.id) }.map(\.name)
        return names.isEmpty ? "Unassigned" : "Assigned to: \(names.joined(separator: ", "))"
    }
    
    private func assignmentMenu(for item: ReceiptItem) -> some View {
        Menu {
            ForEach(diners) { diner in
                let isAssigned = assignments[item.id, default: []].contains(diner.id)
                Button {
                    toggleAssignment(for: item, diner: diner)
                } label: {
                    Label(diner.name, systemImage: isAssigned ? "checkmark.circle.fill" : "circle")
                }
            }
            if diners.isEmpty {
                Text("Add a diner to assign items")
            }
        } label: {
            Text("Assign")
        }
        .disabled(diners.isEmpty)
    }
    
    private var addDinerRow: some View {
        HStack {
            TextField("Diner name", text: $newDinerName)
                .onAppear {
                    if newDinerName.isEmpty { newDinerName = suggestedDinerName() }
                }
            Button("Add") {
                addDiner()
            }
            .disabled(diners.count >= 20)
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
    
    private func addDiner() {
        dinerValidationMessage = nil
        let trimmed = newDinerName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            dinerValidationMessage = "Please enter a name."
            return
        }
        guard !diners.contains(where: { $0.name.caseInsensitiveCompare(trimmed) == .orderedSame }) else {
            dinerValidationMessage = "That name is already used."
            return
        }
        guard diners.count < 20 else {
            dinerValidationMessage = "Maximum of 20 diners reached."
            return
        }
        diners.append(Diner(name: trimmed))
        newDinerName = suggestedDinerName()
    }
    
    private func suggestedDinerName() -> String {
        "Diner \(diners.count + 1)"
    }
}

struct DinerTotal: Identifiable {
    let diner: Diner
    let subtotal: Decimal
    let service: Decimal
    var total: Decimal { subtotal + service }
    var id: UUID { diner.id }
}

extension Receipt {
    func perPersonTotals(diners: [Diner], assignments: [UUID: Set<UUID>]) -> [DinerTotal] {
        var subtotals: [UUID: Decimal] = [:]
        
        for item in items {
            guard let value = item.value, value > .zero else { continue }
            let dinerIDs = assignments[item.id] ?? []
            guard !dinerIDs.isEmpty else { continue }
            let count = Decimal(dinerIDs.count)
            let baseShare = (value / count).rounded(toPlaces: 2, roundingMode: .plain)
            let totalRounded = baseShare * count
            let residue = value.rounded(toPlaces: 2, roundingMode: .plain) - totalRounded
            
            for (index, dinerID) in dinerIDs.enumerated() {
                var share = baseShare
                if index == dinerIDs.count - 1 {
                    share += residue
                }
                subtotals[dinerID, default: .zero] += share
            }
        }
        
        let subtotalSum = subtotals.values.reduce(.zero, +)
        let servicePortion = receiptTotalWithServiceCharge() - receiptTotal()
        let hasShares = subtotalSum > .zero
        
        var totals: [DinerTotal] = []
        var accumulatedService: Decimal = .zero
        for (index, diner) in diners.enumerated() {
            let subtotal = subtotals[diner.id]?.rounded(toPlaces: 2) ?? .zero
            var serviceShare: Decimal = .zero
            if hasShares {
                let proportional = (subtotal / subtotalSum) * servicePortion
                serviceShare = proportional.rounded(toPlaces: 2, roundingMode: .plain)
            }
            
            // allocate any rounding residue on service to the last diner to keep sums aligned
            if hasShares && index == diners.count - 1 {
                let roundedSum = accumulatedService + serviceShare
                let residue = servicePortion.rounded(toPlaces: 2) - roundedSum
                serviceShare += residue
            }
            accumulatedService += serviceShare
            
            totals.append(DinerTotal(diner: diner, subtotal: subtotal, service: serviceShare))
        }
        
        return totals
    }
}

struct SecondView_Previews: PreviewProvider {
    @State static var receipt: Receipt = Receipt(items: [
        ReceiptItem(itemName: "Beef", value: 25.99),
        ReceiptItem(itemName: "Chips", value: 3.50),
        ReceiptItem(itemName: "Tenderstem Broccoli", value: 4.50)
        ])
    @State static var diners: [Diner] = [
        Diner(name: "Alex"), Diner(name: "Sam")
    ]
    @State static var assignments: [UUID: Set<UUID>] = [:]
    
    static var previews: some View {
        SecondView(receipt: $receipt, diners: $diners, assignments: $assignments, currencyCode: "GBP")
    }
}
