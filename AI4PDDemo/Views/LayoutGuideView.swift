//
//  LayoutGuideView.swift
//  AI4PDDemo
//
//  Created by Tim_Feige on 09.05.23.
//

import SwiftUI

struct LayoutGuideView: View {
    let layoutGuideFrame: CGRect
    let hasDetectedValidBody: Bool

    var body: some View {
      VStack {
        RoundedRectangle(cornerRadius: 20)
          .stroke(hasDetectedValidBody ? Color.green : Color.red,lineWidth: 6.0)
          .frame(width: layoutGuideFrame.width, height: layoutGuideFrame.height)
      }
    }
}

struct LayoutGuideView_Previews: PreviewProvider {
    static var previews: some View {
        LayoutGuideView(
            layoutGuideFrame: CGRect(x: 0, y: 0, width: 400, height: 700),
            hasDetectedValidBody: true
        )
    }
}
