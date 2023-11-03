//
//  BillboardBannerView.swift
//
//  Created by Hidde van der Ploeg on 03/07/2023.
//

import SwiftUI

public struct BillboardBannerView : View {
    @Environment(\.accessibilityReduceMotion) private var reducedMotion
    @Environment(\.openURL) private var openURL
    
    let advert : BillboardAd
    let config : BillboardConfiguration
    let includeShadow : Bool
    let hideDismissButtonAndTimer : Bool
    
    @State private var canDismiss = false
    @State private var appIcon : UIImage? = nil
    @State private var showAdvertisement = true
    
    public init(advert: BillboardAd, config: BillboardConfiguration = BillboardConfiguration(), includeShadow: Bool = true, hideDismissButtonAndTimer: Bool = false) {
        self.advert = advert
        self.config = config
        self.includeShadow = includeShadow
        self.hideDismissButtonAndTimer = hideDismissButtonAndTimer
    }
    
    public var body: some View {
        
        HStack(spacing: 10) {
            Button {
                if let url = advert.appStoreLink {
                    openURL(url)
                    canDismiss = true
                }
            } label: {
                HStack(spacing: 10) {
                    if let appIcon {
                        Image(uiImage: appIcon)
                            .resizable()
                            .frame(width: 60, height: 60)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    VStack(alignment: .leading, spacing: 4) {
                                                
                        VStack(alignment: .leading) {
                            Text(advert.title)
                                .font(.compatibleSystem(.footnote, design: .rounded, weight: .bold))
                                .foregroundColor(advert.text)
                                .lineLimit(1)
                                .minimumScaleFactor(0.75)
                            Text(advert.description)
                                .font(.compatibleSystem(.caption, design: .rounded, weight: .medium))
                                .foregroundColor(advert.text)
                                .minimumScaleFactor(0.75)
                            
                            HStack {
                                BillboardAdInfoLabel(advert: advert)

                                Text(advert.name)
                                    .font(.compatibleSystem(.caption, design: .rounded, weight: .medium).smallCaps())
                                    .foregroundColor(advert.tint)
                                    .opacity(0.8)
                                
                                Spacer()
                                
                            }
                        }
                    }
                }
            }
            .buttonStyle(.plain)
            Spacer()
            
            if !hideDismissButtonAndTimer {
                if canDismiss {
                    Button {
                        if config.allowHaptics {
                            haptics(.light)
                        }
                        
                        withAnimation(.spring()) {
                            showAdvertisement = false
                        }
                        
                    } label: {
                        Label("Dismiss advertisement", systemImage: "xmark.circle.fill")
                            .labelStyle(.iconOnly)
                            .font(.compatibleSystem(.title2, design: .rounded, weight: .bold))
                            .symbolRenderingMode(.hierarchical)
                            .imageScale(.large)
                            .controlSize(.large)
                    }
                    .tint(advert.tint)
                } else {
                    BillboardCountdownView(advert:advert,
                                           totalDuration: config.duration,
                                           canDismiss: $canDismiss)
                    .padding(.trailing, 2)
                }
            }
        }
        .padding(10)
        .background(backgroundView)
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(Color.primary.opacity(0.1), lineWidth: 1))
        .task {
            await fetchAppIcon()
        }
        .opacity(showAdvertisement ? 1 : 0)
        .scaleEffect(showAdvertisement ? 1 : 0)
        .frame(height: showAdvertisement ? nil : 0)
        .transaction {
            if reducedMotion { $0.animation = nil }
        }
        .onChange(of: advert) { _ in
            Task {
                await fetchAppIcon()
            }
        }
        
    }
    
    
    private func fetchAppIcon() async {
        if let data = try? await advert.getAppIcon() {
            await MainActor.run {
                appIcon = UIImage(data: data)
            }
        }
    }

    @ViewBuilder
    var backgroundView : some View {
        if #available(iOS 16.0, *) {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(advert.background.gradient)
                .shadow(color: includeShadow ? advert.background.opacity(0.5) : Color.clear, radius: 6, x: 0, y: 2)
        } else {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(advert.background)
                .shadow(color: includeShadow ? advert.background.opacity(0.5) : Color.clear, radius: 6, x: 0, y: 2)
        }
    }
}


struct BillboardBannerView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            BillboardBannerView(advert: BillboardSamples.sampleDefaultAd)
            BillboardBannerView(advert: BillboardSamples.sampleDefaultAd, includeShadow: false)
        }
        .padding()
        
    }
}
