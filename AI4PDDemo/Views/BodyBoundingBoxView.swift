//
//  BodyBoundingBoxView.swift
//  AI4PDDemo
//
//  Created by Tim_Feige on 09.05.23.
//

import SwiftUI

struct BodyBoundingBoxView: View {
    @ObservedObject private(set) var model: CameraViewModel

    var body: some View {
        switch model.bodyGeometryState {
        case .bodyNotFound:
        Rectangle().fill(Color.clear)
        case .bodyFound(let bodyGeometryModel):
        Rectangle()
          .path(in: CGRect(
            x: bodyGeometryModel.boundingBox.origin.x,
            y: bodyGeometryModel.boundingBox.origin.y,
            width: bodyGeometryModel.boundingBox.width,
            height: bodyGeometryModel.boundingBox.height
          ))
          .stroke(Color.yellow, lineWidth: 2.0)
      case .errored:
        Rectangle().fill(Color.clear)
      }
    }
}

struct BodyBoundingBoxView_Previews: PreviewProvider {
    static var previews: some View {
        BodyBoundingBoxView(model: CameraViewModel())
    }
}
