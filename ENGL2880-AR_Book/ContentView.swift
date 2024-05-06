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
        config.planeDetection = [.vertical/*, .horizontal*/]
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
        let model = Resnet50Int8LUT()
        let max_surfaces = 5

        func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
            //guard let view = self.view else { return }
            //debugPrint("Anchors added to the scene: ", anchors)
        }
        
        func return_string() -> String {
            let target_width = 224
            let target_height = 224
            let current_frame = self.view?.session.currentFrame
            guard let imageBuffer = current_frame?.capturedImage else { return "[Insert poem here]" }

            let imageSize = CGSize(width: CVPixelBufferGetWidth(imageBuffer), height: CVPixelBufferGetHeight(imageBuffer))
            let viewPortSize = CGSize(width: target_width, height: target_height)

            let interfaceOrientation : UIInterfaceOrientation
            interfaceOrientation = UIApplication.shared.statusBarOrientation

            let image = CIImage(cvImageBuffer: imageBuffer)
            debugPrint(image.extent)

            // The camera image doesn't match the view rotation and aspect ratio
            // Transform the image:

            // 1) Convert to "normalized image coordinates"
            let normalizeTransform = CGAffineTransform(scaleX: 1.0/imageSize.width, y: 1.0/imageSize.height)

            // 2) Flip the Y axis (for some mysterious reason this is only necessary in portrait mode)
            let flipTransform = (interfaceOrientation.isPortrait) ? CGAffineTransform(scaleX: -1, y: -1).translatedBy(x: -1, y: -1) : .identity

            // 3) Apply the transformation provided by ARFrame
            // This transformation converts:
            // - From Normalized image coordinates (Normalized image coordinates range from (0,0) in the upper left corner of the image to (1,1) in the lower right corner)
            // - To view coordinates ("a coordinate space appropriate for rendering the camera image onscreen")
            // See also: https://developer.apple.com/documentation/arkit/arframe/2923543-displaytransform

            guard let displayTransform = self.view?.session.currentFrame?.displayTransform(for: interfaceOrientation, viewportSize: viewPortSize) else { return "[Error: Display transform failed]" }

            // 4) Convert to view size
            let toViewPortTransform = CGAffineTransform(scaleX: viewPortSize.width, y: viewPortSize.height)

            let cropRect = CGRect(
                x: Double(1920 - target_width) / 2.0,
                y: Double(1440 - target_width) / 2.0,
                width: viewPortSize.width,
                height: viewPortSize.height
            ).integral
            
            // Transform the image and crop it to the viewport
            let transformedImage = image.cropped(to: cropRect)
            debugPrint(type(of: transformedImage))
            debugPrint(transformedImage.extent)
            
            var pixelBuffer: CVPixelBuffer?
            let attrs = [kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue,
                         kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue] as CFDictionary
            let width:Int = target_width
            let height:Int = target_height
            CVPixelBufferCreate(kCFAllocatorDefault,
                                width,
                                height,
                                kCVPixelFormatType_32BGRA,
                                attrs,
                                &pixelBuffer)
            let context = CIContext()
            context.render(transformedImage, to: pixelBuffer!)
            debugPrint("trans size:")
            debugPrint(transformedImage.extent)
            debugPrint(cropRect.size)
            debugPrint(type(of: pixelBuffer))
            let predicted_type = try? model.prediction(image: pixelBuffer!)
            debugPrint(CVPixelBufferGetHeight(pixelBuffer!))
            
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
                //guard let num_surfaces = self.surfaces?.count else { return <#default value#> }
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
            

            

            // Add the sticky note to the scene's entity hierarchy.
            //arView.scene.addAnchor(frame)

            // Add the sticky note's view to the view hierarchy.
            //guard let stickyView = frame.view else { return }
            //arView.insertSubview(stickyView, belowSubview: trashZone)

        }
    }
    
}

#Preview {
    ContentView()
}
