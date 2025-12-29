import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

class FormattedTextEditor extends StatefulWidget {
  final String initialContent;
  final Function(String) onChanged;
  final String placeholder;
  final bool isCompact;

  const FormattedTextEditor({
    super.key,
    required this.initialContent,
    required this.onChanged,
    this.placeholder = 'Digite aqui...',
    this.isCompact = false,
  });

  @override
  State<FormattedTextEditor> createState() => _FormattedTextEditorState();
}

class _FormattedTextEditorState extends State<FormattedTextEditor> {
  late QuillController _controller;
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _initController(widget.initialContent);
  }
  
  @override
  void didUpdateWidget(covariant FormattedTextEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If the initial content changes significantly (e.g. switching dates), reload.
    // We check if the current document text is different to avoid overwriting user while typing
    // But since this is widely used, we rely on parent Key to force rebuild on context switch.
    if (widget.initialContent != oldWidget.initialContent) {
       // Only re-init if the content is NOT what we just emitted.
       // This comparison is tricky. 
       // For this app, DailyView updates widget.date which triggers full reload.
       // So we can assume if this widget is persistent, we might need to update.
       // But simplest is to Key the widget in the parent.
       _initController(widget.initialContent);
    }
  }

  void _initController(String content) {
    Document doc;
    try {
       if (content.trim().startsWith('[') || content.trim().startsWith('{')) {
          final json = jsonDecode(content);
          doc = Document.fromJson(json);
       } else {
          doc = Document()..insert(0, content.endsWith('\n') ? content : '$content\n');
       }
    } catch (e) {
      doc = Document()..insert(0, content.endsWith('\n') ? content : '$content\n');
    }
    
    _controller = QuillController(
      document: doc,
      selection: const TextSelection.collapsed(offset: 0),
    );
    
    _controller.changes.listen((event) {
       // Save as JSON string
       final json = jsonEncode(_controller.document.toDelta().toJson());
       widget.onChanged(json);
    });
  }
  
  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 20, // Comfortable but compact height
          child: Center(
            child: Theme(
              data: Theme.of(context).copyWith(
                iconTheme: const IconThemeData(size: 12),
                iconButtonTheme: IconButtonThemeData(
                  style: IconButton.styleFrom(
                    padding: const EdgeInsets.all(2),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ),
              child: QuillSimpleToolbar(
                controller: _controller,
                config: QuillSimpleToolbarConfig(
                  showFontFamily: false,
                  showFontSize: !widget.isCompact,
                  showSearchButton: false,
                  showInlineCode: false,
                  showSubscript: false,
                  showSuperscript: false,
                  showColorButton: true,
                  showListBullets: true,
                  showListNumbers: true,
                  showCodeBlock: false,
                  showQuote: false,
                  showLink: !widget.isCompact,
                  multiRowsDisplay: false,
                  showIndent: !widget.isCompact,
                  buttonOptions: const QuillSimpleToolbarButtonOptions(
                    base: QuillToolbarBaseButtonOptions(
                      iconSize: 12.0,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const Divider(height: 1, color: Colors.grey),
        Expanded(
          child: Container(
             padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
             color: Colors.white,
             child: QuillEditor(
               controller: _controller,
               scrollController: _scrollController,
               focusNode: _focusNode,
               config: QuillEditorConfig(
                 autoFocus: false,
                 expands: false,
                 padding: EdgeInsets.zero,
               ), 
             ),
          ),
        ),
      ],
    );
  }
}
