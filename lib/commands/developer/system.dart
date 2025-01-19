import 'dart:io';

import 'package:mog_discord_bot/database.dart';
import 'package:mog_discord_bot/utils/utils.dart';
import 'package:nyxx/nyxx.dart';
import 'package:nyxx_commands/nyxx_commands.dart';
import 'package:nyxx_extensions/nyxx_extensions.dart';

final system =
    ChatGroup('system', 'Commands for the developer.', localizedDescriptions: {
  Locale.da: 'Kommandoer til udvikleren.',
  Locale.de: 'Befehle für den Entwickler.',
  Locale.enUs: 'Commands for the developer.',
  Locale.esEs: 'Comandos para el desarrollador.',
  Locale.fr: 'Commandes pour le développeur.',
  Locale.ru: 'Команды для разработчика.',
  Locale.hi: 'डेवलपर के लिए कमांड।',
  Locale.zhCn: '开发者的命令。',
  Locale.ja: '開発者向けコマンド。',
  Locale.ko: '개발자용 명령어.'
}, checks: [
  UserCheck.id(Snowflake(402483602094555138))
], children: [
  ChatCommand('clear-cache', 'Clear bot cache.', localizedDescriptions: {
    Locale.da: 'Ryd bot-cache.',
    Locale.de: 'Bot-Cache leeren.',
    Locale.enUs: 'Clear bot cache.',
    Locale.esEs: 'Borrar caché del bot.',
    Locale.fr: 'Vider le cache du bot.',
    Locale.ru: 'Очистить кэш бота.',
    Locale.hi: 'बॉट कैश साफ़ करें।',
    Locale.zhCn: '清除机器人缓存。',
    Locale.ja: 'ボットのキャッシュをクリアする。',
    Locale.ko: '봇 캐시 지우기.'
  }, (ChatContext context) async {
    context.client.channels.cache.clear();
    context.client.users.cache.clear();

    await context.respond(
      MessageBuilder(content: 'Cache cleared successfully!'),
      level: ResponseLevel.hint,
    );
  }),
  ChatCommand('skid', 'Read out files.', localizedDescriptions: {
    Locale.da: 'Læs filer.',
    Locale.de: 'Dateien auslesen.',
    Locale.enUs: 'Read out files.',
    Locale.esEs: 'Leer archivos.',
    Locale.fr: 'Lire des fichiers.',
    Locale.ru: 'Чтение файлов.',
    Locale.hi: 'फ़ाइलें पढ़ें।',
    Locale.zhCn: '读取文件。',
    Locale.ja: 'ファイルを読み取る。',
    Locale.ko: '파일 읽기.'
  }, (
    ChatContext context,
    @Description('The path to the file.', {
      Locale.da: 'Stien til filen.',
      Locale.de: 'Der Pfad zur Datei.',
      Locale.enUs: 'The path to the file.',
      Locale.esEs: 'La ruta al archivo.',
      Locale.fr: 'Le chemin vers le fichier.',
      Locale.ru: 'Путь к файлу.',
      Locale.hi: 'फ़ाइल का पथ।',
      Locale.zhCn: '文件路径。',
      Locale.ja: 'ファイルへのパス。',
      Locale.ko: '파일 경로.'
    })
    String path,
    @Description('Whether to send the file content as a hastebin link.', {
      Locale.da: 'Om filindholdet skal sendes som en hastebin link.',
      Locale.de: 'Ob der Dateiinhalt als Hastebin-Link gesendet werden soll.',
      Locale.enUs: 'Whether to send the file content as a hastebin link.',
      Locale.esEs:
          'Si se debe enviar el contenido del archivo como un enlace de hastebin.',
      Locale.fr: 'Envoyer le contenu du fichier comme un lien hastebin.',
      Locale.ru: 'Отправить содержимое файла как ссылку на hastebin.',
      Locale.hi: 'क्या फ़ाइल की सामग्री को hastebin लिंक के रूप में भेजना है।',
      Locale.zhCn: '是否将文件内容作为 hastebin 链接发送。',
      Locale.ja: 'ファイル内容を hastebin リンクとして送信するかどうか。',
      Locale.ko: '파일 내용을 hastebin 링크로 보낼지 여부.'
    })
    bool hastebin,
  ) async {
    try {
      final fileContent = await File(path).readAsString();
      String result;

      if (hastebin) {
        result = await uploadToHastebin(fileContent);

        await context.respond(MessageBuilder(content: result));
      } else {
        result = fileContent.length > 1980
            ? '${fileContent.substring(0, 1980)}...'
            : fileContent;

        await context
            .respond(MessageBuilder(content: codeBlock(result, 'dart')));
      }
    } catch (e) {
      await context.respond(
          MessageBuilder(embeds: [
            EmbedBuilder(
              color: DiscordColor.parseHexString('#c41111'),
              title: await getString(context.user, 'global_error'),
              description: codeBlock(e.toString(), 'sh'),
            )
          ]),
          level: ResponseLevel.hint);
      return;
    }
  }),
  ChatCommand('listroles', 'List all roles and their permissions.',
      localizedDescriptions: {
        Locale.da: 'Vis alle roller og deres tilladelser.',
        Locale.de: 'Alle Rollen und deren Berechtigungen auflisten.',
        Locale.enUs: 'List all roles and their permissions.',
        Locale.esEs: 'Listar todos los roles y sus permisos.',
        Locale.fr: 'Lister tous les rôles et leurs permissions.',
        Locale.ru: 'Список всех ролей и их разрешений.',
        Locale.hi: 'सभी भूमिकाएं और उनकी अनुमतियां सूचीबद्ध करें।',
        Locale.zhCn: '列出所有角色及其权限。',
        Locale.ja: '全ての役割とその権限を一覧表示。',
        Locale.ko: '모든 역할과 권한 나열.'
      }, (
    ChatContext context,
    @Description('Whether to send the output as a hastebin link.', {
      Locale.da: 'Om output skal sendes som en hastebin link.',
      Locale.de: 'Ob die Ausgabe als Hastebin-Link gesendet werden soll.',
      Locale.enUs: 'Whether to send the output as a hastebin link.',
      Locale.esEs: 'Si se debe enviar la salida como un enlace de hastebin.',
      Locale.fr: 'Si la sortie doit être envoyée comme un lien hastebin.',
      Locale.ru: 'Отправить вывод как ссылку на hastebin.',
      Locale.hi: 'आउटपुट को hastebin लिंक के रूप में भेजना है या नहीं।',
      Locale.zhCn: '是否将输出作为 hastebin 链接发送。',
      Locale.ja: '出力を hastebin リンクとして送信するかどうか。',
      Locale.ko: '출력을 hastebin 링크로 보낼지 여부.'
    })
    bool hastebin,
  ) async {
    final guild = context.guild;
    final roles = guild!.roles.cache.values.toList();

    String content = '';

    for (final role in roles) {
      content += '📑 ${role.name}\n';
      content += 'Permissions:\n';

      for (final permission in role.permissions.toList()) {
        content += '✅ $permission\n';
      }
      content += '\n';
    }

    if (hastebin) {
      final hastebinUrl = await uploadToHastebin(content);
      await context.respond(MessageBuilder(embeds: [
        EmbedBuilder(
          color: DiscordColor.parseHexString('#3498db'),
          title: '${guild.name} Role Permissions',
          description: codeBlock(hastebinUrl, 'sh'),
        )
      ]));
    } else {
      await context.respond(MessageBuilder(embeds: [
        EmbedBuilder(
          color: DiscordColor.parseHexString('#3498db'),
          title: '${guild.name} Role Permissions',
          description: content.length > 4096
              ? codeBlock('Content too long, use hastebin option', 'sh')
              : codeBlock(content, 'sh'),
        )
      ]));
    }
  })
]);
