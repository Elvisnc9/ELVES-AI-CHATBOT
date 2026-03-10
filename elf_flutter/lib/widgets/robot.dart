import 'package:flutter/material.dart';
import 'package:o3d/o3d.dart';

class Robot extends StatefulWidget {
  const Robot({super.key});

  @override
  State<Robot> createState() => _RobotState();
}

class _RobotState extends State<Robot> {

  O3DController controller = O3DController();

  @override
  Widget build(BuildContext context) {
    // return O3D.asset(
    //   src : 'assets/mech_drone.glb',
    //   autoPlay: true,
    //   cameraControls: false,      
    //   disableZoom: true,
    //   disablePan: true,
    //   disableTap: true,
    //   controller: controller,
    //   cameraOrbit: CameraOrbit(
    //     180, 85,  0.2
    //   ),
    //   cameraTarget: CameraTarget(0, 0.3, 0),
    // );
  

  return CircularProgressIndicator();
  }
}