//
//  ContentView.swift
//  ENGL2880-AR_Book
//
//  Created by Spencer Dunn on 3/27/24.
//

import SwiftUI
import RealityKit
import ARKit
import SceneKit
import UIKit

struct ContentView : View {
    var body: some View {
        ARViewContainer().edgesIgnoringSafeArea(.all)
    }
}

struct ARViewContainer: UIViewRepresentable {
    
    
    func makeUIView(context: Context) -> ARView {
        
        let arView = ARView(frame: .zero)

        let session = arView.session
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.vertical, .horizontal]
        config.environmentTexturing = .automatic
        session.run(config)
        
        let coachingOverlay = ARCoachingOverlayView()
        coachingOverlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        coachingOverlay.session = session
        coachingOverlay.goal = .horizontalPlane
        arView.addSubview(coachingOverlay)
        
        #if DEBUG
        arView.debugOptions = [.showAnchorGeometry, .showAnchorOrigins]
        #endif
        
        // Handle ARSession events via delegate
        context.coordinator.view = arView
        session.delegate = context.coordinator
        
        arView.addGestureRecognizer(
            UITapGestureRecognizer(
                target: context.coordinator,
                action: #selector(Coordinator.handleTap)
            )
        )
        
        return arView
        
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator: NSObject, ARSessionDelegate {
        weak var view: ARView?
        var surfaces: [ModelEntity]?
        let model = ARPlaneDetection_2()
        let max_surfaces = 5
        var context = CIContext()

        func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
            guard let view = self.view else { return }
        }
        
        func assertCropAndScaleValid(_ pixelBuffer: CVPixelBuffer, _ cropRect: CGRect, _ scaleSize: CGSize) {
            let originalWidth: CGFloat = CGFloat(CVPixelBufferGetWidth(pixelBuffer))
            let originalHeight: CGFloat = CGFloat(CVPixelBufferGetHeight(pixelBuffer))

            assert(CGRect(x: 0, y: 0, width: originalWidth, height: originalHeight).contains(cropRect))
            assert(scaleSize.width > 0 && scaleSize.height > 0)
        }

        func createCroppedPixelBufferCoreImage(pixelBuffer: CVPixelBuffer,
                                               cropRect: CGRect,
                                               scaleSize: CGSize,
                                               context: inout CIContext
        ) -> CVPixelBuffer {
            assertCropAndScaleValid(pixelBuffer, cropRect, scaleSize)
            var image = CIImage(cvImageBuffer: pixelBuffer)
            image = image.cropped(to: cropRect)

            let scaleX = scaleSize.width / image.extent.width
            let scaleY = scaleSize.height / image.extent.height

            image = image.transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))
            image = image.transformed(by: CGAffineTransform(translationX: -image.extent.origin.x, y: -image.extent.origin.y))

            var output: CVPixelBuffer? = nil

            CVPixelBufferCreate(nil, Int(image.extent.width), Int(image.extent.height), kCVPixelFormatType_32BGRA, nil, &output)

            if output != nil {
                context.render(image, to: output!)
            } else {
                fatalError("Error")
            }
            return output!
        }
        
        func return_string() -> String {
            let target_width = 224
            let target_height = 224
            let current_frame = self.view?.session.currentFrame
            guard let imageBuffer = current_frame?.capturedImage else { return "[Insert poem here]" }

            let viewPortSize = CGSize(width: target_width, height: target_height)
            let scale = CGSize(width: 224.0, height: 224.0)
            let cropRect = CGRect(
                x: Double(1920 - target_width) / 2.0,
                y: Double(1440 - target_width) / 2.0,
                width: viewPortSize.width,
                height: viewPortSize.height
            ).integral
            debugPrint(cropRect)
            
            let cropped_image = createCroppedPixelBufferCoreImage(pixelBuffer: imageBuffer, cropRect: cropRect, scaleSize: scale, context: &context)
            
            debugPrint(CVPixelBufferGetWidth(cropped_image))
            debugPrint(CVPixelBufferGetHeight(cropped_image))
            let predicted_type = try? model.prediction(image: cropped_image)
            
            return predicted_type?.classLabel ?? "[Error, no label found]"
        }
        
        @objc func handleTap(_ sender: UITapGestureRecognizer) {
            guard let view = self.view else { return }
            debugPrint("New tap")
            debugPrint(return_string())
            
            let touchLocation = sender.location(in: view)
            debugPrint(view.raycast(from: touchLocation, allowing: .existingPlaneGeometry, alignment: .any))
            guard let raycastResult = view.raycast(from: touchLocation, allowing: .existingPlaneGeometry, alignment: .any).first else {
                debugPrint("No surface detected, try getting closer.")
                return
            }
            
            let int_anchor = raycastResult.anchor
            
            if let planeAnchor = int_anchor as? ARPlaneAnchor {
                debugPrint(planeAnchor.planeExtent)
                let pa_width = Double(planeAnchor.planeExtent.width)
                let pa_height = Double(planeAnchor.planeExtent.height)
                let pa_x = Double(planeAnchor.center.x)
                let pa_y = Double(planeAnchor.center.y)
                
                let frame_width = pa_width * 0.75
                let frame_height = pa_height * 0.75
                
                let anchor = AnchorEntity()
                view.scene.anchors.append(anchor)
                
                //let box = MeshResource.generateBox(width: Float(pa_width / 2), height: Float(pa_height / 2), depth: 0.01)
                let material = SimpleMaterial(color: .white, isMetallic: false)
                
                let message = return_string()
                
                let font_size = frame_width * frame_height * 2.0 / Double(message.count)
                
                let text_frame = CGRect(x: pa_x - frame_width / 2, y: pa_y - frame_height, width: frame_width, height: frame_height)
                
                let text = MeshResource.generateText(message, extrusionDepth: 0.01, font: UIFont.boldSystemFont(ofSize: font_size), containerFrame: text_frame, alignment: .left, lineBreakMode: .byWordWrapping)
                let planeEntity = ModelEntity(mesh: text, materials: [material])
                debugPrint(planeAnchor.transform)
                //var trans_matrix = matrix_identity_float4x4
                //let translation = simd_float4(
                //    planeAnchor.center.x,
                //    planeAnchor.center.z * -1,
                //    planeAnchor.center.y,
                //    0
                //)
                let offset = simd_float3(
                    0,
                    0,
                    0
                )
                //trans_matrix.columns.3 = translation + offset
                debugPrint(planeAnchor.center)
                var transform = planeAnchor.transform
                //transform.columns.3 = transform.columns.3 + translation + offset
                
                let z_angle = simd_float4x4(simd_quatf(angle: -1.5708, axis: simd_float3(1, 0, 0)))
                transform = matrix_multiply(transform, z_angle)
                //transform = matrix_multiply(trans_matrix, transform)
                //transform.columns.3 = transform.columns.3 + translation + offset
                
                //planeEntity.position = translation + planeAnchor.center
                //planeEntity.transform.rotation = planeAnchor.transform.rotation
                planeEntity.transform = Transform(matrix: transform)
                //planeEntity.position = planeEntity.position + offset
                debugPrint(planeEntity.transform)
                debugPrint("New shape!!")
                debugPrint(planeEntity.position)
                anchor.addChild(planeEntity)
              }
            else {
                debugPrint("Not a ARPlaneAnchor: ", type(of: int_anchor))
                view.session.remove(anchor: int_anchor!)
            }
        }
    }
    
}

#Preview {
    ContentView()
}
