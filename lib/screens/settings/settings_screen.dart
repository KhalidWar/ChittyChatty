import 'package:animations/animations.dart';
import 'package:chittychatty/services/user_service.dart';
import 'package:chittychatty/utilities/confirmation_dialog.dart';
import 'package:chittychatty/utilities/form_validator.dart';
import 'package:chittychatty/widgets/alert_widget.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../constants.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key key}) : super(key: key);

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _textEditingController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  void _updateName() {
    if (_formKey.currentState.validate()) {
      context
          .read(userServiceProvider)
          .updateUserName(_textEditingController.text.trim());
      _textEditingController.clear();
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.red,
      ),
      child: Scaffold(
        appBar: buildAppBar(),
        body: StreamBuilder(
          stream: context.read(userServiceProvider).getCurrentUserStream(),
          builder: (BuildContext context, AsyncSnapshot snapshot) {
            switch (snapshot.connectionState) {
              case ConnectionState.none:
                return AlertWidget(
                  lottie: kLottieErrorCone,
                  label: kSomethingWentWrong,
                );
              case ConnectionState.waiting:
                return Center(child: CircularProgressIndicator());
              default:
                if (snapshot.hasData) {
                  final data = snapshot.data.docs[0].data();

                  return Column(
                    children: [
                      Container(
                        height: size.height * 0.3,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            GestureDetector(
                              onTap: () {},
                              child: CircleAvatar(
                                backgroundImage:
                                    NetworkImage('${data['profilePic']}'),
                                radius: 80,
                              ),
                            ),
                            Positioned(
                              bottom: 50,
                              right: 5,
                              child: Container(
                                padding: EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.blue,
                                  borderRadius: BorderRadius.circular(50),
                                ),
                                child: Icon(Icons.camera_alt_outlined),
                              ),
                            )
                          ],
                        ),
                      ),
                      ListTile(
                        leading: Icon(Icons.account_circle_outlined, size: 40),
                        title: Text('${data['name']}',
                            style: Theme.of(context).textTheme.bodyText1),
                        subtitle: Text('Tap to change your name'),
                        onTap: () => showModal(
                            context: context,
                            builder: (context) {
                              return buildAlertDialog(data, context);
                            }),
                      ),
                      ListTile(
                        leading: Icon(Icons.email_outlined, size: 40),
                        title: Text('${data['email']}',
                            style: Theme.of(context).textTheme.bodyText1),
                        subtitle: Text(
                            'Manage email settings including email notifications'),
                        onTap: () {},
                      ),
                      ListTile(
                        leading: Icon(Icons.lock_outline, size: 40),
                        title: Text('Security & Privacy',
                            style: Theme.of(context).textTheme.bodyText1),
                        subtitle:
                            Text('Manage password, 2FA, and linked accounts'),
                        onTap: () {},
                      ),
                      ListTile(
                        leading:
                            Icon(Icons.notifications_none_outlined, size: 40),
                        title: Text('Notifications',
                            style: Theme.of(context).textTheme.bodyText1),
                        subtitle: Text('Manage App Notifications'),
                        onTap: () {},
                      ),
                      Spacer(),
                      Container(
                        width: double.infinity,
                        height: size.height * 0.05,
                        child: RaisedButton(
                          color: Colors.red,
                          child: Text('Log Out',
                              style: Theme.of(context).textTheme.headline6),
                          onPressed: () =>
                              ConfirmationDialogs().signOut(context),
                        ),
                      ),
                    ],
                  );
                } else if (snapshot.hasError) {
                  return Center(child: Text('${snapshot.error}'));
                }
            }
            return Center(child: CircularProgressIndicator());
          },
        ),
      ),
    );
  }

  AlertDialog buildAlertDialog(data, BuildContext context) {
    return AlertDialog(
      contentPadding: EdgeInsets.all(10),
      title: Text('Change name'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Form(
            key: _formKey,
            child: TextFormField(
              controller: _textEditingController,
              validator: (input) => FormValidator().updateNameField(input),
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              decoration: kTextFormInputDecoration.copyWith(
                  hintText: '${data['name']}'),
            ),
          ),
        ],
      ),
      actions: [
        RaisedButton(
          child: Text('Update name'),
          onPressed: () => _updateName(),
        ),
        RaisedButton(
          child: Text('Cancel'),
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }

  AppBar buildAppBar() {
    return AppBar(
      brightness: Brightness.dark,
      title: Text('Settings'),
    );
  }
}
