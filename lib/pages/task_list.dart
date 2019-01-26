import 'package:flutter/material.dart';
import 'package:scoped_model/scoped_model.dart';

import './task_edit.dart';
import '../scoped-models/main.dart';

class TaskListPage extends StatefulWidget {
  final MainModel model;

  TaskListPage(this.model);

  @override
  State<StatefulWidget> createState() {
    return _TaskListPageState();
  }
}

class _TaskListPageState extends State<TaskListPage> {
  @override
  initState() {
    widget.model.fetchTasks(onlyForUser: true, clearExisting: true);
    super.initState();
  }

  Widget _buildEditButton(BuildContext context, int index, MainModel model) {
    return IconButton(
      icon: Icon(Icons.edit),
      onPressed: () {
        model.selectTask(model.allTasks[index].id);
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (BuildContext context) {
              return TaskEditPage();
            },
          ),
        ).then((_) {
          model.selectTask(null);
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ScopedModelDescendant<MainModel>(
      builder: (BuildContext context, Widget child, MainModel model) {
        return ListView.builder(
          itemBuilder: (BuildContext context, int index) {
            return Dismissible(
              key: Key(model.allTasks[index].title),
              onDismissed: (DismissDirection direction) {
                if (direction == DismissDirection.endToStart) {
                  model.selectTask(model.allTasks[index].id);
                  model.deleteTask();
                } else if (direction == DismissDirection.startToEnd) {
                  print('Swiped start to end');
                } else {
                  print('Other swiping');
                }
              },
              background: Container(color: Colors.red),
              child: Column(
                children: <Widget>[
                  ListTile(
                    leading: CircleAvatar(
                      backgroundImage:
                          NetworkImage(model.allTasks[index].image),
                    ),
                    title: Text(model.allTasks[index].title),
                    subtitle:
                        Text('${model.allTasks[index].price.toString()}0'),
                    trailing: _buildEditButton(context, index, model),
                  ),
                  Divider()
                ],
              ),
            );
          },
          itemCount: model.allTasks.length,
        );
      },
    );
  }
}
