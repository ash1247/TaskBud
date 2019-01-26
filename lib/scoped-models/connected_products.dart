import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'package:rxdart/subjects.dart';
import 'package:scoped_model/scoped_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/auth.dart';
import '../models/location_data.dart';
import '../models/task.dart';
import '../models/user.dart';
import '../shared/global_config.dart';

class ConnectedTasksModel extends Model {
  List<Task> _tasks = [];
  String _selTaskId;
  User _authenticatedUser;
  bool _isLoading = false;
}

class TasksModel extends ConnectedTasksModel {
  bool _showFavorites = false;

  List<Task> get allTasks {
    return List.from(_tasks);
  }

  List<Task> get displayedTasks {
    if (_showFavorites) {
      return _tasks.where((Task task) => task.isFavorite).toList();
    }
    return List.from(_tasks);
  }

  int get selectedTaskIndex {
    return _tasks.indexWhere((Task task) {
      return task.id == _selTaskId;
    });
  }

  String get selectedTaskId {
    return _selTaskId;
  }

  Task get selectedTask {
    if (selectedTaskId == null) {
      return null;
    }

    return _tasks.firstWhere((Task task) {
      return task.id == _selTaskId;
    });
  }

  bool get displayFavoritesOnly {
    return _showFavorites;
  }

  Future<Map<String, dynamic>> uploadImage(File image,
      {String imagePath}) async {
    final mimeTypeData = lookupMimeType(image.path).split('/');
    final imageUploadRequest = http.MultipartRequest(
        'POST',
        Uri.parse(
            'https://us-central1-flutter-products-85048.cloudfunctions.net/storeImage'));
    final file = await http.MultipartFile.fromPath(
      'image',
      image.path,
      contentType: MediaType(
        mimeTypeData[0],
        mimeTypeData[1],
      ),
    );
    imageUploadRequest.files.add(file);
    if (imagePath != null) {
      imageUploadRequest.fields['imagePath'] = Uri.encodeComponent(imagePath);
    }
    imageUploadRequest.headers['Authorization'] =
        'Bearer ${_authenticatedUser.token}';

    try {
      final streamedResponse = await imageUploadRequest.send();
      final response = await http.Response.fromStream(streamedResponse);
      if (response.statusCode != 200 && response.statusCode != 201) {
        print('Something went wrong');
        print(json.decode(response.body));
        return null;
      }
      final responseData = json.decode(response.body);
      return responseData;
    } catch (error) {
      print(error);
      return null;
    }
  }

  Future<bool> addTask(String title, String description, File image,
      double price, LocationData locData) async {
    _isLoading = true;
    notifyListeners();
    final uploadData = await uploadImage(image);

    if (uploadData == null) {
      print('Upload failed!');
      return false;
    }

    final Map<String, dynamic> taskData = {
      'title': title,
      'description': description,
      'price': price,
      'userEmail': _authenticatedUser.email,
      'userId': _authenticatedUser.id,
      'imagePath': uploadData['imagePath'],
      'imageUrl': uploadData['imageUrl'],
      'loc_lat': locData.latitude,
      'loc_lng': locData.longitude,
      'loc_address': locData.address
    };
    try {
      final http.Response response = await http.post(
          'https://flutter-products-85048.firebaseio.com/products.json?auth=${_authenticatedUser.token}',
          body: json.encode(taskData));

      if (response.statusCode != 200 && response.statusCode != 201) {
        _isLoading = false;
        notifyListeners();
        return false;
      }
      final Map<String, dynamic> responseData = json.decode(response.body);
      final Task newTask = Task(
          id: responseData['name'],
          title: title,
          description: description,
          image: uploadData['imageUrl'],
          imagePath: uploadData['imagePath'],
          price: price,
          location: locData,
          userEmail: _authenticatedUser.email,
          userId: _authenticatedUser.id);
      _tasks.add(newTask);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (error) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
    // .catchError((error) {
    //   _isLoading = false;
    //   notifyListeners();
    //   return false;
    // });
  }

  Future<bool> updateTask(String title, String description, File image,
      double price, LocationData locData) async {
    _isLoading = true;
    notifyListeners();
    String imageUrl = selectedTask.image;
    String imagePath = selectedTask.imagePath;
    if (image != null) {
      final uploadData = await uploadImage(image);

      if (uploadData == null) {
        print('Upload failed!');
        return false;
      }

      imageUrl = uploadData['imageUrl'];
      imagePath = uploadData['imagePath'];
    }
    final Map<String, dynamic> updateData = {
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'imagePath': imagePath,
      'price': price,
      'loc_lat': locData.latitude,
      'loc_lng': locData.longitude,
      'loc_address': locData.address,
      'userEmail': selectedTask.userEmail,
      'userId': selectedTask.userId
    };
    try {
      await http.put(
          'https://flutter-products-85048.firebaseio.com/products/${selectedTask.id}.json?auth=${_authenticatedUser.token}',
          body: json.encode(updateData));
      _isLoading = false;
      final Task updatedTask = Task(
          id: selectedTask.id,
          title: title,
          description: description,
          image: imageUrl,
          imagePath: imagePath,
          price: price,
          location: locData,
          userEmail: selectedTask.userEmail,
          userId: selectedTask.userId);
      _tasks[selectedTaskIndex] = updatedTask;
      notifyListeners();
      return true;
    } catch (error) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteTask() {
    _isLoading = true;
    final deletedTaskId = selectedTask.id;
    _tasks.removeAt(selectedTaskIndex);
    _selTaskId = null;
    notifyListeners();
    return http
        .delete(
            'https://flutter-products-85048.firebaseio.com/products/$deletedTaskId.json?auth=${_authenticatedUser.token}')
        .then((http.Response response) {
      _isLoading = false;
      notifyListeners();
      return true;
    }).catchError((error) {
      _isLoading = false;
      notifyListeners();
      return false;
    });
  }

  Future<Null> fetchTasks({onlyForUser = false, clearExisting = false}) {
    _isLoading = true;
    if (clearExisting) {
      _tasks = [];
    }

    notifyListeners();
    return http
        .get(
            'https://flutter-products-85048.firebaseio.com/products.json?auth=${_authenticatedUser.token}')
        .then<Null>((http.Response response) {
      final List<Task> fetchedTaskList = [];
      final Map<String, dynamic> taskListData = json.decode(response.body);
      if (taskListData == null) {
        _isLoading = false;
        notifyListeners();
        return;
      }
      taskListData.forEach((String taskId, dynamic taskData) {
        final Task task = Task(
            id: taskId,
            title: taskData['title'],
            description: taskData['description'],
            image: taskData['imageUrl'],
            imagePath: taskData['imagePath'],
            price: taskData['price'],
            location: LocationData(
                address: taskData['loc_address'],
                latitude: taskData['loc_lat'],
                longitude: taskData['loc_lng']),
            userEmail: taskData['userEmail'],
            userId: taskData['userId'],
            isFavorite: taskData['wishlistUsers'] == null
                ? false
                : (taskData['wishlistUsers'] as Map<String, dynamic>)
                    .containsKey(_authenticatedUser.id));
        fetchedTaskList.add(task);
      });
      _tasks = onlyForUser
          ? fetchedTaskList.where((Task task) {
              return task.userId == _authenticatedUser.id;
            }).toList()
          : fetchedTaskList;
      _isLoading = false;
      notifyListeners();
      _selTaskId = null;
    }).catchError((error) {
      _isLoading = false;
      notifyListeners();
      return;
    });
  }

  void toggleTaskFavoriteStatus() async {
    final bool isCurrentlyFavorite = selectedTask.isFavorite;
    final bool newFavoriteStatus = !isCurrentlyFavorite;
    final Task updatedTask = Task(
        id: selectedTask.id,
        title: selectedTask.title,
        description: selectedTask.description,
        price: selectedTask.price,
        image: selectedTask.image,
        imagePath: selectedTask.imagePath,
        location: selectedTask.location,
        userEmail: selectedTask.userEmail,
        userId: selectedTask.userId,
        isFavorite: newFavoriteStatus);
    _tasks[selectedTaskIndex] = updatedTask;
    notifyListeners();
    http.Response response;
    if (newFavoriteStatus) {
      response = await http.put(
          'https://flutter-products-85048.firebaseio.com/products/'
          '${selectedTask.id}/wishlistUsers/${_authenticatedUser.id}.json?',
          body: json.encode(true));
    } else {
      response = await http.delete(
          'https://flutter-products-85048.firebaseio.com/products/'
          '${selectedTask.id}/wishlistUsers/${_authenticatedUser.id}.json?');
    }
    if (response.statusCode != 200 && response.statusCode != 201) {
      final Task updatedTask = Task(
          id: selectedTask.id,
          title: selectedTask.title,
          description: selectedTask.description,
          price: selectedTask.price,
          image: selectedTask.image,
          imagePath: selectedTask.imagePath,
          location: selectedTask.location,
          userEmail: selectedTask.userEmail,
          userId: selectedTask.userId,
          isFavorite: !newFavoriteStatus);
      _tasks[selectedTaskIndex] = updatedTask;
      notifyListeners();
    }
    _selTaskId = null;
  }

  void selectTask(String taskId) {
    _selTaskId = taskId;
    if (taskId != null) {
      notifyListeners();
    }
  }

  void toggleDisplayMode() {
    _showFavorites = !_showFavorites;
    notifyListeners();
  }
}

class UserModel extends ConnectedTasksModel {
  Timer _authTimer;
  PublishSubject<bool> _userSubject = PublishSubject();

  User get user {
    return _authenticatedUser;
  }

  PublishSubject<bool> get userSubject {
    return _userSubject;
  }

  Future<Map<String, dynamic>> authenticate(String email, String password,
      [AuthMode mode = AuthMode.Login]) async {
    _isLoading = true;
    notifyListeners();
    final Map<String, dynamic> authData = {
      'email': email,
      'password': password,
      'returnSecureToken': true
    };
    http.Response response;
    if (mode == AuthMode.Login) {
      response = await http.post(
        'https://www.googleapis.com/identitytoolkit/v3/relyingparty/verifyPassword?key=$apiKey',
        body: json.encode(authData),
        headers: {'Content-Type': 'application/json'},
      );
    } else {
      response = await http.post(
        'https://www.googleapis.com/identitytoolkit/v3/relyingparty/signupNewUser?key=$apiKey',
        body: json.encode(authData),
        headers: {'Content-Type': 'application/json'},
      );
    }

    final Map<String, dynamic> responseData = json.decode(response.body);
    bool hasError = true;
    String message = 'Something went wrong.';
    print(responseData);
    if (responseData.containsKey('idToken')) {
      hasError = false;
      message = 'Authentication succeeded!';
      _authenticatedUser = User(
          id: responseData['localId'],
          email: email,
          token: responseData['idToken']);
      setAuthTimeout(int.parse(responseData['expiresIn']));
      _userSubject.add(true);
      final DateTime now = DateTime.now();
      final DateTime expiryTime =
          now.add(Duration(seconds: int.parse(responseData['expiresIn'])));
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      prefs.setString('token', responseData['idToken']);
      prefs.setString('userEmail', email);
      prefs.setString('userId', responseData['localId']);
      prefs.setString('expiryTime', expiryTime.toIso8601String());
    } else if (responseData['error']['message'] == 'EMAIL_EXISTS') {
      message = 'This email already exists.';
    } else if (responseData['error']['message'] == 'EMAIL_NOT_FOUND') {
      message = 'This email was not found.';
    } else if (responseData['error']['message'] == 'INVALID_PASSWORD') {
      message = 'The password is invalid.';
    }
    _isLoading = false;
    notifyListeners();
    return {'success': !hasError, 'message': message};
  }

  void autoAuthenticate() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String token = prefs.getString('token');
    final String expiryTimeString = prefs.getString('expiryTime');
    if (token != null) {
      final DateTime now = DateTime.now();
      final parsedExpiryTime = DateTime.parse(expiryTimeString);
      if (parsedExpiryTime.isBefore(now)) {
        _authenticatedUser = null;
        notifyListeners();
        return;
      }
      final String userEmail = prefs.getString('userEmail');
      final String userId = prefs.getString('userId');
      final int tokenLifespan = parsedExpiryTime.difference(now).inSeconds;
      _authenticatedUser = User(id: userId, email: userEmail, token: token);
      _userSubject.add(true);
      setAuthTimeout(tokenLifespan);
      notifyListeners();
    }
  }

  void logout() async {
    _authenticatedUser = null;
    _authTimer.cancel();
    _userSubject.add(false);
    _selTaskId = null;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.remove('token');
    prefs.remove('userEmail');
    prefs.remove('userId');
  }

  void setAuthTimeout(int time) {
    _authTimer = Timer(Duration(seconds: time), logout);
  }
}

class UtilityModel extends ConnectedTasksModel {
  bool get isLoading {
    return _isLoading;
  }
}
