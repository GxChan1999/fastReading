import 'package:path/path.dart' as p;
import 'ebook_parser.dart';
import '../../data/models/book.dart';

/// PDF 格式解析器
class PdfParserImpl implements EbookParser {
  @override
  bool supportsFormat(String filePath) {
    return p.extension(filePath).toLowerCase() == '.pdf';
  }

  @override
  Future<EbookParseResult> parse(String filePath) async {
    // TODO: 使用 pdf_render / flutter_pdfview 实现解析
    return EbookParseResult(
      title: p.basenameWithoutExtension(filePath),
      author: '',
      format: BookFormat.pdf,
      chapters: [
        EbookChapter(title: '全文', content: '（PDF 解析待集成）'),
      ],
    );
  }

  @override
  Future<String> getChapterContent(String filePath, String chapterId) async {
    return '（PDF 章节内容解析待集成）';
  }

  @override
  Future<String> extractText(String filePath) async {
    return '（PDF 文本提取待集成）';
  }
}
