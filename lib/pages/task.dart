import 'dart:async';

import 'package:flutter/material.dart';
import 'package:map_view/map_view.dart';

import '../models/task.dart';
import '../widgets/tasks/task_fab.dart';
import '../widgets/ui_elements/title_default.dart';

class TaskPage extends StatelessWidget {
  final Task task;

  TaskPage(this.task);

  void _showMap() {
    final List<Marker> markers = <Marker>[
      Marker('position', 'Position', task.location.latitude,
          task.location.longitude)
    ];
    final cameraPosition = CameraPosition(
        Location(task.location.latitude, task.location.longitude), 14.0);
    final mapView = MapView();
    mapView.show(
        MapOptions(
            initialCameraPosition: cameraPosition,
            mapViewType: MapViewType.normal,
            title: 'Task Location'),
        toolbarActions: [
          ToolbarAction('Close', 1),
        ]);
    mapView.onToolbarAction.listen((int id) {
      if (id == 1) {
        mapView.dismiss();
      }
    });
    mapView.onMapReady.listen((_) {
      mapView.setMarkers(markers);
    });
  }

  Widget _buildAddressPriceRow(String address, double price) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        GestureDetector(
          onTap: _showMap,
          child: Text(
            address,
            style: TextStyle(fontFamily: 'Oswald', color: Colors.grey),
          ),
        ),
        Container(
          margin: EdgeInsets.symmetric(horizontal: 5.0),
          child: Text(
            '|',
            style: TextStyle(color: Colors.grey),
          ),
        ),
        Text(
          price.toString() + '0',
          style: TextStyle(fontFamily: 'Oswald', color: Colors.grey),
        )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () {
        print('Back button pressed!');
        Navigator.pop(context, false);
        return Future.value(false);
      },
      child: Scaffold(
        // appBar: AppBar(
        //   title: Text(product.title),
        // ),
        body: CustomScrollView(
          slivers: <Widget>[
            SliverAppBar(
              expandedHeight: 256.0,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                title: Text(task.title),
                background: Hero(
                  tag: task.id,
                  child: FadeInImage(
                    image: NetworkImage(task.image),
                    height: 300.0,
                    fit: BoxFit.cover,
                    placeholder: AssetImage('assets/quote.jpg'),
                  ),
                ),
              ),
            ),
            SliverList(
              delegate: SliverChildListDelegate(
                [
                  Container(
                    padding: EdgeInsets.all(10.0),
                    alignment: Alignment.center,
                    child: TitleDefault(task.title),
                  ),
                  _buildAddressPriceRow(task.location.address, task.price),
                  Container(
                    padding: EdgeInsets.all(10.0),
                    child: Text(
                      task.description,
                      textAlign: TextAlign.center,
                    ),
                  )
                ],
              ),
            )
          ],
        ),
        floatingActionButton: TaskFAB(task),
      ),
    );
  }
}
