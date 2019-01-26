import 'package:flutter/material.dart';

import './task_edit.dart';
import './task_list.dart';
import '../scoped-models/main.dart';
import '../widgets/ui_elements/logout_list_tile.dart';

class TasksAdminPage extends StatelessWidget {
  final MainModel model;

  TasksAdminPage(this.model);

  Widget _buildSideDrawer(BuildContext context) {
    return Drawer(
      child: Column(
        children: <Widget>[
          AppBar(
            automaticallyImplyLeading: false,
            title: Text('Choose'),
            elevation:
                Theme.of(context).platform == TargetPlatform.iOS ? 0.0 : 4.0,
          ),
          ListTile(
            leading: Icon(Icons.local_library),
            title: Text('All Tasks'),
            onTap: () {
              Navigator.pushReplacementNamed(context, '/');
            },
          ),
          Divider(),
          LogoutListTile()
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        drawer: _buildSideDrawer(context),
        appBar: AppBar(
          title: Text('Manage Tasks'),
          elevation:
              Theme.of(context).platform == TargetPlatform.iOS ? 0.0 : 4.0,
          bottom: TabBar(
            tabs: <Widget>[
              Tab(
                icon: Icon(Icons.create),
                text: 'Create Task',
              ),
              Tab(
                icon: Icon(Icons.list),
                text: 'My Tasks',
              ),
            ],
          ),
        ),
        body: TabBarView(
          children: <Widget>[TaskEditPage(), TaskListPage(model)],
        ),
      ),
    );
  }
}
