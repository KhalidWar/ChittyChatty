import 'package:chittychatty/screens/settings/settings_screen.dart';
import 'package:chittychatty/services/chat_service.dart';
import 'package:chittychatty/utilities/confirmation_dialog.dart';
import 'package:chittychatty/widgets/alert_widget.dart';
import 'package:chittychatty/widgets/chat_list_tile.dart';
import 'package:chittychatty/widgets/fab_open_container.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/all.dart';

import '../constants.dart';
import 'chat/chat_room_screen.dart';
import 'chat/start_new_chat_screen.dart';

final chatStream = StreamProvider.autoDispose<QuerySnapshot>((ref) {
  return ref.read(chatServiceProvider).getChatRooms();
});

class HomeScreen extends ConsumerWidget {
//   static const String id = 'home_screen';
//   @override
//   _HomeScreenState createState() => _HomeScreenState();
// }
//
// class _HomeScreenState extends State<HomeScreen> {
  // String currentUserEmail;
  // String currentUserName;
  // String _lastMessage;

  @override
  Widget build(BuildContext context, ScopedReader watch) {
    final stream = watch(chatStream);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Theme.of(context).scaffoldBackgroundColor,
      ),
      child: Scaffold(
        appBar: buildAppBar(context),
        floatingActionButton: FABOpenContainer(
          heroTag: 'chatTab',
          iconData: Icons.chat,
          child: StartNewChatScreen(),
        ),
        body: StreamBuilder(
          stream: context.read(chatServiceProvider).getChatRooms(),
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
                if (snapshot.data.documents.isEmpty) {
                  return AlertWidget(lottie: 'assets/lottie/booGhost.json');
                } else if (snapshot.hasData) {
                  return ListView.builder(
                    shrinkWrap: true,
                    physics: BouncingScrollPhysics(),
                    itemCount: snapshot.data.documents.length,
                    itemBuilder: (BuildContext context, int index) {
                      final data = snapshot.data.documents[index].data();
                      String name, email, profilePic;

                      if (data['users'][1]['email'] ==
                          FirebaseAuth.instance.currentUser.email) {
                        name = data['users'][0]['name'];
                        email = data['users'][0]['email'];
                        profilePic = data['users'][0]['profilePic'];
                      } else {
                        name = data['users'][1]['name'];
                        email = data['users'][1]['email'];
                        profilePic = data['users'][1]['profilePic'];
                      }

                      //todo fix lastMessage
                      // context
                      //     .read(chatServiceProvider)
                      //     .getLastMessage(data['chatRoomID'])
                      //     .then((value) {
                      //   _lastMessage = value;
                      // });

                      return ChatListTile(
                        userName: name,
                        profilePic: profilePic,
                        lastMessage: '_lastMessage',
                        index: index,
                        onPress: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ChatRoomScreen(
                                name: name,
                                email: email,
                                profilePic: profilePic,
                                chatRoomID: data['chatRoomID'],
                                index: index,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  );
                } else if (snapshot.hasError) {
                  return AlertWidget(
                    iconData: Icons.warning_amber_rounded,
                    label: 'Something went wrong\n${snapshot.error}',
                    buttonLabel: 'Sign out',
                    buttonOnPress: () => ConfirmationDialogs().signOut(context),
                  );
                } else {
                  return Center(child: CircularProgressIndicator());
                }
            }
          },
        ),
      ),
    );
  }

  AppBar buildAppBar(BuildContext context) {
    return AppBar(
      brightness: Brightness.dark,
      title: Text('Chitty Chatty'),
      actions: [
        IconButton(
          icon: Icon(Icons.settings),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) {
                  return SettingsScreen();
                },
              ),
            );
          },
        ),
      ],
    );
  }
}
