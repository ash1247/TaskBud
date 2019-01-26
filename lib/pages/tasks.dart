import 'package:flutter/material.dart';
import 'package:scoped_model/scoped_model.dart';

import '../scoped-models/main.dart';
import '../widgets/tasks/tasks.dart';
import '../widgets/ui_elements/logout_list_tile.dart';

class TasksPage extends StatefulWidget {
  final MainModel model;

  TasksPage(this.model);

  @override
  State<StatefulWidget> createState() {
    return _TasksPageState();
  }
}

class _TasksPageState extends State<TasksPage> {
  @override
  initState() {
    widget.model.fetchTasks();
    super.initState();
  }

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
            leading: Icon(Icons.edit),
            title: Text('Manage Your Tasks'),
            onTap: () {
              Navigator.pushReplacementNamed(context, '/admin');
            },
          ),
          Divider(),
          LogoutListTile()
        ],
      ),
    );
  }

  Widget _buildTasksList() {
    return ScopedModelDescendant(
      builder: (BuildContext context, Widget child, MainModel model) {
        Widget content = Center(child: Text('No Tasks Found!'));
        if (model.displayedTasks.length > 0 && !model.isLoading) {
          content = Tasks();
        } else if (model.isLoading) {
          content = Center(child: CircularProgressIndicator());
        }
        return RefreshIndicator(
          onRefresh: model.fetchTasks,
          child: content,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: _buildSideDrawer(context),
      appBar: AppBar(
        title: Text('TaskBud'),
        elevation: Theme.of(context).platform == TargetPlatform.iOS ? 0.0 : 4.0,
        actions: <Widget>[],
      ),
      body: _buildTasksList(),
    );
  }
}
