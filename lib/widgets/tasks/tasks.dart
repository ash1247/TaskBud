import 'package:flutter/material.dart';
import 'package:scoped_model/scoped_model.dart';

import './task_card.dart';
import '../../models/task.dart';
import '../../scoped-models/main.dart';

class Tasks extends StatelessWidget {
  Widget _buildTaskList(List<Task> tasks) {
    Widget taskCards;
    if (tasks.length > 0) {
      taskCards = ListView.builder(
        itemBuilder: (BuildContext context, int index) =>
            TaskCard(tasks[index]),
        itemCount: tasks.length,
      );
    } else {
      taskCards = Container();
    }
    return taskCards;
  }

  @override
  Widget build(BuildContext context) {
    print('[Tasks Widget] build()');
    return ScopedModelDescendant<MainModel>(
      builder: (BuildContext context, Widget child, MainModel model) {
        return _buildTaskList(model.displayedTasks);
      },
    );
  }
}
