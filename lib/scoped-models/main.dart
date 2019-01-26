import 'package:scoped_model/scoped_model.dart';

import './connected_products.dart';

class MainModel extends Model
    with ConnectedTasksModel, UserModel, TasksModel, UtilityModel {}
