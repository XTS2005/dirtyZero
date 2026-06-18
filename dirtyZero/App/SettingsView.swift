//
//  SettingsView.swift
//  dirtyZero
//
//  Created by lunginspector on 10/8/25.
//

import SwiftUI
import PartyUI
import DeviceKit

struct SettingsView: View {
    @EnvironmentObject var mgr: dirtyZeroManager
    @Environment(\.dismiss) var dismiss
    @Environment(\.openURL) var openURL
    @AppStorage("tweakArray") var tweakArray: [ZeroSection] = TweakArray.tweaks
    
    @AppStorage("useRespringApp") var useRespringApp: Bool = false
    @AppStorage("respringAppBID") var respringAppBID: String = "com.jbdotparty.respringr"
    
    @AppStorage("enableDebugSettings") var enableDebugSettings: Bool = false
    @AppStorage("enableRiskyTweaks") var enableRiskyTweaks: Bool = false
    
    @State private var fetchingKcache: Bool = false
    @State private var downloadingKcache: Bool = false
    @State private var showKcacheImporter: Bool = false
    
    var body: some View {
        NavigationStack {
            List {
                Section(header: HeaderLabel(text: "信息", icon: "info.circle")) {
                    VStack {
                        AppInfoCell()
                            .frame(maxWidth: .infinity, alignment: .leading)
                        HStack {
                            Button(action: {
                                openURL(URL(string: "https://jailbreak.party/discord")!)
                            }) {
                                ButtonLabel(text: "Discord", icon: "discord", useImage: true)
                            }
                            .buttonStyle(TranslucentButtonStyle(color: .discord))
                            Button(action: {
                                openURL(URL(string: "https://github.com/jailbreakdotparty/dirtyZero")!)
                            }) {
                                ButtonLabel(text: "GitHub", icon: "github", useImage: true)
                            }
                            .buttonStyle(TranslucentButtonStyle(color: .gitHub))
                        }
                        Button(action: {
                            openURL(URL(string: "https://jailbreak.party")!)
                        }) {
                            ButtonLabel(text: "网站", icon: "globe")
                        }
                        .buttonStyle(TranslucentButtonStyle(color: .blue))
                    }
                    NavigationLink("致谢") {
                        List {
                            LinkCreditCell(image: Image("skadz108"), name: "Skadz", description: "初始开发者、后端及漏洞利用相关管理。", url: "https://github.com/skadz108")
                            LinkCreditCell(image: Image("lunginspector"), name: "lunginspector", description: "前端开发者、调整创建者及应用界面。", url: "https://github.com/lunginspector")
                            LinkCreditCell(image: Image("ianbeer"), name: "Ian Beer (Gooogle Project Zero)", description: "发现并发布 CVE-2025-24203。", url: "https://project-zero.issues.chromium.org/issues/391518636")
                            LinkCreditCell(image: Image("DuyTran"), name: "Duy Tran", description: "应用检测漏洞利用，以及对其他所用库的多项贡献。", url: "https://github.com/khanhduytran0")
                            if mgr.chosenExploit == .DarkSword {
                                LinkCreditCell(image: Image("rooootdev"), name: "rooootdev", description: "DarkSword 漏洞利用库及实现协助。", url: "https://github.com/rooootdev")
                                LinkCreditCell(image: Image("appinstallerios"), name: "AppInstalleriOS", description: "Patchfinder 协助及多项贡献。", url: "https://github.com/AppInstalleriOSGH")
                                LinkCreditCell(image: Image("wh1te4ever"), name: "wh1te4ever", description: "对 DarkSword 漏洞利用的多项补充与研究。", url: "https://github.com/wh1te4ever")
                                LinkCreditCell(image: Image("opa334"), name: "opa334", description: "原 DarkSword 内核漏洞利用实现，以及多项所需库。", url: "https://github.com/opa334")
                                LinkCreditCell(image: Image("alfiecg"), name: "Alfie CG", description: "开发了内核缓存下载库。", url: "https://github.com/alfiecg24")
                            }
                            LinkCreditCell(image: Image("neonmodder123"), name: "neonmodder123", description: "开发了 WebView 注销方法。", url: "https://github.com/neonmodder123")
                            LinkCreditCell(image: Image("floatingdreamer"), name: "浮梦往事", description: "完成了应用汉化。", url: "http://www.coolapk.com/u/30819340")
                        }
                        .navigationTitle("致谢")
                    }
                }
                Section(header: HeaderLabel(text: "漏洞利用", icon: "ant"), footer: Text("要使用 dirtyZero，您应首先运行漏洞利用，然后点击\"获取内核缓存\"按钮。如果获取内核缓存失败，您也可以尝试自行下载或提取并导入。")) {
                    if mgr.supportsl0ckwire {
                        Picker("", selection: $mgr.chosenExploit) {
                            ForEach(ExploitOptions.allCases, id: \.self) { option in
                                if option.rawValue != "none" {
                                    Text(option.rawValue).tag(option)
                                }
                            }
                        }
                        .pickerStyle(.segmented)
                        .listRowSeparator(.hidden)
                    }
                    // this check should keep the ux of hiding these options for devices that support both l0ckwire and DarkSword, while also forcing these options to be shown if this device supports only DarkSword.
                    if mgr.chosenExploit == .DarkSword || defaultExploit() == .DarkSword {
                        if !mgr.hasOffsets {
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
                                    HStack {
                                        Text("正在获取内核缓存...")
                                        Spacer()
                                        ProgressView()
                                    }
                                } else {
                                    Text("获取内核缓存")
                                }
                            }
                            .disabled(fetchingKcache || !mgr.dsready)
                            
                            Button(action: {
                                downloadingKcache = true
                                let dlkc = dlkcache()
                                
                                DispatchQueue.main.async {
                                    mgr.hasOffsets = dlkc
                                    if dlkc {
                                        Alertinator.shared.alert(title: "成功下载内核缓存！", body: "现在，重启应用以完成设置并使用 dirtyZero。", showCancel: false, actionLabel: "退出", action: { exitinator() })
                                    }
                                    downloadingKcache = false
                                }
                            }) {
                                if downloadingKcache {
                                    HStack {
                                        Text("正在下载内核缓存...")
                                        Spacer()
                                        ProgressView()
                                    }
                                } else {
                                    Text("下载内核缓存")
                                }
                            }
                            .disabled(downloadingKcache)
                            
                            Button(action: {
                                showKcacheImporter.toggle()
                            }) {
                                Text("导入内核缓存")
                            }
                        } else {
                            Button("删除内核缓存", role: .destructive, action: {
                                clearkerncachedata()
                                mgr.hasOffsets = false
                                mgr.isReady = false
                                mgr.applyShortStatus = "未找到内核缓存！"
                                mgr.applyIcon = "exclamationmark.triangle.fill"
                                mgr.applyColor = Color.yellow
                            })
                        }
                    }
                    
                    if mgr.chosenExploit == .DarkSword {
                        NavigationLink("修改偏移量", destination: OffsetManagementView())
                    }
                }
                Section(header: HeaderLabel(text: "应用", icon: "checkmark.seal")) {
                    Toggle(isOn: $useRespringApp) {
                        Text("使用 Respring App")
                        Text("仅当您更倾向于使用[独立应用](https://github.com/jailbreakdotparty/dirtyZero/releases/tag/respringr)来重启桌面时启用此项。")
                    }
                    if useRespringApp {
                        TextField("Respring App Bundle ID", text: $respringAppBID)
                    }
                }
                Section(header: HeaderLabel(text: "自定义", icon: "checklist")) {
                    Toggle("调试设置", isOn: $enableDebugSettings)
                    Toggle("风险调整", isOn: $enableRiskyTweaks)
                }
                Section(header: HeaderLabel(text: "数据", icon: "externaldrive")) {
                    Button("重置选中的调整", action: {
                        tweakArray = TweakArray.tweaks
                    })
                    Button("移除自定义调整", role: .destructive, action: {
                        Alertinator.shared.alert(title: "您确定要移除所有自定义调整吗？", body: "这将移除您创建的所有调整。", action: {
                            let customTweaksIndex = tweakArray.firstIndex(where: { $0.name == "自定义调整" }) ?? 0
                            
                            tweakArray[customTweaksIndex].tweaks.removeAll()
                        })
                    })
                }
            }
            .navigationTitle("设置")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                    }
                }
            }
        }
        // thanks roooot
        .fileImporter(isPresented: $showKcacheImporter, allowedContentTypes: [.data], allowsMultipleSelection: false) { result in
            switch result {
            case .success(let urls):
                guard let url = urls.first else { return }
                DispatchQueue.global(qos: .userInitiated).async {
                    var ok = false
                    let shouldStopAccess = url.startAccessingSecurityScopedResource()
                    defer {
                        if shouldStopAccess {
                            url.stopAccessingSecurityScopedResource()
                        }
                    }
                    let fm = FileManager.default
                    if let docs = fm.urls(for: .documentDirectory, in: .userDomainMask).first {
                        let dest = docs.appendingPathComponent("kernelcache")
                        do {
                            if fm.fileExists(atPath: dest.path) {
                                try fm.removeItem(at: dest)
                            }
                            try fm.copyItem(at: url, to: dest)
                            ok = dlkcache()
                        } catch {
                            print("failed to import kernelcache: \(error)")
                            ok = false
                        }
                    }
                    DispatchQueue.main.async {
                        mgr.hasOffsets = ok
                    }
                }
            case .failure:
                break
            }
        }
    }
}

#Preview {
    SettingsView()
}