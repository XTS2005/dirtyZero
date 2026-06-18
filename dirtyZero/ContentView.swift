//
//  ContentView.swift
//  dirtyZero
//
//  Created by Skadz on 5/8/25.
//

import SwiftUI
import PartyUI
import DeviceKit
import UIKit

enum SectionType {
    case custom, risky, normal
}

struct ContentView: View {
    @EnvironmentObject var mgr: dirtyZeroManager
    @AppStorage("tweakArray") var tweakArray: [ZeroSection] = TweakArray.tweaks
    @AppStorage("enableDebugSettings") var enableDebugSettings: Bool = false
    @AppStorage("enableRiskyTweaks") var enableRiskyTweaks: Bool = false
    
    @State private var showSettingsView: Bool = false
    @State private var showCustomTweaksView: Bool = false
    @State private var customZeroPath: String = ""
    @State private var selectedTweak: ZeroTweak?
    
    @State private var hasOffsets: Bool = false
    @State private var fetchingKcache = false
    
    let version = doubleSystemVersion()
    
    var body: some View {
        Group {
            if UIDevice.current.userInterfaceIdiom == .phone {
                NavigationStack {
                    List {
                        AlertsSection
                            .listRowSeparator(.hidden)
                        ApplyingSection
                            .listRowSeparator(.hidden)
                        if enableDebugSettings {
                            DebuggingSection
                                .listRowSeparator(.hidden)
                        }
                        ListedTweaksSection
                            .disabled(mgr.chosenExploit == .DarkSword && !mgr.vfsready)
                            .listRowSeparator(.hidden)
                    }
                    .listStyle(.plain)
                    .navigationTitle("dirtyZero")
                    .safeAreaInset(edge: .bottom) {
                        ApplyingButtons
                            .modifier(OverlayBackground())
                    }
                    .toolbar {
                        ToolbarItem(placement: .topBarLeading) {
                            Button(action: { showSettingsView.toggle() }) {
                                Image(systemName: "gear")
                            }
                        }
                        ToolbarItem(placement: .topBarTrailing) {
                            Button(action: { showCustomTweaksView.toggle() }) {
                                Image(systemName: "paintbrush")
                            }
                        }
                    }
                }
            } else {
                NavigationSplitView(sidebar: {
                    List {
                        AlertsSection
                            .listRowSeparator(.hidden)
                        ApplyingSection
                            .listRowSeparator(.hidden)
                            .listRowInsets(.sectionInsets)
                        ApplyingButtons
                            .listRowSeparator(.hidden)
                        if enableDebugSettings {
                            DebuggingSection
                                .listRowSeparator(.hidden)
                        }
                    }
                    .listStyle(.plain)
                    .navigationTitle("dirtyZero")
                    .modifier(RemoveSidebarToggle())
                    .navigationSplitViewColumnWidth(385)
                    .toolbar {
                        ToolbarItem(placement: .topBarLeading) {
                            Button(action: { showSettingsView.toggle() }) {
                                Image(systemName: "gear")
                            }
                        }
                        ToolbarItem(placement: .topBarTrailing) {
                            Button(action: { showCustomTweaksView.toggle() }) {
                                Image(systemName: "paintbrush")
                            }
                        }
                    }
                }) {
                    List {
                        ListedTweaksSection
                            .disabled(mgr.chosenExploit == .DarkSword && !mgr.vfsready)
                            .listRowSeparator(.hidden)
                    }
                    .listStyle(.plain)
                    .toolbar(.hidden, for: .navigationBar)
                }
            }
        }
        .onChange(of: tweakArray) { _ in
            let tweaks = tweakArray.flatMap { $0.tweaks }
            mgr.enabledTweaks = tweaks.filter { $0.isOn }.count
        }
        .onAppear {
            let tweaks = tweakArray.flatMap { $0.tweaks }
            mgr.enabledTweaks = tweaks.filter { $0.isOn }.count
        }
        .sheet(isPresented: $showSettingsView) {
            SettingsView()
        }
        .sheet(isPresented: $showCustomTweaksView) {
            CustomTweaksView()
        }
        .sheet(item: $selectedTweak) { tweak in
            TweakInfoView(tweak: tweak)
        }
    }
    
    private var AlertsSection: some View {
        Group {
            if !mgr.hasOffsets && mgr.chosenExploit == .DarkSword {
                Button(action: {
                    showSettingsView.toggle()
                }) {
                    CompactAlert(title: "缺少偏移量！", icon: "exclamationmark.triangle.fill", text: "使用 DarkSword 需要偏移量。点击\"运行漏洞利用\"，然后点击\"获取内核缓存\"。")
                }
            }
        }
        .listRowInsets(.sectionInsets)
    }
    
    // MARK: Applying Section
    private var ApplyingSection: some View {
        Section(header: HeaderLabel(text: "日志", icon: "terminal"), footer: Text("由 [jailbreak.party](https://jailbreak.party) 团队倾心制作。\n加入 jailbreak.party [Discord 频道](https://jailbreak.party/discord)！").font(.footnote).foregroundStyle(.secondary)) {
            VStack {
                VStack(alignment: .leading) {
                    HStack {
                        HStack {
                            Image(systemName: mgr.applyIcon)
                            Text(mgr.applyShortStatus)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .fontWeight(.semibold)
                        }
                        Text("\(mgr.applyCurrentTweak)/\(mgr.enabledTweaks)")
                    }
                }
                .tint(mgr.applyColor)
                LogView()
                    .modifier(TerminalPlatter())
            }
            .modifier(SectionPlatter())
        }
        .listRowInsets(.sectionInsets)
    }
    
    // MARK: Debugging Section
    private var DebuggingSection: some View {
        Section(header: HeaderLabel(text: "调试", icon: "ant")) {
            HStack {
                TextField("自定义路径", text: $customZeroPath)
                    .modifier(TextFieldBackground())
                Button(action: {
                    do {
                        try mgr.zeroPage(path: customZeroPath)
                    } catch {
                        Alertinator.shared.alert(title: "文件清零失败！", body: "\(error)")
                    }
                }) {
                    Image(systemName: "checkmark")
                        .frame(width: 24, height: 24)
                }
                .buttonStyle(TranslucentButtonStyle(color: .green, useFullWidth: false))
                .disabled(customZeroPath.isEmpty)
            }
            Button(action: {
                tweakArray = TweakArray.tweaks
            }) {
                HeaderLabel(text: "重置调整列表", icon: "trash")
            }
            .buttonStyle(TranslucentButtonStyle(color: .red))
        }
        .listRowInsets(.sectionInsets)
    }
    
    // MARK: Listed Tweaks Section
    // i hate this whole section a lot, but breaking this up into three seperate arrays would suck for management. this is likely the best solution.
    private var ListedTweaksSection: some View {
        ForEach($tweakArray) { $section in
            let sectionType: SectionType = section.name == "自定义调整" ? .custom : section.name == "风险调整" ? .risky : .normal
            
            if sectionType == .risky && enableRiskyTweaks || sectionType != .risky && !section.tweaks.isEmpty {
                Section(header: HeaderDropdown(text: section.name, icon: section.icon, isExpanded: $section.isExpanded, useItemCount: true, itemCount: section.tweaks.filter { version >= $0.minSupportedVersion && version <= $0.maxSupportedVersion || enableDebugSettings }.count)) {
                    if section.isExpanded {
                        let sectionColor = sectionType == .custom ? .purple : sectionType == .risky ? .red : Color.accentColor
                        
                        ForEach($section.tweaks) { $tweak in
                            if (version >= tweak.minSupportedVersion && version <= tweak.maxSupportedVersion) || enableDebugSettings {
                                Button(action: {
                                    tweak.isOn.toggle()
                                }) {
                                    HStack(spacing: 10) {
                                        Image(systemName: tweak.icon)
                                            .frame(width: 22, height: 20)
                                        Text(tweak.name)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                        Image(systemName: tweak.isOn ? "checkmark.circle.fill" : "circle")
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                .buttonStyle(TranslucentButtonStyle(color: sectionColor))
                                .listRowSeparator(.hidden)
                                .listRowInsets(.sectionInsets)
                                .swipeActions {
                                    Button(action: {
                                        selectedTweak = tweak
                                    }) {
                                        Image(systemName: "info.circle")
                                    }
                                    if sectionType == .custom {
                                        Button(action: {
                                            let customTweaksIndex = tweakArray.firstIndex(where: { $0.name == "自定义调整" }) ?? 0
                                            
                                            tweakArray[customTweaksIndex].tweaks.removeAll { $0.name == tweak.name }
                                        }) {
                                            Image(systemName: "trash")
                                        }
                                        .tint(.red)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: Applying Buttons
    private var ApplyingButtons: some View {
        VStack {
            if mgr.chosenExploit == .DarkSword && !mgr.vfsready {
                if !mgr.hasOffsets {
                    // run offsets
                    Button(action: {
                        offsets_init()
                        mgr.run()
                    }) {
                        if mgr.dsfailed || mgr.vfsfailed {
                            ButtonLabel(text: "漏洞利用失败！", icon: "xmark")
                        } else if mgr.dsrunning || mgr.vfsrunning {
                            ButtonLabel(text: "正在运行漏洞利用...", icon: "showMeProgressPlease")
                        } else {
                            ButtonLabel(text: "运行 DarkSword", icon: "ant")
                        }
                    }
                    .buttonStyle(FancyButtonStyle(color: mgr.dsfailed || mgr.vfsfailed ? .red : .purple))
                    .disabled(mgr.dsrunning || mgr.dsready)
                    
                    // fetch kernelcache
                    Button(action: {
                        guard !fetchingKcache else { return }
                        fetchingKcache = true

                        DispatchQueue.global(qos: .userInitiated).async {
                            let fetched = fetchkcache()

                            if fetched {
                                DispatchQueue.main.async {
                                    mgr.hasOffsets = true
                                    fetchingKcache = false
                                    Alertinator.shared.alert(title: "成功获取内核缓存！", body: "现在，重启应用以完成设置并使用 dirtyZero。", showCancel: false, actionLabel: "退出", action: { exitinator() })
                                }
                                return
                            }

                            let dlkc = dlkcache()

                            DispatchQueue.main.async {
                                mgr.hasOffsets = dlkc
                                if dlkc {
                                    Alertinator.shared.alert(title: "成功下载内核缓存！", body: "现在，重启应用以完成设置并使用 dirtyZero。", showCancel: false, actionLabel: "退出", action: { exitinator() })
                                }
                                fetchingKcache = false
                            }
                        }
                    }) {
                        if fetchingKcache {
                            ButtonLabel(text: "正在获取内核缓存...", icon: "showMeProgressPlease")
                        } else {
                            ButtonLabel(text: "获取内核缓存", icon: "externaldrive")
                        }
                    }
                    .buttonStyle(FancyButtonStyle(color: mgr.dsfailed || mgr.vfsfailed ? .red : Color.accentColor))
                    .disabled(mgr.dsrunning || mgr.vfsrunning)
                } else {
                    Button(action: {
                        offsets_init()
                        mgr.run()
                    }) {
                        if mgr.dsfailed || mgr.vfsfailed {
                            ButtonLabel(text: "漏洞利用失败！", icon: "xmark")
                        } else if mgr.dsrunning || mgr.vfsrunning {
                            ButtonLabel(text: "正在运行漏洞利用...", icon: "showMeProgressPlease")
                        } else {
                            ButtonLabel(text: "运行 DarkSword", icon: "ant")
                        }
                    }
                    .buttonStyle(FancyButtonStyle(color: mgr.dsfailed || mgr.vfsfailed ? .red : .purple))
                    .disabled(mgr.dsrunning || mgr.vfsrunning || mgr.dsready)
                    
                    Button(action: {
                        mgr.vfsinit()
                    }) {
                        if mgr.vfsfailed {
                            ButtonLabel(text: "初始化失败！", icon: "xmark")
                        } else if mgr.vfsrunning {
                            ButtonLabel(text: "正在初始化 VFS...", icon: "showMeProgressPlease")
                        } else {
                            ButtonLabel(text: "初始化 VFS", icon: "cpu")
                        }
                    }
                    .buttonStyle(FancyButtonStyle())
                    .disabled(!mgr.dsready || mgr.vfsrunning)
                }
            } else {
                Button(action: {
                    mgr.applyTweaks(tweakData: tweakArray)
                }) {
                    ButtonLabel(text: "应用调整", icon: "checkmark")
                }
                .buttonStyle(FancyButtonStyle(color: .green))
                .disabled(tweakArray.flatMap { $0.tweaks }.filter { $0.isOn }.isEmpty)
                HStack {
                    Button(action: {
                        mgr.revertTweaks()
                    }) {
                        ButtonLabel(text: "还原", icon: "xmark")
                    }
                    .buttonStyle(FancyButtonStyle(color: .red))
                    Button(action: {
                        mgr.respringDevice()
                    }) {
                        ButtonLabel(text: "注销", icon: "goforward")
                    }
                    .buttonStyle(FancyButtonStyle(color: .orange))
                }
            }
        }
    }
}

// this is annoying but whatever
struct RemoveSidebarToggle: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 17.0, *) {
            content
                .toolbar(removing: .sidebarToggle)
        } else {
            
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(dirtyZeroManager())
}
