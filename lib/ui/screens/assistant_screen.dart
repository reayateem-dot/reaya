import 'package:flutter/material.dart';

import '../../app/reaya_theme.dart';
import '../../data/firebase_ai_chat_service.dart';
import '../../data/local_chat_service.dart';

class AssistantScreen extends StatefulWidget {
  const AssistantScreen({
    super.key,
    required this.onOpenDirectory,
    this.chatService,
  });

  final VoidCallback onOpenDirectory;
  final LocalChatService? chatService;

  @override
  State<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends State<AssistantScreen> {
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();
  final List<_ChatMessage> _messages = [];
  late final LocalChatService? _injectedChatService = widget.chatService;
  final FirebaseAiChatService _firebaseChatService = FirebaseAiChatService();
  bool _isSending = false;

  static const _suggestions = [
    'ما التخصص المناسب لمشكلة عامة في الظهر؟',
    'ما دور طبيب الأطفال؟',
    'كيف أبحث عن صيدلية؟',
  ];

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 17, 20, 12),
            child: Row(
              children: [
                Container(
                  width: 43,
                  height: 43,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: const Icon(
                    Icons.chat_bubble_outline_rounded,
                    color: ReayaColors.plum,
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'مساعد رعاية',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Text(
                        'إرشاد أولي للتخصصات',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.lock_outline_rounded,
                  color: ReayaColors.green,
                  size: 19,
                ),
              ],
            ),
          ),
          const _AssistantSafetyNotice(),
          Expanded(
            child: _messages.isEmpty
                ? _WelcomeSuggestions(
                    suggestions: _suggestions,
                    onSelect: _sendMessage,
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                    itemCount: _messages.length + (_isSending ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _messages.length) {
                        return const Padding(
                          padding: EdgeInsetsDirectional.only(bottom: 16),
                          child: Align(
                            alignment: AlignmentDirectional.centerEnd,
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }
                      return _MessageBubble(
                        message: _messages[index],
                        onOpenDirectory: widget.onOpenDirectory,
                      );
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextField(
                    controller: _inputController,
                    enabled: !_isSending,
                    minLines: 1,
                    maxLines: 4,
                    maxLength: 1800,
                    textInputAction: TextInputAction.send,
                    onSubmitted: _sendMessage,
                    decoration: const InputDecoration(
                      hintText: 'اكتب سؤالك بشكل عام...',
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 15,
                        vertical: 13,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  tooltip: 'إرسال',
                  onPressed: _isSending
                      ? null
                      : () => _sendMessage(_inputController.text),
                  style: IconButton.styleFrom(
                    backgroundColor: ReayaColors.plum,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(49, 49),
                  ),
                  icon: _isSending
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.arrow_upward_rounded),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _sendMessage(String rawText) async {
    final text = rawText.trim();
    if (text.isEmpty || _isSending) return;
    _inputController.clear();

    if (_isEmergency(text)) {
      setState(() {
        _messages
          ..add(
            _ChatMessage(text: text, fromUser: true, includeInContext: false),
          )
          ..add(
            const _ChatMessage(
              text:
                  'قد تكون الأعراض التي ذكرتها طارئة. لا تنتظر ردًا من التطبيق؛ اطلب المساعدة الطبية العاجلة أو توجّه لأقرب طوارئ. في مصر، رقم الإسعاف 123.\n\nهذا التطبيق لا يستطيع تقييم حالتك أو استبعاد الطوارئ.',
              fromUser: false,
              includeInContext: false,
            ),
          );
      });
      _scrollToLatest();
      return;
    }

    final requestMessageIndex = _messages.length;
    setState(() {
      _messages.add(_ChatMessage(text: text, fromUser: true));
      _isSending = true;
    });
    _scrollToLatest();

    try {
      final conversation = _messages
          .where((message) => !message.isError && message.includeInContext)
          .map(
            (message) => ChatTurn(text: message.text, isUser: message.fromUser),
          )
          .toList();
      if (conversation.length > 12) {
        conversation.removeRange(0, conversation.length - 12);
      }
      if (conversation.isNotEmpty && !conversation.first.isUser) {
        conversation.removeAt(0);
      }
      final injected = _injectedChatService;
      final response = injected != null
          ? await injected.sendMessage(conversation)
          : await _firebaseChatService.sendMessage(conversation);
      if (!mounted) return;
      setState(() {
        _messages.add(_ChatMessage(text: response, fromUser: false));
      });
    } on AssistantServiceException catch (error) {
      if (!mounted) return;
      setState(() {
        final failedMessage = _messages[requestMessageIndex];
        _messages[requestMessageIndex] = _ChatMessage(
          text: failedMessage.text,
          fromUser: failedMessage.fromUser,
          includeInContext: false,
        );
        _messages.add(
          _ChatMessage(text: error.message, fromUser: false, isError: true),
        );
      });
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
        _scrollToLatest();
      }
    }
  }

  void _scrollToLatest() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  bool _isEmergency(String input) {
    final text = input.toLowerCase();
    const urgentTerms = [
      'ضيق في التنفس',
      'مش قادر أتنفس',
      'صعوبة التنفس',
      'ألم شديد في الصدر',
      'ألم بالصدر',
      'فقدان الوعي',
      'نزيف شديد',
      'جلطة',
    ];
    return urgentTerms.any(text.contains);
  }
}

class _AssistantSafetyNotice extends StatelessWidget {
  const _AssistantSafetyNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, color: ReayaColors.amber, size: 17),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'المساعد مخصص للمعلومات الصحية العامة وخدمات التطبيق؛ تُرسل رسالتك إلى Gemini عبر Firebase AI Logic. لا يشخّص ولا يصف علاجًا، ولا يحفظ التطبيق سجل المحادثة. لا تكتب بيانات شخصية. للطوارئ اتصل بالإسعاف 123.',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 10,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WelcomeSuggestions extends StatelessWidget {
  const _WelcomeSuggestions({
    required this.suggestions,
    required this.onSelect,
  });

  final List<String> suggestions;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 16),
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.health_and_safety_outlined,
            color: ReayaColors.plum,
            size: 36,
          ),
        ),
        const SizedBox(height: 17),
        Text(
          'إزاي أقدر أساعدك؟',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 7),
        Text(
          'اكتب سؤالًا عامًا عن التخصصات أو الخدمات الصحية. لا أقدّم تشخيصًا أو علاجًا.',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            height: 1.6,
          ),
        ),
        const SizedBox(height: 22),
        for (final suggestion in suggestions)
          Padding(
            padding: const EdgeInsets.only(bottom: 9),
            child: OutlinedButton(
              onPressed: () => onSelect(suggestion),
              style: OutlinedButton.styleFrom(
                alignment: AlignmentDirectional.centerStart,
                foregroundColor: ReayaColors.plum,
                padding: const EdgeInsets.all(13),
                side: BorderSide(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
                backgroundColor: Theme.of(context).colorScheme.surface,
              ),
              child: Text(suggestion),
            ),
          ),
      ],
    );
  }
}

class _ChatMessage {
  const _ChatMessage({
    required this.text,
    required this.fromUser,
    this.isError = false,
    this.includeInContext = true,
  });

  final String text;
  final bool fromUser;
  final bool isError;
  final bool includeInContext;
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message, required this.onOpenDirectory});

  final _ChatMessage message;
  final VoidCallback onOpenDirectory;

  @override
  Widget build(BuildContext context) {
    final isUser = message.fromUser;
    return Align(
      alignment: isUser
          ? AlignmentDirectional.centerStart
          : AlignmentDirectional.centerEnd,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 310),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isUser
              ? ReayaColors.plum
              : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(18),
          border: isUser
              ? null
              : Border.all(
                  color: message.isError
                      ? Theme.of(context).colorScheme.error
                      : Theme.of(context).colorScheme.outlineVariant,
                ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.text,
              style: TextStyle(
                color: isUser
                    ? Colors.white
                    : message.isError
                    ? Theme.of(context).colorScheme.error
                    : Theme.of(context).colorScheme.onSurface,
                height: 1.6,
                fontSize: 13,
              ),
            ),
            if (!isUser)
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: TextButton(
                  onPressed: onOpenDirectory,
                  child: Text('فتح دليل الخدمات'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
