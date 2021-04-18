import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_icons/flutter_icons.dart';
import 'package:provider/provider.dart';
import 'package:social_media_app/components/chat_item.dart';
import 'package:social_media_app/models/message.dart';
import 'package:social_media_app/utils/firebase.dart';
import 'package:social_media_app/view_models/user/user_view_model.dart';
import 'package:social_media_app/widgets/indicators.dart';

class Chats extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    UserViewModel viewModel =
        Provider.of<UserViewModel>(context, listen: false);
    viewModel.setUser();
    return Scaffold(
      appBar: AppBar(
        title: Text("Chats"),
        // actions: [
        //   Padding(
        //     padding: const EdgeInsets.all(15.0),
        //     child: GestureDetector(
        //       //Feature coming soon
        //       onTap: (){},
        //       child: Icon(Feather.search),
        //     ),
        //   )
        // ],
      ),
      body: StreamBuilder(
          stream: userChatsStream('${viewModel.user?.uid ?? ""}'),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              List chatList = snapshot.data.documents;
              if (chatList.isNotEmpty) {
                return ListView.separated(
                  itemCount: chatList.length,
                  itemBuilder: (BuildContext context, int index) {
                    DocumentSnapshot chatListSnapshot = chatList[index];
                    return StreamBuilder(
                      stream: messageListStream(chatListSnapshot.id),
                      builder: (context, snapshot) {
                        if (snapshot.hasData) {
                          List messages = snapshot.data.documents;
                          Message message =
                              Message.fromJson(messages.first.data());
                          List users = chatListSnapshot.data()['users'];
                          // remove the current user's id from the Users
                          // list so we can get the second user's id
                          users.remove('${viewModel.user?.uid ?? ""}');
                          String recipient = users[0];
                          return ChatItem(
                            userId: recipient,
                            messageCount: messages?.length,
                            msg: message?.content,
                            time: message?.time,
                            chatId: chatListSnapshot.id,
                            type: message?.type,
                            currentUserId: viewModel.user?.uid ?? "",
                          );
                        } else {
                          return SizedBox();
                        }
                      },
                    );
                  },
                  separatorBuilder: (BuildContext context, int index) {
                    return Align(
                      alignment: Alignment.centerRight,
                      child: Container(
                        height: 0.5,
                        width: MediaQuery.of(context).size.width / 1.3,
                        child: Divider(),
                      ),
                    );
                  },
                );
              } else {
                return Center(child: Text('No Chats'));
              }
            } else {
              return Center(
                child: circularProgress(context),
              );
            }
          }),
    );
  }

  Stream<QuerySnapshot> userChatsStream(String uid) {
    return chatRef.where('users', arrayContains: '$uid').snapshots();
  }

  Stream<QuerySnapshot> messageListStream(String documentId) {
    return chatRef.doc(documentId).collection('messages').snapshots();
  }
}
