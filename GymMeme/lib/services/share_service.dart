import 'package:share_plus/share_plus.dart';

class ShareService {
  /// Share a locally saved meme image with optional text
  Future<void> shareMeme({
    required String imagePath,
    String text =
        'Check out my gym meme! 💪 Made with GymType — find your gym archetype!',
  }) async {
    await Share.shareXFiles(
      [XFile(imagePath)],
      text: text,
      subject: 'My GymType Meme',
    );
  }

  /// Share just text (e.g. weekly report summary)
  Future<void> shareText(String text) async {
    await Share.share(text, subject: 'My GymType Weekly Report');
  }

  /// Share a report card image
  Future<void> shareReportCard({
    required String imagePath,
    required String dominantArchetype,
  }) async {
    await Share.shareXFiles(
      [XFile(imagePath)],
      text:
          'This week I was a $dominantArchetype at the gym! 🏋️\nWhat\'s your gym type? Download GymType!',
      subject: 'My GymType Weekly Report',
    );
  }
}
