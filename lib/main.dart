import 'package:flutter/material.dart';
import 'package:map_view/map_view.dart';
import 'package:scoped_model/scoped_model.dart';

import './models/task.dart';
import './pages/auth.dart';
import './pages/task.dart';
import './pages/tasks.dart';
import './pages/tasks_admin.dart';
import './scoped-models/main.dart';
import './shared/adaptive_theme.dart';
import './shared/global_config.dart' show apiKey;
import './widgets/helpers/custom_route.dart';
// import 'package:flutter/rendering.dart';

void main() {
  // debugPaintSizeEnabled = true;
  // debugPaintBaselinesEnabled = true;
  // debugPaintPointersEnabled = true;
  MapView.setApiKey(apiKey);
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _MyAppState();
  }
}

class _MyAppState extends State<MyApp> {
  final MainModel _model = MainModel();
  bool _isAuthenticated = false;

  @override
  void initState() {
    _model.autoAuthenticate();
    _model.userSubject.listen((bool isAuthenticated) {
      setState(() {
        _isAuthenticated = isAuthenticated;
      });
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    print('building main page');
    return ScopedModel<MainModel>(
      model: _model,
      child: MaterialApp(
        title: 'TaskBud',
        // debugShowMaterialGrid: true,
        theme: getAdaptiveThemeData(context),
//        home: AuthPage(),
        routes: {
          '/': (BuildContext context) =>
              !_isAuthenticated ? AuthPage() : TasksPage(_model),
          '/admin': (BuildContext context) =>
              !_isAuthenticated ? AuthPage() : TasksAdminPage(_model),
        },
        onGenerateRoute: (RouteSettings settings) {
          if (!_isAuthenticated) {
            return MaterialPageRoute<bool>(
              builder: (BuildContext context) => AuthPage(),
            );
          }
          final List<String> pathElements = settings.name.split('/');
          if (pathElements[0] != '') {
            return null;
          }
          if (pathElements[1] == 'task') {
            final String taskId = pathElements[2];
            final Task task = _model.allTasks.firstWhere((Task task) {
              return task.id == taskId;
            });
            return CustomRoute<bool>(
              builder: (BuildContext context) =>
                  !_isAuthenticated ? AuthPage() : TaskPage(task),
            );
          }
          return null;
        },
        onUnknownRoute: (RouteSettings settings) {
          return MaterialPageRoute(
              builder: (BuildContext context) =>
                  !_isAuthenticated ? AuthPage() : TasksPage(_model));
        },
      ),
    );
  }
}
