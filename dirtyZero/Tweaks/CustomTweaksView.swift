//
//  CustomTweaksView.swift
//  dirtyZero
//
//  Created by lunginspector on 10/10/25.
//

import SwiftUI
import PartyUI
import UIKit
import DeviceKit

struct CustomTweaksView: View {
    @EnvironmentObject var mgr: dirtyZeroManager
    @Environment(\.dismiss) var dismiss
    @AppStorage("tweakArray") var tweakArray: [ZeroSection] = TweakArray.tweaks
    @AppStorage("enableDebugSettings") var enableDebugSettings: Bool = false
    
    @State private var tweakName: String = ""
    @State private var path2Add: String = ""
    @State private var targetPaths: [String] = []
    
    var body: some View {
        NavigationStack {
            List {
                if enableDebugSettings {
                    Section(header: HeaderLabel(text: "调试", icon: "ant")) {
                        Button(action: {
                            tweakName = "隐藏 Dock 背景"
                            targetPaths = ["/System/Library/PrivateFrameworks/CoreMaterial.framework/dockDark.materialrecipe", "/System/Library/PrivateFrameworks/CoreMaterial.framework/dockLight.materialrecipe"]
                        }) {
                            ButtonLabel(text: "填充示例数组", icon: "character.cursor.ibeam")
                        }
                        .buttonStyle(TranslucentButtonStyle(color: .purple))
                    }
                    .listRowInsets(.sectionInsets)
                    .listRowSeparator(.hidden)
                }
                Section(header: HeaderLabel(text: "创建调整", icon: "paintbrush")) {
                    VStack {
                        TextField("调整名称", text: $tweakName)
                            .modifier(TextFieldBackground())
                        HStack {
                            TextField("/path/to/zero", text: $path2Add)
                                .modifier(TextFieldBackground())
                            Button(action: {
                                if targetPaths.contains(path2Add) {
                                    Haptic.shared.play(.heavy)
                                    Alertinator.shared.alert(title: "错误！", body: "该路径已存在于目标路径列表中。请尝试不同的路径。")
                                } else {
                                    Haptic.shared.play(.soft)
                                    targetPaths.append(path2Add)
                                }
                            }) {
                                Image(systemName: "plus")
                                    .frame(width: 24, height: 24)
                            }
                            .buttonStyle(TranslucentButtonStyle(color: .purple, useFullWidth: false))
                            .disabled(path2Add.isEmpty || tweakName.isEmpty)
                        }
                    }
                }
                .listRowInsets(.sectionInsets)
                .listRowSeparator(.hidden)
                
                if !targetPaths.isEmpty {
                    Section(header: HeaderLabel(text: "目标路径", icon: "character.cursor.ibeam")) {
                        ForEach(targetPaths, id: \.self) { path in
                            Text(path)
                                .font(.system(.footnote, design: .monospaced))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding()
                                .background(Color(.secondarySystemBackground), in: .rect(cornerRadius: cornerRad.component))
                                .swipeActions {
                                    Button(role: .destructive, action: {
                                        targetPaths.removeAll { $0 == path }
                                    }) {
                                        Image(systemName: "xmark")
                                    }
                                    .tint(.red)
                                }
                        }
                    }
                    .listRowInsets(.sectionInsets)
                    .listRowSeparator(.hidden)
                }
            }
            .listStyle(.plain)
            .navigationTitle("调整创建器")
            .navigationBarTitleDisplayMode(.inline)
            .safeAreaInset(edge: .bottom) {
                Button(action: {
                    let customTweaksIndex = tweakArray.firstIndex(where: { $0.name == "自定义调整" }) ?? 0
                    tweakArray[customTweaksIndex].tweaks.append(ZeroTweak(name: tweakName, icon: "paintbrush", paths: targetPaths))
                    dismiss()
                }) {
                    ButtonLabel(text: "添加调整", icon: "plus")
                }
                .buttonStyle(TranslucentButtonStyle(color: .purple))
                .disabled(targetPaths.isEmpty || tweakName.isEmpty)
                .modifier(OverlayBackground(stickBottomPadding: UIDevice.current.userInterfaceIdiom == .pad ? true : false))
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark")
                    }
                }
            }
            .tint(.purple)
        }
    }
}

#Preview {
    CustomTweaksView()
}
