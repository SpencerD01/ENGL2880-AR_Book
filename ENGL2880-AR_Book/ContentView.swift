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
        
        @objc func handleTap(_ sender: UITapGestureRecognizer) {
            guard let view = self.view else { return }
            debugPrint("New tap")
            
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
                
                
                let anchor = AnchorEntity()
                view.scene.anchors.append(anchor)
                
                let box = MeshResource.generateBox(width: Float(planeAnchor.planeExtent.width), height: Float(planeAnchor.planeExtent.height), depth: 0.01)
                let material = SimpleMaterial(color: .white, isMetallic: false)
                let text = MeshResource.generateText("Testing TESTING TESTRINGRTGDSKLFNSALKFJAKLF", extrusionDepth: 0.01, alignment: .center, lineBreakMode: .byWordWrapping)
                let planeEntity = ModelEntity(mesh: box, materials: [material])
                debugPrint(planeAnchor.transform)
                let translation = simd_float3(
                    planeAnchor.transform.columns.3.x,
                    planeAnchor.transform.columns.3.y,
                    planeAnchor.transform.columns.3.z
                )
                debugPrint(planeAnchor.center)
                var transform = planeAnchor.transform
                transform.columns.3 = transform.columns.3 + simd_make_float4(planeAnchor.center * 2)
                let z_angle = simd_float4x4(simd_quatf(angle: -1.5708, axis: simd_float3(1, 0, 0)))
                transform = matrix_multiply(transform, z_angle)
                
                //planeEntity.position = translation + planeAnchor.center
                //planeEntity.transform.rotation = planeAnchor.transform.rotation
                planeEntity.transform = Transform(matrix: transform)
                debugPrint(planeAnchor.transform)
                debugPrint("New shape!!")
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
