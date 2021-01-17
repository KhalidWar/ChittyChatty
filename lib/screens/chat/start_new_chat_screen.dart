import 'package:chittychatty/models/app_user.dart';
import 'package:chittychatty/services/chat_service.dart';
import 'package:chittychatty/services/user_service.dart';
import 'package:chittychatty/utilities/form_validator.dart';
import 'package:chittychatty/utilities/utilities.dart';
import 'package:chittychatty/widgets/error_message_alert.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../constants.dart';
import 'chat_room_screen.dart';

class StartNewChatScreen extends StatefulWidget {
  const StartNewChatScreen({Key key}) : super(key: key);

  @override
  _StartNewChatScreenState createState() => _StartNewChatScreenState();
}

List<AppUser> _recentSearchList = [];

class _StartNewChatScreenState extends State<StartNewChatScreen> {
  final _userDBService = UserService();
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _textEditingController = TextEditingController();

  QuerySnapshot _searchSnapshot;
  QuerySnapshot _currentUserSnapshot;
  String _error;

  void _searchByEmailAddress() {
    if (_formKey.currentState.validate()) {
      context
          .read(userServiceProvider)
          .searchUserByEmail(_textEditingController.text.trim())
          .then(
        (value) {
          if (value.docs.isEmpty) {
            setState(() {
              _error = 'No user with this email found';
              _searchSnapshot = null;
            });
          } else {
            _searchSnapshot = value;
            _recentSearchList.add(AppUser.fromJson(value.docs[0].data()));
            _error = null;
          }
        },
      );
    }
  }

  void _createChatRoom({Map<String, dynamic> searchedUserData}) async {
    final currentUser = AppUser.fromJson(_currentUserSnapshot.docs[0].data());
    final searchedUser = AppUser.fromJson(searchedUserData);

    if (searchedUser.email == currentUser.email) {
      setState(() {
        _error = 'You cannot chat with yourself';
      });
    } else {
      List<Map<String, dynamic>> users = [
        currentUser.toJson(),
        searchedUser.toJson(),
      ];

      String chatRoomID =
          Utilities().getChatRoomID(searchedUser.email, currentUser.email);

      Map<String, Object> chatRoomMap = {
        'users': users,
        'chatRoomID': chatRoomID,
        'emails': [currentUser.email, searchedUser.email]
      };

      ChatService().createChatRoom(chatRoomID, chatRoomMap);

      Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) => ChatRoomScreen(
                    name: searchedUser.name,
                    email: searchedUser.email,
                    profilePic: searchedUser.profilePic,
                    chatRoomID: chatRoomID,
                  )));
    }
  }

  @override
  void initState() {
    super.initState();
    _userDBService
        .searchUserByEmail(FirebaseAuth.instance.currentUser.email)
        .then((value) => _currentUserSnapshot = value);
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Theme.of(context).scaffoldBackgroundColor,
      ),
      child: Scaffold(
        appBar: buildAppBar(context),
        body: SingleChildScrollView(
          child: Column(
            children: [
              ErrorMessageAlert(errorMessage: _error),
              Padding(
                padding: EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Form(
                      key: _formKey,
                      child: TextFormField(
                        controller: _textEditingController,
                        textInputAction: TextInputAction.search,
                        onFieldSubmitted: (value) => _searchByEmailAddress(),
                        validator: (input) =>
                            FormValidator().searchByEmail(input),
                        decoration: kTextFormInputDecoration.copyWith(
                          hintText: 'Search by Email Address...',
                        ),
                      ),
                    ),
                    SizedBox(height: size.height * 0.02),
                    _searchSnapshot == null
                        ? Container()
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Search Result',
                                  style: Theme.of(context).textTheme.headline6),
                              ListView.builder(
                                shrinkWrap: true,
                                itemCount: _searchSnapshot.docs.length,
                                itemBuilder: (BuildContext context, int index) {
                                  final data =
                                      _searchSnapshot.docs[index].data();
                                  return Column(
                                    children: [
                                      GestureDetector(
                                        onTap: () => _createChatRoom(
                                            searchedUserData: data),
                                        child: ListTile(
                                          leading: CircleAvatar(
                                              backgroundImage: NetworkImage(
                                                  data['profilePic'])),
                                          title: Text(data['name']),
                                          subtitle: Text(data['email']),
                                          trailing: Icon(Icons.send),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ],
                          ),
                    Divider(),
                    Text('Recently searched',
                        style: Theme.of(context).textTheme.headline6),
                    _recentSearchList.isEmpty
                        ? Text('No Recent Search')
                        : ListView.builder(
                            shrinkWrap: true,
                            reverse: true,
                            itemCount: _recentSearchList.length,
                            itemBuilder: (BuildContext context, int index) {
                              final data = _recentSearchList[index];
                              return GestureDetector(
                                onTap: () => _createChatRoom(
                                    searchedUserData: data.toJson()),
                                child: ListTile(
                                  leading: CircleAvatar(
                                      backgroundImage:
                                          NetworkImage(data.profilePic)),
                                  title: Text(data.name),
                                  subtitle: Text(data.email),
                                  trailing: Icon(Icons.send),
                                ),
                              );
                            },
                          ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  AppBar buildAppBar(BuildContext context) {
    return AppBar(
      brightness: Brightness.dark,
      elevation: 0,
      title: Text('Start New Chat'),
      actions: [
        IconButton(
          icon: Icon(Icons.search),
          onPressed: () => _searchByEmailAddress(),
        ),
      ],
    );
  }
}
