//
//  SelectableText.swift
//  MacGptChatLegacy
//
//  Created by User2 on 11/9/24.
//
import SwiftUI

struct SelectableText: NSViewRepresentable {
    let text: String
    
    final class Coordinator: NSObject {
        var text: String
        var textView: NSTextView?
        
        init(text: String) {
            self.text = text
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(text: text)
    }
    
    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        let textView = NSTextView()
        
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        
        textView.isEditable = false
        textView.isSelectable = true
        textView.font = .systemFont(ofSize: NSFont.systemFontSize)
        
        // Set up text container
        let contentSize = scrollView.contentSize
        textView.minSize = NSSize(width: 0, height: 0)
        textView.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        textView.textContainer?.containerSize = NSSize(width: contentSize.width, height: CGFloat.greatestFiniteMagnitude)
        textView.textContainer?.widthTracksTextView = true
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.autoresizingMask = [.width]
        
        // Set initial text
        textView.string = text
        
        scrollView.documentView = textView
        context.coordinator.textView = textView
        
        return scrollView
    }
    
    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = scrollView.documentView as? NSTextView else { return }
        
        // Only update if text has changed
        if textView.string != text {
            let selectedRanges = textView.selectedRanges
            textView.string = text
            textView.selectedRanges = selectedRanges
            
            // Scroll to bottom
            textView.scrollToEndOfDocument(nil)
        }
    }
}
