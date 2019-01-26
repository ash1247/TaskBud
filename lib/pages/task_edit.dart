import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:scoped_model/scoped_model.dart';

import '../models/location_data.dart';
import '../models/task.dart';
import '../scoped-models/main.dart';
import '../widgets/form_inputs/image.dart';
import '../widgets/form_inputs/location.dart';
import '../widgets/helpers/ensure_visible.dart';
import '../widgets/ui_elements/adapative_progress_indicator.dart';

class TaskEditPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _TaskEditPageState();
  }
}

class _TaskEditPageState extends State<TaskEditPage> {
  final Map<String, dynamic> _formData = {
    'title': null,
    'description': null,
    'price': null,
    'image': null,
    'location': null
  };
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final _titleFocusNode = FocusNode();
  final _descriptionFocusNode = FocusNode();
  final _priceFocusNode = FocusNode();
  final _titleTextController = TextEditingController();
  final _descriptionTextController = TextEditingController();
  final _priceTextController = TextEditingController();

  Widget _buildTitleTextField(Task task) {
    if (task == null && _titleTextController.text.trim() == '') {
      _titleTextController.text = '';
    } else if (task != null && _titleTextController.text.trim() == '') {
      _titleTextController.text = task.title;
    } else if (task != null && _titleTextController.text.trim() != '') {
      _titleTextController.text = _titleTextController.text;
    } else if (task == null && _titleTextController.text.trim() != '') {
      _titleTextController.text = _titleTextController.text;
    } else {
      _titleTextController.text = '';
    }
    return EnsureVisibleWhenFocused(
      focusNode: _titleFocusNode,
      child: TextFormField(
        focusNode: _titleFocusNode,
        decoration: InputDecoration(labelText: 'Task Name'),
        controller: _titleTextController,
        validator: (String value) {
          // if (value.trim().length <= 0) {
          if (value.isEmpty || value.length < 5) {
            return 'Name is required and should be 5+ characters long.';
          }
        },
        onSaved: (String value) {
          _formData['title'] = value;
        },
      ),
    );
  }

  Widget _buildDescriptionTextField(Task task) {
    if (task == null && _descriptionTextController.text.trim() == '') {
      _descriptionTextController.text = '';
    } else if (task != null && _descriptionTextController.text.trim() == '') {
      _descriptionTextController.text = task.description;
    }
    return EnsureVisibleWhenFocused(
      focusNode: _descriptionFocusNode,
      child: TextFormField(
        focusNode: _descriptionFocusNode,
        maxLines: 4,
        decoration: InputDecoration(labelText: 'Task Description'),
        controller: _descriptionTextController,
        validator: (String value) {
          // if (value.trim().length <= 0) {
          if (value.isEmpty || value.length < 10) {
            return 'Description is required and should be 10+ characters long.';
          }
        },
        onSaved: (String value) {
          _formData['description'] = value;
        },
      ),
    );
  }

  Widget _buildPriceTextField(Task task) {
    if (task == null && _priceTextController.text.trim() == '') {
      _priceTextController.text = '';
    } else if (task != null && _priceTextController.text.trim() == '') {
      _priceTextController.text = task.price.toString();
    }
    return EnsureVisibleWhenFocused(
      focusNode: _priceFocusNode,
      child: TextFormField(
        focusNode: _priceFocusNode,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(labelText: 'Task Time'),
        controller: _priceTextController,
        validator: (String value) {
          // if (value.trim().length <= 0) {
          if (value.isEmpty ||
              !RegExp(r'^(?:[1-9]\d*|0)?(?:[.,]\d+)?$').hasMatch(value)) {
            return 'Price is required and should be a number.';
          }
        },
      ),
    );
  }

  Widget _buildSubmitButton() {
    return ScopedModelDescendant<MainModel>(
      builder: (BuildContext context, Widget child, MainModel model) {
        return model.isLoading
            ? Center(
                child: AdaptiveProgressIndicator(),
              )
            : RaisedButton(
                child: Text('Save'),
                textColor: Colors.white,
                onPressed: () => _submitForm(model.addTask, model.updateTask,
                    model.selectTask, model.selectedTaskIndex),
              );
      },
    );
  }

  Widget _buildPageContent(BuildContext context, Task task) {
    final double deviceWidth = MediaQuery.of(context).size.width;
    final double targetWidth = deviceWidth > 550.0 ? 500.0 : deviceWidth * 0.95;
    final double targetPadding = deviceWidth - targetWidth;
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).requestFocus(FocusNode());
      },
      child: Container(
        margin: EdgeInsets.all(10.0),
        child: Form(
          key: _formKey,
          child: ListView(
            padding: EdgeInsets.symmetric(horizontal: targetPadding / 2),
            children: <Widget>[
              _buildTitleTextField(task),
              _buildDescriptionTextField(task),
              _buildPriceTextField(task),
              SizedBox(
                height: 10.0,
              ),
              LocationInput(_setLocation, task),
              SizedBox(height: 10.0),
              ImageInput(_setImage, task),
              SizedBox(
                height: 10.0,
              ),
              _buildSubmitButton(),
              // GestureDetector(
              //   onTap: _submitForm,
              //   child: Container(
              //     color: Colors.green,
              //     padding: EdgeInsets.all(5.0),
              //     child: Text('My Button'),
              //   ),
              // )
            ],
          ),
        ),
      ),
    );
  }

  void _setLocation(LocationData locData) {
    _formData['location'] = locData;
  }

  void _setImage(File image) {
    _formData['image'] = image;
  }

  void _submitForm(
      Function addTask, Function updateTask, Function setSelectedTask,
      [int selectedTaskIndex]) {
    if (!_formKey.currentState.validate() ||
        (_formData['image'] == null && selectedTaskIndex == -1)) {
      return;
    }
    _formKey.currentState.save();
    if (selectedTaskIndex == -1) {
      addTask(
              _titleTextController.text,
              _descriptionTextController.text,
              _formData['image'],
              double.parse(
                  _priceTextController.text.replaceFirst(RegExp(r','), '.')),
              _formData['location'])
          .then((bool success) {
        if (success) {
          Navigator.pushReplacementNamed(context, '/tasks')
              .then((_) => setSelectedTask(null));
        } else {
          showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: Text('Something went wrong'),
                  content: Text('Please try again!'),
                  actions: <Widget>[
                    FlatButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text('Okay'),
                    )
                  ],
                );
              });
        }
      });
    } else {
      updateTask(
        _titleTextController.text,
        _descriptionTextController.text,
        _formData['image'],
        double.parse(_priceTextController.text.replaceFirst(RegExp(r','), '.')),
        _formData['location'],
      ).then((_) => Navigator.pushReplacementNamed(context, '/tasks')
          .then((_) => setSelectedTask(null)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScopedModelDescendant<MainModel>(
      builder: (BuildContext context, Widget child, MainModel model) {
        final Widget pageContent =
            _buildPageContent(context, model.selectedTask);
        return model.selectedTaskIndex == -1
            ? pageContent
            : Scaffold(
                appBar: AppBar(
                  title: Text('Edit Task'),
                  elevation: Theme.of(context).platform == TargetPlatform.iOS
                      ? 0.0
                      : 4.0,
                ),
                body: pageContent,
              );
      },
    );
  }
}
