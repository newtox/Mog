import 'dart:convert';
import 'dart:io';

import 'package:dotenv/dotenv.dart';
import 'package:mysql1/mysql1.dart';
import 'package:nyxx/nyxx.dart';

var env = DotEnv(includePlatformEnvironment: true)..load();

final Map<String, bool> cached = {};

Future<Guild?> checkForDatabase(Guild guild) async {
  // ignore: collection_methods_unrelated_type
  if (cached.containsKey(guild.id)) {
    return null;
  }

  MySqlConnection connection = await MySqlConnection.connect(ConnectionSettings(
      host: env['db_host']!,
      user: env['db_user'],
      password: env['db_password'],
      db: env['db_name']));

  try {
    var guildId = guild.id.toString();

    var results = await connection
        .query('SELECT * FROM `guilds` WHERE `id` = ? LIMIT 1;', [guildId]);

    if (results.isNotEmpty) {
      return null;
    }

    await connection.query(
        'INSERT INTO `guilds` (`id`, `welcome_channel`, `bye_channel`, `welcome_msg`, `bye_msg`, `autorole`, `notify`, `stream`) VALUES (?, NULL, NULL, NULL, NULL, NULL, NULL, NULL);',
        [guildId]);

    cached[guildId] = true;
  } catch (e) {
    print('Error in checkForDatabase: $e');
  } finally {
    await connection.close();
  }
  return null;
}

Future<String> getString(User user, String dbString) async {
  MySqlConnection connection = await MySqlConnection.connect(ConnectionSettings(
      host: env['db_host']!,
      user: env['db_user'],
      password: env['db_password'],
      db: env['db_name']));

  try {
    final userId = user.id.toString();

    final results = await connection
        .query('SELECT * FROM `users` WHERE `id` = ? LIMIT 1;', [userId]);

    String language;

    if (results.isEmpty) {
      if (user.isBot) return '';

      language = 'en_us';
      await connection.query(
          'INSERT INTO `users` (`id`, `language`, `color`) VALUES (?, ?, ?);',
          [userId, language, '#7289da']);
    } else {
      final blobData = results.first['language'];

      List<int> languageBytes;
      if (blobData is Blob) {
        languageBytes = blobData.toBytes();
      } else {
        languageBytes = blobData as List<int>;
      }

      language = utf8.decode(languageBytes);
    }

    final languageFile =
        File('${Directory.current.path}/lib/utils/languages/$language.json');
    if (!(await languageFile.exists())) {
      print('File does not exist: ${languageFile.path}');
    }

    try {
      final fileStats = await languageFile.stat();
      if (fileStats.size == 0) {
        print('File is empty: ${languageFile.path}');
      }

      final content = await languageFile.readAsString(encoding: utf8);
      final languageData = jsonDecode(content);

      if (!languageData.containsKey(dbString)) {
        print('Key not found in JSON: $dbString');
      }

      return languageData[dbString] ?? '';
    } catch (e) {
      print('Error reading or decoding file: $e');
    }
  } catch (e) {
    print('Error in getString: $e');
  } finally {
    await connection.close();
  }

  return '';
}

/// Removes entries from the 'guilds' table for guilds that no longer exist in the Discord client.
Future<void> clearOldGuilds(NyxxGateway client) async {
  MySqlConnection connection = await MySqlConnection.connect(ConnectionSettings(
      host: env['db_host']!,
      user: env['db_user'],
      password: env['db_password'],
      db: env['db_name']));

  try {
    // Fetch all records from the 'guilds' table.
    final results = await connection.query('SELECT * FROM `guilds`;', []);

    // Iterate over each guild record.
    for (final row in results) {
      // 'id' is stored as a string in the database but needs to be an int for queries.
      final String guildIdAsString = row['id'].toString();
      int? guildIdAsInt = int.tryParse(guildIdAsString);

      if (guildIdAsInt == null) {
        print('Failed to parse guild ID: $guildIdAsString');
        continue; // Skip this iteration if ID can't be parsed.
      }
      // Check if the guild can still be fetched.
      try {
        await client.guilds.fetch(Snowflake(guildIdAsInt));
      } catch (e) {
        // If not, delete the guild record from the database.
        await connection
            .query('DELETE FROM `guilds` WHERE `id` = ?;', [guildIdAsString]);
      } finally {
        await connection.close();
      }
    }
  } catch (e) {
    print('Error in clearOldGuilds: $e');
  } finally {
    await connection.close();
  }
}

/// Removes entries from the 'users' table for users that no longer exist in the Discord client.
Future<void> clearOldUsers(NyxxGateway client) async {
  MySqlConnection connection = await MySqlConnection.connect(ConnectionSettings(
      host: env['db_host']!,
      user: env['db_user'],
      password: env['db_password'],
      db: env['db_name']));

  try {
    // Fetch all records from the 'users' table.
    final results = await connection.query('SELECT * FROM `users`;', []);

    // Iterate over each user record.
    for (final row in results) {
      // 'id' is stored as a string in the database but needs to be an int for queries.
      final String userIdAsString = row['id'].toString();
      int? userIdAsInt = int.tryParse(userIdAsString);

      if (userIdAsInt == null) {
        print('Failed to parse user ID: $userIdAsString');
        continue; // Skip this iteration if ID can't be parsed.
      }
      // Check if the user can still be fetched.
      try {
        await client.users.fetch(Snowflake(userIdAsInt));
      } catch (e) {
        // If not, delete the user record from the database.
        await connection
            .query('DELETE FROM `users` WHERE `id` = ?;', [userIdAsString]);
      } finally {
        await connection.close();
      }
    }
  } catch (e) {
    print('Error in clearOldUsers: $e');
  } finally {
    await connection.close();
  }
}
