import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

/// A chat message model.
class _ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  _ChatMessage({
    required this.text,
    required this.isUser,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

/// AI Advisor Screen — chat-style UI with a dynamic list of messages.
/// Satisfies M2 "Dynamic content" and "Interaction" requirements.
class AiAdvisorScreen extends StatefulWidget {
  const AiAdvisorScreen({super.key});

  @override
  State<AiAdvisorScreen> createState() => _AiAdvisorScreenState();
}

class _AiAdvisorScreenState extends State<AiAdvisorScreen> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // Dynamic list of chat messages (the core dynamic collection)
  final List<_ChatMessage> _messages = [
    _ChatMessage(
      text:
          "Hello! 👋 I'm your SmartFinance AI advisor. Ask me anything about budgeting, savings, or your spending habits!",
      isUser: false,
    ),
  ];

  bool _isTyping = false; // simulates AI "thinking" indicator

  // Predefined AI response map for common financial questions
  static const Map<String, String> _aiResponses = {
    'budget':
        '💡 A solid budgeting rule is the 50/30/20 method: 50% on needs, 30% on wants, and 20% on savings. Based on your transactions, try capping daily spending at 60% of your income.',
    'save':
        '🏦 The best time to save is right when your salary arrives — transfer it before you spend. Even saving UGX 5,000/day adds up to UGX 150,000/month!',
    'spend':
        '📊 Your recent transactions show higher spending on Food and Transport. Consider meal-prepping to cut food costs by up to 30%.',
    'airtime':
        '📱 Airtime purchases seem frequent. Switching to weekly bundles instead of daily top-ups could save you up to 20% on data costs.',
    'invest':
        '📈 For beginners in Uganda, consider Unit Trusts (e.g., UAP, Britam) or Treasury Bills as low-risk starting points before stocks.',
    'debt':
        '💳 Rule of thumb: always pay high-interest debt first (credit cards, mobile loans). Never take a new loan to pay an old one.',
    'hello':
        "Hi there! 😊 I'm ready to help. You can ask me about budgeting, how to save more, or what to do with your salary.",
    'help':
        "I can help you with:\n• 📊 Analysing your spending\n• 💰 Building a savings plan\n• 📈 Basic investment advice\n• 💡 Daily money tips\n\nJust type your question!",
  };

  String _generateResponse(String userMessage) {
    final lower = userMessage.toLowerCase();
    for (final keyword in _aiResponses.keys) {
      if (lower.contains(keyword)) return _aiResponses[keyword]!;
    }
    return "🤔 Great question! For personalised advice, I'd recommend reviewing your last 30 days of transactions. Generally: track every shilling, set a daily limit, and always pay yourself first.";
  }

  Future<void> _sendMessage() async {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;

    // Add user message
    setState(() {
      _messages.add(_ChatMessage(text: text, isUser: true));
      _isTyping = true;
    });
    _inputController.clear();
    _scrollToBottom();

    // Simulate AI processing delay
    await Future.delayed(const Duration(milliseconds: 1200));

    if (!mounted) return;

    // Add AI response
    setState(() {
      _messages.add(_ChatMessage(text: _generateResponse(text), isUser: false));
      _isTyping = false;
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgGradientStart,

      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 1,
        shadowColor: Colors.white10,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.primary.withValues(alpha: 0.3),
              child: const Icon(
                Icons.smart_toy_outlined,
                color: Colors.white70,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('AI Finance Advisor', style: AppTextStyles.body.copyWith(
                  fontSize: 15,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                )),
                Text(
                  _isTyping ? 'typing...' : 'Online',
                  style: AppTextStyles.body.copyWith(
                    fontSize: 12,
                    color: _isTyping ? Colors.amber : AppColors.successGreen,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),

      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.bgGradientStart, Color(0xFF1E0A3C)],
          ),
        ),
        child: Column(
          children: [
            // ── Message list ───────────────────────────────────────────────
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: _messages.length + (_isTyping ? 1 : 0),
                itemBuilder: (context, index) {
                  // Show typing indicator at the end
                  if (_isTyping && index == _messages.length) {
                    return _buildTypingIndicator();
                  }
                  final msg = _messages[index];
                  return _buildMessageBubble(msg);
                },
              ),
            ),

            // ── Quick suggestion chips ─────────────────────────────────────
            _buildSuggestionChips(),

            // ── Input bar ──────────────────────────────────────────────────
            _buildInputBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(_ChatMessage msg) {
    final isUser = msg.isUser;

    return Padding(
      padding: EdgeInsets.only(
        bottom: 12,
        left: isUser ? 60 : 0,
        right: isUser ? 0 : 60,
      ),
      child: Column(
        crossAxisAlignment:
            isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          // Avatar row
          if (!isUser)
            Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.3),
                  child: const Icon(
                    Icons.smart_toy_outlined,
                    size: 14,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'AI Advisor',
                  style: AppTextStyles.body.copyWith(
                    fontSize: 11,
                    color: Colors.white54,
                  ),
                ),
              ],
            ),
          if (!isUser) const SizedBox(height: 4),

          // Bubble
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isUser
                  ? AppColors.primary
                  : Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(18),
                topRight: const Radius.circular(18),
                bottomLeft: isUser
                    ? const Radius.circular(18)
                    : const Radius.circular(4),
                bottomRight: isUser
                    ? const Radius.circular(4)
                    : const Radius.circular(18),
              ),
              border: isUser
                  ? null
                  : Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Text(msg.text, style: AppTextStyles.body.copyWith(
              color: Colors.white,
              fontSize: 15,
              height: 1.4,
            )),
          ),

          // Timestamp
          const SizedBox(height: 4),
          Text(
            _formatTime(msg.timestamp),
            style: AppTextStyles.body.copyWith(
              fontSize: 10,
              color: Colors.white30,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, right: 60),
      child: Row(
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: AppColors.primary.withValues(alpha: 0.3),
            child: const Icon(
              Icons.smart_toy_outlined,
              size: 14,
              color: Colors.white70,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) {
                return _AnimatedDot(delay: i * 200);
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionChips() {
    final suggestions = [
      'How to save more?',
      'Analyse my spending',
      'Investment tips',
      'Help',
    ];
    return SizedBox(
      height: 44,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: suggestions.length,
        itemBuilder: (_, i) => GestureDetector(
          onTap: () {
            _inputController.text = suggestions[i];
            _sendMessage();
          },
          child: Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
            ),
            child: Text(
              suggestions[i],
              style: AppTextStyles.body.copyWith(
                fontSize: 12,
                color: Colors.white70,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      color: const Color(0xFF0F172A),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _inputController,
              style: AppTextStyles.body.copyWith(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Ask a financial question...',
                hintStyle: AppTextStyles.body.copyWith(color: Colors.white38),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.05),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide(
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: const BorderSide(color: AppColors.primary),
                ),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(Icons.send_rounded, color: Colors.white, size: 22),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

/// Simple bouncing dot for the "AI is typing" indicator.
class _AnimatedDot extends StatefulWidget {
  final int delay;
  const _AnimatedDot({required this.delay});

  @override
  State<_AnimatedDot> createState() => _AnimatedDotState();
}

class _AnimatedDotState extends State<_AnimatedDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0, end: -6).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (_, __) => Transform.translate(
        offset: Offset(0, _animation.value),
        child: Container(
          width: 8,
          height: 8,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          decoration: BoxDecoration(
            color: Colors.white54,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }
}
