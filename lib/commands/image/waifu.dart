import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:mog_discord_bot/database.dart';
import 'package:nyxx/nyxx.dart';
import 'package:nyxx_commands/nyxx_commands.dart';
import 'package:nyxx_extensions/nyxx_extensions.dart';

final waifu =
    ChatCommand('waifu', 'Displays a waifu image.', localizedDescriptions: {
  Locale.da: 'Viser et waifu-billede.',
  Locale.de: 'Zeigt ein Waifu-Bild an.',
  Locale.enUs: 'Displays a waifu image.',
  Locale.esEs: 'Muestra una imagen de waifu.',
  Locale.fr: 'Affiche une image de waifu.',
  Locale.ru: 'Отображает изображение ваифу.',
  Locale.hi: 'एक वाइफु छवि प्रदर्शित करता है।',
  Locale.zhCn: '显示一个二次元角色图片。',
  Locale.ja: 'ワイフの画像を表示します。',
  Locale.ko: '와이푸 이미지를 표시합니다.'
}, (ChatContext context) async {
  try {
    final httpPackageUrl = Uri.https('waifu.pics', 'api/sfw/waifu');
    final httpPackageInfo = await http.get(httpPackageUrl);

    final httpPackageResponse =
        jsonDecode(utf8.decode(httpPackageInfo.bodyBytes)) as Map;
    final httpPackageResult = Uri.parse(httpPackageResponse['url'] as String);

    final imageResponse = (await http.get(httpPackageResult)).bodyBytes;

    await context.respond(MessageBuilder(attachments: [
      AttachmentBuilder(
          data: imageResponse,
          fileName: httpPackageResult.path.toString().substring(1),
          description: httpPackageResult.host.toString())
    ]));
  } catch (e) {
    print('Error in waifu command: $e');
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
