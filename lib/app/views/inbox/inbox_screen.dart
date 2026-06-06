import 'package:flutter/material.dart';

/// Inbox screen — a clean notifications and messaging center.
class InboxScreen extends StatelessWidget {
  const InboxScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Mock conversations
    final conversations = [
      {
        'name': 'Priya Sharma',
        'avatar': 'https://images.unsplash.com/photo-1589156280159-27698a70f29e?w=150',
        'message': 'Bhai video gazab था! Kahan shoot kiya?',
        'time': '2m ago',
        'unread': true,
      },
      {
        'name': 'Amit Patel',
        'avatar': 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150',
        'message': 'Bro next video kab aa raha hai?',
        'time': '1h ago',
        'unread': false,
      },
      {
        'name': 'Rahul Verma',
        'avatar': 'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=150',
        'message': 'Party kab de raha hai bhai, video viral ho gaya!',
        'time': '3h ago',
        'unread': false,
      },
      {
        'name': 'Pooja Sen',
        'avatar': 'https://images.unsplash.com/photo-1614089145363-af5e7b68267e?w=150',
        'message': 'Aesthetic music ka link bhej na please.',
        'time': '1d ago',
        'unread': false,
      },
    ];

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'All Activity',
          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.send_rounded, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // Quick activity filter icons
          _buildQuickActivityFilters(),
          const Divider(color: Colors.white12, height: 1),

          // Messages list
          Expanded(
            child: ListView.builder(
              itemCount: conversations.length,
              physics: const BouncingScrollPhysics(),
              itemBuilder: (context, index) {
                final chat = conversations[index];
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  leading: CircleAvatar(
                    radius: 24,
                    backgroundImage: NetworkImage(chat['avatar'] as String),
                  ),
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        chat['name'] as String,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        chat['time'] as String,
                        style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      chat['message'] as String,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: (chat['unread'] as bool) ? Colors.white : Colors.white54,
                        fontSize: 13,
                        fontWeight: (chat['unread'] as bool) ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ),
                  trailing: (chat['unread'] as bool)
                      ? Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFFFF2D55),
                            shape: BoxShape.circle,
                          ),
                        )
                      : null,
                  onTap: () {},
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActivityFilters() {
    final filters = [
      {'name': 'Likes', 'icon': Icons.favorite_rounded, 'color': const Color(0xFFFF2D55)},
      {'name': 'Comments', 'icon': Icons.comment_rounded, 'color': Colors.blueAccent},
      {'name': 'Mentions', 'icon': Icons.alternate_email_rounded, 'color': Colors.greenAccent},
      {'name': 'Followers', 'icon': Icons.person_add_rounded, 'color': Colors.orangeAccent},
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: filters.map((f) {
          return Column(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: (f['color'] as Color).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(f['icon'] as IconData, color: f['color'] as Color, size: 20),
              ),
              const SizedBox(height: 8),
              Text(
                f['name'] as String,
                style: const TextStyle(color: Colors.white70, fontSize: 11),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}
