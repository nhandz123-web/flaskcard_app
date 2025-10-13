// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class AppLocalizationsVi extends AppLocalizations {
  AppLocalizationsVi([String locale = 'vi']) : super(locale);

  @override
  String get lexiFlash => '⚡ LexiFlash';

  @override
  String get settings_title => 'Cài đặt';

  @override
  String get font_size => 'Cỡ chữ';

  @override
  String get theme => 'Giao diện';

  @override
  String get language => 'Ngôn ngữ';

  @override
  String get auto_play => 'Tự phát âm trong màn Học';

  @override
  String get daily_reminder => 'Nhắc hằng ngày';

  @override
  String get pick_time => 'Chọn giờ';

  @override
  String get turn_off => 'Tắt';

  @override
  String get study_play => 'Phát lại';

  @override
  String get settings_hint =>
      'Các cài đặt này lưu trên thiết bị (SharedPreferences). Bạn có thể đồng bộ lên server ở bước sau.';

  @override
  String get home => 'Trang chủ';

  @override
  String get deck => 'Bộ thẻ';

  @override
  String get learn => 'Học tập';

  @override
  String get profile => 'Hồ sơ';

  @override
  String get createNewDeck => 'Tạo Bộ Thẻ Mới';

  @override
  String get deckName => 'Tên bộ thẻ';

  @override
  String get description => 'Mô tả';

  @override
  String get save => 'Lưu';

  @override
  String get deckCreatedSuccess => 'Tạo bộ thẻ thành công!';

  @override
  String get error => 'Lỗi';

  @override
  String get noDecks => 'Không có bộ thẻ nào';

  @override
  String get createdDate => 'Ngày tạo: ';

  @override
  String get deckNameRequired => 'deckNameRequired';

  @override
  String get settings => 'Cài đặt';

  @override
  String get deckDeleted => 'Đã xóa bộ thẻ thành công';

  @override
  String get deckUpdated => 'Đã cập nhật bộ thẻ thành công';

  @override
  String get cardAdded => 'Đã thêm thẻ thành công';

  @override
  String get editDeck => 'Chỉnh sửa bộ thẻ';

  @override
  String get cards => 'cards';

  @override
  String get addCard => 'Thêm thẻ';

  @override
  String get name => 'Tên';

  @override
  String get front => 'Mặt trước';

  @override
  String get back => 'Mặt sau';

  @override
  String get note => 'Ghi chú';

  @override
  String get appName => 'Flashcard';

  @override
  String get login => 'Đăng nhập';

  @override
  String get email => 'Email';

  @override
  String get password => 'Mật khẩu';

  @override
  String get loginButton => 'Đăng nhập';

  @override
  String get signup => 'Đăng ký';

  @override
  String get signupButton => 'Đăng ký';

  @override
  String get logout => 'Đăng xuất';

  @override
  String get fontSize => 'Cỡ chữ';

  @override
  String get darkMode => 'Chế độ tối';

  @override
  String get lightMode => 'Chế độ sáng';

  @override
  String get systemDefault => 'Mặc định hệ thống';

  @override
  String get englishWord => 'Từ vựng tiếng Anh';

  @override
  String get meaning => 'Nghĩa';

  @override
  String get phonetic => 'Phiên âm';

  @override
  String get uploadImage => 'Tải hình ảnh lên';

  @override
  String get uploadAudio => 'Tải âm thanh lên';

  @override
  String get cardCreated => 'Thêm thẻ thành công';

  @override
  String get englishWordRequired => 'Từ vựng tiếng Anh là bắt buộc';

  @override
  String get meaningRequired => 'Nghĩa là bắt buộc';

  @override
  String get noCards => 'Chưa có thẻ';

  @override
  String get edit => 'Sửa';

  @override
  String get delete => 'Xóa';

  @override
  String get confirm => 'Xác nhận';

  @override
  String get confirmDeleteCard => 'Bạn có chắc chắn muốn xoá card này?';

  @override
  String get cancel => 'Hủy';

  @override
  String get cardDeletedSuccessfully => 'Card đã được xóa thành công';

  @override
  String errorDeletingCard(Object error) {
    return 'Lỗi: $error';
  }

  @override
  String get cardUpdatedSuccessfully => 'Thẻ đã được cập nhật thành công';

  @override
  String errorUpdatingCard(Object error) {
    return 'Lỗi khi cập nhật thẻ: $error';
  }

  @override
  String get editCard => 'Chỉnh sửa thẻ';

  @override
  String get requiredField => 'Trường này là bắt buộc';

  @override
  String get imageUrl => 'Đường dẫn hình ảnh';

  @override
  String get audioUrl => 'Đường dẫn âm thanh';

  @override
  String get example => 'ví dụ';

  @override
  String get removeImage => 'removeImage';

  @override
  String get removeAudio => 'removeAudio';

  @override
  String get errorNavigating => 'errorNavigating';

  @override
  String get noAudio => 'Không có audio';

  @override
  String get errorPlayingAudio => 'Lỗi phát audio';

  @override
  String get errorLoadingDeck => 'Error loading deck';

  @override
  String get errorLoadingCards => 'Lỗi khi tải thẻ';

  @override
  String get noDeckData => 'Chưa có thẻ ';

  @override
  String get cardCreatedSuccessfully => 'CThẻ đã được tạo thành công';

  @override
  String errorCreatingCard(Object error) {
    return 'Error creating card: $error';
  }

  @override
  String get debug => 'debug';

  @override
  String get errorLoadingDecks => 'Error loading Decks';

  @override
  String get addCards => 'addCards';

  @override
  String get deckDeletedSuccessfully => 'Deck deleted successfully';

  @override
  String get errorDeletingDeck => 'Error deleting deck';

  @override
  String get welcome => 'Chào mừng';

  @override
  String get welcomeBack => 'quay trở lại';

  @override
  String get loading => 'Đang tải...';

  @override
  String get dueCards => 'Thẻ đến hạn hôm nay';

  @override
  String get goal => 'mục tiêu';

  @override
  String get cardsPerDay => 'thẻ/ngày';

  @override
  String get learnNow => 'Học Ngay';

  @override
  String get streak => 'Chuỗi';

  @override
  String get days => 'ngày';

  @override
  String get markLearned => 'Đánh dấu đã học';

  @override
  String get nextCard => 'Thẻ tiếp theo';

  @override
  String get card => 'Thẻ';

  @override
  String get noMoreCards => 'Không còn thẻ';

  @override
  String get markCardAsLearned => 'Đánh dấu thẻ đã học';

  @override
  String get errorMarkingCard => 'Lỗi tạo thẻ';

  @override
  String get notDeckOwner => 'notDeckOwner';

  @override
  String get retry => 'retry';

  @override
  String get cardLearnedSuccessfully => 'Học thẻ thành công';

  @override
  String get errorMarkingCardLearned => 'Lỗi khi đánh dấu thẻ đã học';

  @override
  String get completedDeck => 'Hoàn thành bộ thẻ';

  @override
  String get pauseAudio => 'Tạm dừng âm thanh';

  @override
  String get playAudio => 'Phát âm thanh';

  @override
  String get learned => 'Đã học';

  @override
  String get next => 'Tiếp theo';

  @override
  String learnDeckTitle(Object deckId) {
    return 'Học Deck #$deckId';
  }

  @override
  String get noCardsToReview => 'Không có thẻ nào cần ôn tập hôm nay.';

  @override
  String get again => 'Học lại';

  @override
  String get hard => 'Khó';

  @override
  String get normal => 'Bình thường';

  @override
  String get easy => 'Dễ';

  @override
  String get progress => 'Progress';

  @override
  String get reviewAgain => 'Thẻ sẽ được ôn lại sau 1 phút.';

  @override
  String get reviewHard => 'Thẻ sẽ được ôn lại sau 5 phút.';

  @override
  String get reviewNormal => 'Thẻ sẽ được ôn lại sau 10 phút.';

  @override
  String get reviewEasy => 'Thẻ sẽ được ôn lại sau 1 ngày.';

  @override
  String get accountDetails => 'Cccount details';

  @override
  String get statistics => 'Statistics';

  @override
  String get help => 'Help';
}
