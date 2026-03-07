// import 'dart:io';

// import 'package:csv/csv.dart';
// import 'package:flutter/material.dart';
// import 'package:graphic/graphic.dart';
// import 'package:timezone/data/latest.dart';
// import 'package:timezone/timezone.dart';
// // import 'graphic_lite/graphic_lite.dart' as lite;

// void main() {
//   initializeTimeZones();
//   runApp(const MyApp());
// }

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Graphic with big data',
//       theme: ThemeData(colorScheme: .fromSeed(seedColor: Colors.deepPurple)),
//       home: const MyHomePage(title: 'Graphic with big data'),
//     );
//   }
// }

// class MyHomePage extends StatefulWidget {
//   const MyHomePage({super.key, required this.title});

//   final String title;

//   @override
//   State<MyHomePage> createState() => _MyHomePageState();
// }

// class _MyHomePageState extends State<MyHomePage> {
//   late List<Map<String, Object>> data = [];

//   @override
//   void initState() {
//     super.initState();
//     final location = getLocation('America/New_York');
//     var aux = csv.decode(File('lib/assets/big_data.csv').readAsStringSync());
//     data = aux.skip(1).map((e) {
//       return <String, Object>{
//         'hour_beginning': TZDateTime.parse(location, e[0]) as DateTime,
//         'ptid': e[1] as String,
//         'mcc': double.parse(e[2]),
//       };
//     }).toList();
//     print(data.length);
//     print(data.take(3).toList());
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         backgroundColor: Theme.of(context).colorScheme.inversePrimary,
//         title: Text(widget.title),
//       ),
//       body: Center(
//         child: Column(
//           mainAxisAlignment: .center,
//           children: [
//             Container(
//               padding: const EdgeInsets.all(32.0),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: <Widget>[
//                   SizedBox(
//                     height: 500,
//                     child: Chart(
//                       data: data,
//                       variables: {
//                         'hour_beginning': Variable(
//                           accessor: (Map map) =>
//                               map['hour_beginning'] as DateTime,
//                         ),
//                         'mcc': Variable(
//                           accessor: (Map map) => map['mcc'] as num,
//                         ),
//                         'ptid': Variable(
//                           accessor: (Map map) => map['ptid'] as String,
//                         ),
//                       },
//                       marks: [
//                         LineMark(
//                           position:
//                               Varset('hour_beginning') *
//                               Varset('mcc') /
//                               Varset('ptid'),
//                           color: ColorEncode(
//                             variable: 'ptid',
//                             values: List.generate(
//                               150,
//                               (i) => lite.Defaults.colors,
//                             ).expand((e) => e).toList(),
//                           ),
//                         ),
//                       ],
//                       coord: RectCoord(
//                         horizontalRange: [0, 1],
//                         verticalRange: [0, 1],
//                       ),
//                       axes: [
//                         AxisGuide(
//                           grid: Defaults.strokeStyle,
//                           label: LabelStyle(
//                             textStyle: lite.Defaults.textStyle,
//                             offset: const Offset(0, 7.5),
//                           ),
//                         ),
//                         AxisGuide(
//                           grid: Defaults.strokeStyle,
//                           label: LabelStyle(
//                             textStyle: lite.Defaults.textStyle,
//                             offset: const Offset(-7.5, 0),
//                           ),
//                         ),
//                       ],
//                       selections: {
//                         // 'choose': IntervalSelection(),
//                         'touchMove': PointSelection(
//                           on: {
//                             GestureType.tapDown,
//                             // GestureType.scaleEnd,
//                             // GestureType.longPressMoveUpdate,
//                           },
//                           dim: Dim.x,
//                         ),
//                         'zoom': IntervalSelection(dim: Dim.x),
//                       },
//                       tooltip: TooltipGuide(
//                         followPointer: [false, true],
//                         align: Alignment.topLeft,
//                         offset: const Offset(-20, -20),
//                       ),
//                       // crosshair: CrosshairGuide(
//                       //   followPointer: [false, false],
//                       // ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
