import 'package:flutter/material.dart';
import 'package:scoped_model/scoped_model.dart';

import './address_tag.dart';
import './time_tag.dart';
import '../../models/task.dart';
import '../../scoped-models/main.dart';
import '../ui_elements/title_default.dart';

class TaskCard extends StatelessWidget {
  final Task task;

  TaskCard(this.task);

  Widget _buildTitlePriceRow() {
    return Container(
      padding: EdgeInsets.only(top: 10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Flexible(
            child: TitleDefault(task.title),
          ),
          Flexible(
            child: SizedBox(
              width: 8.0,
            ),
          ),
          Flexible(
            child: TimeTag(task.price.toString()),
          )
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return ScopedModelDescendant<MainModel>(
      builder: (BuildContext context, Widget child, MainModel model) {
        return ButtonBar(
            alignment: MainAxisAlignment.center,
            children: <Widget>[
              IconButton(
                icon: Icon(Icons.info),
                color: Theme.of(context).accentColor,
                onPressed: () {
                  model.selectTask(task.id);
                  Navigator.pushNamed<bool>(context, '/task/' + task.id)
                      .then((_) => model.selectTask(null));
                },
              ),
              IconButton(
                icon: Icon(Icons.thumb_up),
                color: task.isFavorite ? Colors.teal : Colors.red,
                onPressed: () {
                  model.selectTask(task.id);
                  model.toggleTaskFavoriteStatus();
                  if (model.selectedTask.isFavorite) {
                    final snackBar = SnackBar(
                      content: Text(
                          'You have completed this task. Congratulations!!!'),
                      duration: Duration(seconds: 3),
                    );
                    Scaffold.of(context).showSnackBar(snackBar);
                  }
                },
              ),
            ]);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: <Widget>[
          Hero(
            tag: task.id,
            child: FadeInImage(
              image: NetworkImage(task.image),
              height: 300.0,
              fit: BoxFit.cover,
              placeholder: AssetImage('assets/quote.jpg'),
            ),
          ),
          _buildTitlePriceRow(),
          SizedBox(
            height: 10.0,
          ),
          AddressTag(task.location.address),
          _buildActionButtons(context)
        ],
      ),
    );
  }
}
