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
        let max_surfaces = 5

        func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
            //guard let view = self.view else { return }
            //debugPrint("Anchors added to the scene: ", anchors)
        }
        
        func textEntity (words: String, width: Float, height: Float) -> ModelEntity{
            let text_frame = CGRect(x: Double(width / -2), y: Double(height / -1), width: Double(width), height: Double(height))
            let textMesh = MeshResource.generateText(words, extrusionDepth: 10.15, font: UIFont.boldSystemFont(ofSize: 10), containerFrame: text_frame)
            let entity = ModelEntity(mesh: textMesh)
            let material = UnlitMaterial(color: .systemOrange)
            entity.model?.materials = [material]
            return entity
        }
        
        @objc func handleTap(_ sender: UITapGestureRecognizer) {
            guard let view = self.view else { return }
            debugPrint("New tap")
            
            let touchLocation = sender.location(in: view)
            //debugPrint(view.raycast(from: touchLocation, allowing: .existingPlaneGeometry, alignment: .any))
            guard let raycastResult = view.raycast(from: touchLocation, allowing: .existingPlaneGeometry, alignment: .any).first else {
                debugPrint("No surface detected, try getting closer.")
                return
            }
            
            let int_anchor = raycastResult.anchor
            
            if let planeAnchor = int_anchor as? ARPlaneAnchor {
                debugPrint(planeAnchor.planeExtent.width)
                //guard let num_surfaces = self.surfaces?.count else { return <#default value#> }
                let pa_width = planeAnchor.planeExtent.width
                let pa_height = planeAnchor.planeExtent.height
                /*let translation = simd_float4(
                    planeAnchor.center.y,
                    planeAnchor.center.z,
                    planeAnchor.center.x,
                    0
                )*/
                let translation = simd_float4(
                    planeAnchor.center.x,
                    planeAnchor.center.y,
                    planeAnchor.center.x,
                    0
                )
                var transform = planeAnchor.transform
                transform.columns.3 = transform.columns.3 - simd_make_float4(translation)
                let z_angle = simd_float4x4(simd_quatf(angle: -1.5708, axis: simd_float3(1, 0, 0)))
                transform = matrix_multiply(transform, z_angle)
                
                let anchor = AnchorEntity()
                view.scene.anchors.append(anchor)
                
                // Replace this with chosen poems
                let inserted_text = "Test test 1 2 3 testing going on one two three"
                
                let text = textEntity(words: inserted_text, width: pa_width, height: pa_height)
                //let offset = text.visualBounds(relativeTo: nil).extents.x / 2
                //text.position = transform.worldTransform
                debugPrint(text)
                debugPrint(transform.columns.3)
                text.transform = Transform(matrix: transform)
                print(text.position)
                print(anchor.position)
                anchor.addChild(text)
                
                
                /*let box = MeshResource.generateBox(width: Float(planeAnchor.planeExtent.width), height: Float(planeAnchor.planeExtent.height), depth: 0.01)
                let material = UnlitMaterial(color: .systemOrange)
                let text_frame = CGRect(x: Double(pa_width / -2), y: Double(pa_height / -1), width: Double(pa_width), height: Double(pa_height))
                
                
                
                let fontSize = (pa_width * pa_height) / Float(inserted_text.count)
                let fontVar = UIFont.boldSystemFont(ofSize: 0.1)*/
                //let text = MeshResource.generateText(inserted_text, extrusionDepth: 0.01, font: fontVar, containerFrame: text_frame, alignment: .left, lineBreakMode: .byWordWrapping)
                
                /*
                let planeEntity = ModelEntity(mesh: text, materials: [material])
                debugPrint(planeAnchor.transform)
                
                debugPrint(planeAnchor.center)
                var transform = planeAnchor.transform
                transform.columns.3 = transform.columns.3 - simd_make_float4(translation)
                let z_angle = simd_float4x4(simd_quatf(angle: -1.5708, axis: simd_float3(1, 0, 0)))
                transform = matrix_multiply(transform, z_angle)
                
                //planeEntity.position = translation + planeAnchor.center
                //planeEntity.transform.rotation = planeAnchor.transform.rotation
                planeEntity.transform = Transform(matrix: transform)
                debugPrint(planeAnchor.transform)
                debugPrint("New shape!!")
                
                planeEntity.position = [-offset, -0.05, -0.1]
                 */
                
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
