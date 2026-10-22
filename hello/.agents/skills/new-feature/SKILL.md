---
name: new-feature
description: Scaffold a new app feature (screen) with MVVM. Use when the user asks to add a new screen or feature.
---
1. Create Features/<Name>/Views/<Name>View.swift with a #Preview.
2. Create Features/<Name>/ViewModels/<Name>ViewModel.swift: @Observable final class. No @MainActor: the project's default actor isolation is already MainActor.
3. Inject dependencies via init using protocols (for testing).
4. Create Tests/<Name>Tests/<Name>ViewModelTests.swift using Swift Testing.
   - This needs a unit test target. If the project has none, stop and ask the user to add one in Xcode (File > New > Target > Unit Testing Bundle). Never hand-edit project.pbxproj.
5. Build and run the tests; fix all errors and warnings.
