//
//  SavedLinkEditorView.swift
//  hello
//

import SwiftUI

/// Sheet for adding a URL or editing an existing one.
struct SavedLinkEditorView: View {
    @Bindable var viewModel: SavedLinksViewModel
    let editor: SavedLinksViewModel.Editor
    @FocusState private var isFieldFocused: Bool

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("https://example.com", text: $viewModel.draftURL, axis: .vertical)
                        .keyboardType(.URL)
                        .textContentType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .submitLabel(.done)
                        .focused($isFieldFocused)
                        .onSubmit(viewModel.saveDraft)
                } header: {
                    Text("URL")
                } footer: {
                    if let error = viewModel.draftError {
                        Text(error)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: viewModel.cancelEditing)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: viewModel.saveDraft)
                        .disabled(viewModel.draftURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .onAppear { isFieldFocused = true }
        }
        .presentationDetents([.medium, .large])
    }

    private var title: LocalizedStringKey {
        switch editor {
        case .add: "Add URL"
        case .edit: "Edit URL"
        }
    }
}

#Preview {
    let viewModel = SavedLinksViewModel(store: InMemorySavedLinkStore())
    SavedLinkEditorView(viewModel: viewModel, editor: .add)
}
