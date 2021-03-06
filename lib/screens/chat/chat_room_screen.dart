import 'package:chittychatty/models/message.dart';
import 'package:chittychatty/services/chat_service.dart';
import 'package:chittychatty/utilities/confirmation_dialog.dart';
import 'package:chittychatty/widgets/alert_widget.dart';
import 'package:chittychatty/widgets/message_tile.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../constants.dart';

class ChatRoomScreen extends StatefulWidget {
  const ChatRoomScreen({
    Key key,
    this.name,
    this.profilePic,
    this.chatRoomID,
    this.email,
    this.index,
  }) : super(key: key);

  final String name, email, profilePic, chatRoomID;
  final int index;

  @override
  _ChatRoomScreenState createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final currentUserEmail = FirebaseAuth.instance.currentUser.email;

  final _messageInputController = TextEditingController();

  void _sendMessage() async {
    if (_messageInputController.text.isNotEmpty) {
      final message = Message(
          message: _messageInputController.text,
          time: Timestamp.now(),
          sender: currentUserEmail);
      await context
          .read(chatServiceProvider)
          .addMessage(widget.chatRoomID, message);
      _messageInputController.clear();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Can not send empty message'),
          behavior: SnackBarBehavior.floating));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Theme.of(context).scaffoldBackgroundColor,
      ),
      child: Scaffold(
        appBar: buildAppBar(context),
        body: Column(
          children: [
            Expanded(
              child: StreamBuilder(
                stream: context
                    .read(chatServiceProvider)
                    .getChatMessages(widget.chatRoomID),
                builder: (BuildContext context, AsyncSnapshot snapshot) {
                  switch (snapshot.connectionState) {
                    case ConnectionState.none:
                      return AlertWidget(
                        label: kNoInternetConnection,
                        iconData: Icons.warning_amber_rounded,
                      );
                    case ConnectionState.waiting:
                      return Center(child: CircularProgressIndicator());
                    default:
                      if (snapshot.hasData) {
                        return ListView.builder(
                            padding: EdgeInsets.symmetric(horizontal: 12),
                            physics: BouncingScrollPhysics(),
                            reverse: true,
                            itemCount: snapshot.data.documents.length,
                            itemBuilder: (BuildContext context, int index) {
                              final data =
                                  snapshot.data.documents[index].data();
                              return MessageTile(
                                message: data['message'],
                                time: data['time'],
                                sender: data['sender'] == currentUserEmail,
                              );
                            });
                      } else if (snapshot.hasError) {
                        return AlertWidget(
                          iconData: Icons.warning_amber_rounded,
                          label: 'Something went wrong\n${snapshot.error}',
                          buttonLabel: 'Sign out',
                          buttonOnPress: () =>
                              ConfirmationDialogs().signOut(context),
                        );
                      } else {
                        return Center(child: CircularProgressIndicator());
                      }
                  }
                },
              ),
            ),
            Container(
              margin: EdgeInsets.only(right: 8, left: 8, bottom: 10, top: 5),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                border: Border.all(color: Colors.blue),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Row(
                children: <Widget>[
                  //todo open emoji keyboard
                  IconButton(
                    icon: Icon(Icons.emoji_emotions_outlined),
                    onPressed: () {},
                  ),
                  Expanded(
                    child: TextFormField(
                      controller: _messageInputController,
                      textInputAction: TextInputAction.send,
                      onFieldSubmitted: (value) => _sendMessage(),
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Message...',
                      ),
                    ),
                  ),
                  //todo access camera feed to capture photos
                  IconButton(
                    icon: Icon(Icons.camera_alt_outlined),
                    onPressed: () {},
                  ),
                  IconButton(
                    icon: Icon(Icons.send),
                    onPressed: () => _sendMessage(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  AppBar buildAppBar(BuildContext context) {
    return AppBar(
      brightness: Brightness.dark,
      title: ListTile(
        contentPadding: EdgeInsets.all(0),
        selected: false,
        leading: Hero(
            tag: widget.index ?? 0,
            child:
                CircleAvatar(backgroundImage: NetworkImage(widget.profilePic))),
        title: Text(widget.name, style: Theme.of(context).textTheme.headline6),
        subtitle: Text(widget.email),
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.info_outline),
          onPressed: () {},
        ),
      ],
    );
  }
}
