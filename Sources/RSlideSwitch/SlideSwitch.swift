//
//  SlideSwitch.swift
//  DemoApp
//
//  Created by rajasekar.r on 09/12/24.
//

import SwiftUI
import Combine

public struct SlideSwitch<Label: View>: View {
    @Binding public var isOn: Bool
    public var label: () -> Label
    
    @State private var progress: CGFloat = 0
    public var body: some View {
        GeometryReader { geometry in
            let baseOffset = -geometry.size.width / 2 + geometry.size.height / 2
            
            let dragGesture = DragGesture().onChanged { newValue in
                let width = newValue.translation.width
                withAnimation(.interactiveSpring) {
                    let offset = min(max(baseOffset, baseOffset + width), abs(baseOffset))
                    progress = mapToProgress(value: offset, rangeMin: baseOffset, rangeMax: -baseOffset)
                }
                
            }.onEnded { endValue in
                let width = endValue.predictedEndTranslation.width + baseOffset
                withAnimation(.snappy) {
                    let newConfig = width > 0
                    progress = newConfig ? 1 : 0
                    
                    if newConfig, newConfig != isOn {
                        let impactMed = UIImpactFeedbackGenerator(style: .soft)
                        impactMed.impactOccurred()
                        DispatchQueue.main
                            .asyncAfter(deadline: .now() + 0.3) { isOn = newConfig }
                    } else {
                        isOn = newConfig
                    }
                }
            }
            
            ZStack {
                Capsule()
                    .foregroundStyle(Color.orange)
                    .frame(width: !isOn ? geometry.size.width : geometry.size.height)
                
                ZStack {
                    Circle()
                        .foregroundStyle(.white)
                    Image(systemName: "arrow.right")
                        .font(.system(size: 18, weight: .semibold))
                }
                .foregroundStyle(.orange)
                .rotationEffect(.degrees(-mapToValue(progress: progress, rangeMin: 0, rangeMax: 180)))
                .offset(x: mapToValue(progress: progress, rangeMin: baseOffset, rangeMax: -baseOffset))
                .scaleEffect(!isOn ? 1 : 0)
                .padding(3)
                
                if isOn {
                    ProgressView()
                        .transition(.scale)
                } else {
                    label()
                        .foregroundStyle(.white)
                        .opacity(1 - progress)
                        .transition(.opacity)
                }
                
                
            }
            .frame(width: geometry.size.width)
            .onAppear {
                progress = !isOn ? 0 : 1
            }
            .onChange(of: isOn, perform: { newValue in
                progress = mapToProgress(value: !isOn ? baseOffset : 0, rangeMin: baseOffset, rangeMax: -baseOffset)
            })
            .gesture(dragGesture)
            
        }
        .animation(.snappy, value: isOn)
    }
}

public func mapToProgress(value: CGFloat, rangeMin: CGFloat, rangeMax: CGFloat) -> CGFloat {
    let normalisedValue = min(max(value, rangeMin), rangeMax)
    let progress = Double(normalisedValue - rangeMin) / Double(rangeMax - rangeMin)
    return progress
}

public func mapToValue(progress: CGFloat, rangeMin: CGFloat, rangeMax: CGFloat) -> CGFloat {
    let normalisedProgress = min(max(progress, 0), 1)
    return rangeMin + normalisedProgress * (rangeMax - rangeMin)
}


public struct SlideSwitchToggleStyle: ToggleStyle {
    public init() {}
    public func makeBody(configuration: Configuration) -> some View {
        let slideSwitch = SlideSwitch(isOn: configuration.$isOn) {
            configuration.label
        }
        return slideSwitch
    }
}


//#Preview {
//    @Previewable @State var isOn: Bool = false
//    Toggle(isOn: $isOn, label: {
//        Text("Slide to Run")
//            .font(.system(size: 14))
//    })
//    .frame(width: 200, height: 50)
//    .toggleStyle(SlideSwitchToggleStyle())
//}
