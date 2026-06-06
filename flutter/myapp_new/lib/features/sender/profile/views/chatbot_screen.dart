import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../../core/utils/api_config.dart';
import '../../../../core/utils/session_manager.dart';

// ── Design tokens ──────────────────────────────────────────────
const _bgDeep = Color(0xFF080D1A);
const _bgCard = Color(0xFF0F1628);
const _bgSurface = Color(0xFF162036);
const _accent = Color(0xFF2D7EFF);
const _accentGlow = Color(0x222D7EFF);
const _textPri = Color(0xFFECF1FF);
const _textSec = Color(0xFF6B7FA8);
const _divider = Color(0xFF1E2C45);
const _userBubble = Color(0xFF1A56DB);
const _botBubble = Color(0xFF0F1628);
// ───────────────────────────────────────────────────────────────

class ChatMessage {
  final String text;
  final bool isUser;
  ChatMessage({required this.text, required this.isUser});
}

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  List<ChatMessage> _messages = [];
  bool _isLoading = false;
  int? _userId;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);
    _userId = await SessionManager.getUserId();

    if (_userId != null) {
      try {
        final response = await http.get(
          Uri.parse('${ApiConfig.baseUrl}/chatbot/history/$_userId'),
        );
        if (response.statusCode == 200) {
          List<dynamic> historyData = jsonDecode(
            utf8.decode(response.bodyBytes),
          );
          if (!mounted) return;
          setState(() {
            if (historyData.isEmpty) {
              _messages.add(
                ChatMessage(
                  text:
                      "Xin chào! Mình là trợ lý AI của SmartShip. Mình có thể giúp gì cho bạn về giá cước, lộ trình hay các vấn đề vận chuyển?",
                  isUser: false,
                ),
              );
            } else {
              _messages = historyData
                  .map(
                    (msg) => ChatMessage(
                      text: msg['content'],
                      isUser: msg['role'] == 'USER',
                    ),
                  )
                  .toList();
            }
          });
        }
      } catch (e) {
        debugPrint("Lỗi tải lịch sử chat: $e");
      }
    }

    if (!mounted) return;
    setState(() => _isLoading = false);
    _scrollToBottom();
  }

  Future<void> _sendMessage() async {
    if (_controller.text.trim().isEmpty || _isLoading) return;

    final userMessage = _controller.text.trim();
    setState(() {
      _messages.add(ChatMessage(text: userMessage, isUser: true));
      _isLoading = true;
      _controller.clear();
    });
    _scrollToBottom();

    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/chatbot/ask'),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode({'userId': _userId ?? 0, 'message': userMessage}),
      );

      if (!mounted) return;
      if (response.statusCode == 200) {
        final botReply =
            jsonDecode(utf8.decode(response.bodyBytes))['reply'] as String;
        setState(
          () => _messages.add(ChatMessage(text: botReply, isUser: false)),
        );
      } else {
        setState(
          () => _messages.add(
            ChatMessage(
              text: "Lỗi kết nối! Vui lòng thử lại sau.",
              isUser: false,
            ),
          ),
        );
      }
    } catch (_) {
      if (!mounted) return;
      setState(
        () => _messages.add(
          ChatMessage(text: "Không thể kết nối đến máy chủ.", isUser: false),
        ),
      );
    } finally {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 120), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgDeep,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _messages.isEmpty && _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: _accent,
                      strokeWidth: 2,
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                    itemCount: _messages.length + (_isLoading ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _messages.length) {
                        return _buildTypingIndicator();
                      }
                      return _buildChatBubble(_messages[index], index);
                    },
                  ),
          ),
          _buildInputBar(),
        ],
      ),
    );
  }

  // ── Header ───────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        color: _bgCard,
        border: Border(bottom: BorderSide(color: _divider)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 16, 12),
          child: Row(
            children: [
              // Back button
              IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: _textPri,
                  size: 18,
                ),
                onPressed: () => Navigator.pop(context),
              ),
              // Bot avatar
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _accentGlow,
                  border: Border.all(
                    color: _accent.withValues(alpha: 0.4),
                    width: 1.5,
                  ),
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: _accent,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'SmartShip AI',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: _textPri,
                      ),
                    ),
                    Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFF00D68F),
                          ),
                        ),
                        const SizedBox(width: 5),
                        const Text(
                          'Trực tuyến',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF00D68F),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Clear chat hint
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: _bgSurface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _divider),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.support_agent_rounded,
                      color: _textSec,
                      size: 14,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Hỗ trợ AI',
                      style: TextStyle(fontSize: 11, color: _textSec),
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

  // ── Chat bubble ──────────────────────────────────────────────
  Widget _buildChatBubble(ChatMessage message, int index) {
    final isUser = message.isUser;
    final isFirst = index == 0 || _messages[index - 1].isUser != message.isUser;

    return Padding(
      padding: EdgeInsets.only(top: isFirst ? 12 : 3, bottom: 2),
      child: Row(
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            // Bot avatar (only on first of group)
            if (isFirst)
              Container(
                width: 28,
                height: 28,
                margin: const EdgeInsets.only(right: 8, bottom: 2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _accentGlow,
                  border: Border.all(
                    color: _accent.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: _accent,
                  size: 14,
                ),
              )
            else
              const SizedBox(width: 36),
          ],
          // Bubble
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.72,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              decoration: BoxDecoration(
                color: isUser ? _userBubble : _botBubble,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isUser ? 18 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 18),
                ),
                border: isUser ? null : Border.all(color: _divider, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: isUser
                        ? _accent.withValues(alpha: 0.15)
                        : Colors.black.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Text(
                message.text,
                style: TextStyle(
                  color: isUser ? Colors.white : _textPri,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ),
          ),
          if (isUser) const SizedBox(width: 4),
        ],
      ),
    );
  }

  // ── Typing indicator ─────────────────────────────────────────
  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            width: 28,
            height: 28,
            margin: const EdgeInsets.only(right: 8, bottom: 2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _accentGlow,
              border: Border.all(
                color: _accent.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: _accent,
              size: 14,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: _botBubble,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomRight: Radius.circular(18),
                bottomLeft: Radius.circular(4),
              ),
              border: Border.all(color: _divider),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) {
                return _TypingDot(delay: Duration(milliseconds: i * 180));
              }),
            ),
          ),
        ],
      ),
    );
  }

  // ── Input bar ────────────────────────────────────────────────
  Widget _buildInputBar() {
    return Container(
      decoration: const BoxDecoration(
        color: _bgCard,
        border: Border(top: BorderSide(color: _divider)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: _bgSurface,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: _divider),
                  ),
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    style: const TextStyle(color: _textPri, fontSize: 14),
                    maxLines: 4,
                    minLines: 1,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                    decoration: const InputDecoration(
                      hintText: 'Nhập câu hỏi của bạn...',
                      hintStyle: TextStyle(color: _textSec, fontSize: 14),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: _isLoading ? null : _sendMessage,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isLoading ? _bgSurface : _accent,
                    boxShadow: _isLoading
                        ? []
                        : [
                            BoxShadow(
                              color: _accent.withValues(alpha: 0.35),
                              blurRadius: 12,
                              offset: const Offset(0, 3),
                            ),
                          ],
                  ),
                  child: Icon(
                    _isLoading
                        ? Icons.hourglass_top_rounded
                        : Icons.arrow_upward_rounded,
                    color: _isLoading ? _textSec : Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Typing dot widget ────────────────────────────────────────────
class _TypingDot extends StatefulWidget {
  final Duration delay;
  const _TypingDot({required this.delay});

  @override
  State<_TypingDot> createState() => _TypingDotState();
}

class _TypingDotState extends State<_TypingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _anim = Tween<double>(
      begin: 0,
      end: -5,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
    Future.delayed(widget.delay, () {
      if (mounted) _ctrl.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Transform.translate(
        offset: Offset(0, _anim.value),
        child: Container(
          width: 7,
          height: 7,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0xFF6B7FA8),
          ),
        ),
      ),
    );
  }
}
