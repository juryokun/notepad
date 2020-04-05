import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:selectable_autolink_text/selectable_autolink_text.dart';
import 'package:url_launcher/url_launcher.dart';
// import 'package:flutter_share/flutter_share.dart';
import 'package:share/share.dart';

class ChatPage extends StatefulWidget {
  ChatPage(this._userName, this._channelId);

  final String _userName;
  var _channelId;

  @override
  _ChatPageState createState() => new _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _controller = TextEditingController();
  var _channelId;
  @override
  Widget build(BuildContext context) {
    _channelId = widget._channelId;
    return new Scaffold(
        appBar: new AppBar(
          title: new Text("チャットページ"),
        ),
        drawer: Drawer(
          child: StreamBuilder<QuerySnapshot>(
              stream: Firestore.instance
                  .collection("channels")
                  .orderBy("created_at", descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return null;
                final channels = snapshot.data.documents;
                return ListView.builder(
                  itemCount: channels.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return DrawerHeader(
                        child: Text(
                          'Channels',
                          style: TextStyle(
                            fontSize: 24,
                            color: Colors.white,
                          ),
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue,
                        ),
                      );
                    }
                    return ListTile(
                      title: Text(channels[index - 1]['name']),
                      onTap: () {
                        Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                                builder: (builder) => ChatPage(
                                    'test', channels[index - 1]['id'])));
                      },
                    );
                  },
                );
              }),
        ),
        body: Container(
          margin: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Column(
            children: <Widget>[
              Flexible(
                child: StreamBuilder<QuerySnapshot>(
                  stream: Firestore.instance
                      .collection("chat_room")
                      .where("channelId", isEqualTo: _channelId)
                      .orderBy("created_at", descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return Container();
                    return new ListView.builder(
                      padding: new EdgeInsets.all(8.0),
                      reverse: true,
                      itemBuilder: (_, int index) {
                        DocumentSnapshot document =
                            snapshot.data.documents[index];

                        return _message(
                            document['message'], document['created_at']);
                      },
                      itemCount: snapshot.data.documents.length,
                    );
                  },
                ),
              ),
              new Divider(height: 1.0),
              Container(
                margin: EdgeInsets.only(bottom: 20.0, right: 10.0, left: 10.0),
                child: Row(
                  children: <Widget>[
                    new Flexible(
                      child: new TextField(
                        controller: _controller,
                        onSubmitted: _handleSubmit,
                        keyboardType: TextInputType.multiline,
                        maxLines: null,
                        decoration:
                            new InputDecoration.collapsed(hintText: "メッセージの送信"),
                      ),
                    ),
                    new Container(
                      child: new IconButton(
                          icon: new Icon(
                            Icons.send,
                            color: Colors.blue,
                          ),
                          onPressed: () {
                            _handleSubmit(_controller.text);
                          }),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ));
  }

  Widget _message(String message, Timestamp createdAt) {
    return Wrap(
      children: <Widget>[
        // Icon(Icons.person),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            SizedBox(
              height: 10.0,
            ),
            Divider(height: 1.0),
            Padding(padding: EdgeInsets.only(top: 5)),
            GestureDetector(
              child: Text(DateFormat('M月dd日 HH時mm分').format(createdAt.toDate()),
                  style: TextStyle(fontSize: 13)),
              onTap: () => _showPopupMenu(1),
              onLongPress: () => _showPopupMenu(2),
            ),
            Padding(padding: EdgeInsets.only(top: 3)),
            SelectableAutoLinkText(
              message,
              linkStyle: TextStyle(color: Colors.blueAccent),
              highlightedLinkStyle: TextStyle(
                color: Colors.blueAccent,
                backgroundColor: Color(0x33448AFF),
              ),
              style: TextStyle(fontSize: 18),
              onTap: (url) => launch(url, forceSafariVC: false),
              onLongPress: (url) => Share.share(url),
            ),
            Padding(padding: EdgeInsets.only(top: 15.0)),
          ],
        ),
      ],
    );
  }

  _handleSubmit(String message) {
    _controller.text = "";
    var db = Firestore.instance;
    db.collection("chat_room").add({
      "user_name": widget._userName,
      "channelId": _channelId,
      "message": message,
      "created_at": DateTime.now()
    }).then((val) {
      print("成功です");
    }).catchError((err) {
      print(err);
    });
  }

  _showPopupMenu(int id) {
    print(id);
  }
}
