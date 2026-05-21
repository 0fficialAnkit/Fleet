import SwiftUI

struct CreateTicketView: View {
    @Environment(\.dismiss) private var dismiss
    var viewModel: SupportViewModel
    let driverId: UUID
    @State private var step = 1
    @State private var selectedCategory: TicketCategory?
    @State private var subject = ""
    @State private var messageText = ""
    
    private var isValid: Bool {
        !subject.trimmingCharacters(in: .whitespaces).isEmpty && !messageText.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                themeModel.backgroundPrimary.ignoresSafeArea()
                VStack(spacing: 0) {
                    HStack(spacing: themeModel.spacingSM) {
                        ForEach(1...3, id: \.self) { i in
                            RoundedRectangle(cornerRadius: 3).fill(i <= step ? themeModel.accent : themeModel.surfaceTertiary).frame(height: 4)
                        }
                    }.padding(.horizontal, themeModel.spacingMD).padding(.vertical, themeModel.spacingSM)
                    
                    ScrollView {
                        VStack(spacing: themeModel.spacingLG) {
                            switch step { case 1: step1; case 2: step2; case 3: step3; default: EmptyView() }
                        }.padding(themeModel.spacingMD)
                    }
                }
            }
            .navigationTitle("New Ticket").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() }.foregroundColor(themeModel.textSecondary) } }
            .animation(.easeInOut(duration: 0.3), value: step)
        }.preferredColorScheme(.dark)
    }
    
    private var step1: some View {
        VStack(alignment: .leading, spacing: themeModel.spacingMD) {
            Text("What do you need help with?").font(themeModel.title(22)).foregroundStyle(themeModel.textPrimary)
            Text("Select a category").font(themeModel.bodyMedium()).foregroundStyle(themeModel.textSecondary)
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: themeModel.spacingMD) {
                ForEach(TicketCategory.allCases, id: \.self) { cat in
                    CategoryCard(icon: viewModel.categoryIcon(cat), label: viewModel.categoryLabel(cat), color: viewModel.categoryColor(cat), isSelected: selectedCategory == cat)
                        .onTapGesture {
                            withAnimation(.spring(response: 0.3)) { selectedCategory = cat }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { step = 2 }
                        }
                }
            }
        }
    }
    
    private var step2: some View {
        VStack(alignment: .leading, spacing: themeModel.spacingMD) {
            Button { step = 1 } label: { HStack(spacing: 4) { Image(systemName: "chevron.left"); Text("Change Category") }.font(themeModel.caption()).foregroundColor(themeModel.accent) }
            if let cat = selectedCategory {
                HStack(spacing: 6) { Image(systemName: viewModel.categoryIcon(cat)).font(.caption); Text(viewModel.categoryLabel(cat)).font(themeModel.small()) }
                    .foregroundColor(viewModel.categoryColor(cat)).padding(.horizontal, 10).padding(.vertical, 6)
                    .background(viewModel.categoryColor(cat).opacity(0.15)).clipShape(RoundedRectangle(cornerRadius: themeModel.radiusXS))
            }
            Text("Describe your issue").font(themeModel.title(22)).foregroundStyle(themeModel.textPrimary)
            VStack(alignment: .leading, spacing: themeModel.spacingXS) {
                Text("Subject").font(themeModel.caption()).foregroundColor(themeModel.textSecondary)
                TextField("Brief summary", text: $subject).font(themeModel.body()).foregroundStyle(themeModel.textPrimary)
                    .padding(themeModel.spacingSM).background(themeModel.inputBackground)
                    .clipShape(RoundedRectangle(cornerRadius: themeModel.radiusXS))
                    .overlay(RoundedRectangle(cornerRadius: themeModel.radiusXS).stroke(themeModel.inputBorder, lineWidth: 1))
            }
            VStack(alignment: .leading, spacing: themeModel.spacingXS) {
                Text("Details").font(themeModel.caption()).foregroundColor(themeModel.textSecondary)
                TextField("Full details...", text: $messageText, axis: .vertical).lineLimit(4...10).font(themeModel.body()).foregroundStyle(themeModel.textPrimary)
                    .padding(themeModel.spacingSM).background(themeModel.inputBackground)
                    .clipShape(RoundedRectangle(cornerRadius: themeModel.radiusXS))
                    .overlay(RoundedRectangle(cornerRadius: themeModel.radiusXS).stroke(themeModel.inputBorder, lineWidth: 1))
            }
            Button { step = 3 } label: {
                HStack { Spacer(); Text("Review").font(themeModel.bodyMedium()); Image(systemName: "arrow.right"); Spacer() }
                    .padding(themeModel.spacingMD).background(isValid ? themeModel.accent : themeModel.buttonDisabled)
                    .foregroundColor(isValid ? themeModel.accentForeground : themeModel.buttonDisabledText)
                    .clipShape(RoundedRectangle(cornerRadius: themeModel.radiusSM))
            }.disabled(!isValid)
        }
    }
    
    private var step3: some View {
        VStack(alignment: .leading, spacing: themeModel.spacingMD) {
            Button { step = 2 } label: { HStack(spacing: 4) { Image(systemName: "chevron.left"); Text("Edit Details") }.font(themeModel.caption()).foregroundColor(themeModel.accent) }
            Text("Review & Submit").font(themeModel.title(22)).foregroundStyle(themeModel.textPrimary)
            VStack(alignment: .leading, spacing: themeModel.spacingMD) {
                if let cat = selectedCategory {
                    HStack(spacing: 8) { Image(systemName: viewModel.categoryIcon(cat)).foregroundColor(viewModel.categoryColor(cat)); Text(viewModel.categoryLabel(cat)).font(themeModel.bodyMedium()).foregroundStyle(themeModel.textPrimary) }
                }
                Divider().background(themeModel.divider)
                VStack(alignment: .leading, spacing: themeModel.spacingXS) { Text("Subject").font(themeModel.small()).foregroundColor(themeModel.textTertiary); Text(subject).font(themeModel.bodyMedium()).foregroundStyle(themeModel.textPrimary) }
                VStack(alignment: .leading, spacing: themeModel.spacingXS) { Text("Message").font(themeModel.small()).foregroundColor(themeModel.textTertiary); Text(messageText).font(themeModel.body()).foregroundStyle(themeModel.textSecondary).fixedSize(horizontal: false, vertical: true) }
            }.padding(themeModel.spacingMD).background(themeModel.backgroundElevated).clipShape(RoundedRectangle(cornerRadius: themeModel.radiusSM)).shadow(color: themeModel.shadowSoft, radius: 5, x: 0, y: 2)
            Button(action: submitTicket) {
                HStack { Spacer(); Image(systemName: "paperplane.fill"); Text("Submit Ticket").font(themeModel.bodyMedium()); Spacer() }
                    .padding(themeModel.spacingMD).background(themeModel.accent).foregroundColor(themeModel.accentForeground).clipShape(RoundedRectangle(cornerRadius: themeModel.radiusSM))
            }
        }
    }
    
    private func submitTicket() {
        guard let cat = selectedCategory, isValid else { return }
        viewModel.createTicket(driverId: driverId, category: cat, subject: subject.trimmingCharacters(in: .whitespaces), initialMessage: messageText.trimmingCharacters(in: .whitespaces))
        dismiss()
    }
}

struct CategoryCard: View {
    let icon: String; let label: String; let color: Color; let isSelected: Bool
    var body: some View {
        VStack(spacing: themeModel.spacingSM) {
            Image(systemName: icon).font(.system(size: 28)).foregroundColor(color)
            Text(label).font(themeModel.bodyMedium(14)).foregroundStyle(themeModel.textPrimary).multilineTextAlignment(.center)
        }.frame(maxWidth: .infinity).padding(themeModel.spacingLG)
        .background(isSelected ? color.opacity(0.15) : themeModel.backgroundElevated)
        .clipShape(RoundedRectangle(cornerRadius: themeModel.radiusMD))
        .overlay(RoundedRectangle(cornerRadius: themeModel.radiusMD).stroke(isSelected ? color : Color.clear, lineWidth: 2))
        .shadow(color: themeModel.shadowSoft, radius: isSelected ? 8 : 4, x: 0, y: 2)
    }
}
