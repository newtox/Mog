import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:mog_discord_bot/database.dart';
import 'package:mog_discord_bot/utils/functions.dart';
import 'package:nyxx/nyxx.dart';
import 'package:nyxx_commands/nyxx_commands.dart';
import 'package:nyxx_extensions/nyxx_extensions.dart';

final dance = ChatCommand('dance', 'Dance.', localizedDescriptions: {
  Locale.da: 'Danse.',
  Locale.de: 'Tanzen.',
  Locale.enUs: 'Dance.',
  Locale.esEs: 'Bailar.',
  Locale.fr: 'Danser.',
  Locale.ru: 'Танцевать.',
  Locale.hi: 'नृत्य.',
  Locale.zhCn: '跳舞.',
  Locale.ja: '踊る.',
  Locale.ko: '춤추다.'
}, (ChatContext context) async {
  try {
    final httpPackageUrl = Uri.https('waifu.pics', 'api/sfw/dance');
    final httpPackageInfo = await http.get(httpPackageUrl);

    final httpPackageResponse =
        jsonDecode(utf8.decode(httpPackageInfo.bodyBytes)) as Map;
    final httpPackageResult = Uri.parse(httpPackageResponse['url'] as String);

    await context.respond(MessageBuilder(embeds: [
      EmbedBuilder(
          color: await getUserColorFromDatabase(context.user.id),
          title: (await getString(context.user, 'dance_user')),
          image: EmbedImageBuilder(url: httpPackageResult))
    ]));
  } catch (e) {
    print('Error in dance command: $e');
    await context.respond(
        MessageBuilder(embeds: [
          EmbedBuilder(
              color: DiscordColor.parseHexString('#c41111'),
              title: await getString(context.user, 'global_error'),
              description: codeBlock(e.toString(), 'sh'))
        ]),
        level: ResponseLevel.hint);
    return;
  }
});