import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:dotenv/dotenv.dart';
import 'package:mysql1/mysql1.dart';
import 'package:nyxx/nyxx.dart';
import 'package:path/path.dart' as path;

var env = DotEnv(includePlatformEnvironment: true)..load();

Future<String> getClientStatus(Member member, NyxxGateway client) async {
  return '';
}

/// Retrieves the color of the highest role for a given guild member.
///
/// If the member has no roles, or if there's an issue fetching the role,
/// it defaults to Discord's default blue color (#7289da).
Future<DiscordColor> getHighestRoleColor(Member member) async {
  // Default color is Discord's standard blue
  DiscordColor color = DiscordColor.parseHexString('#7289da');

  // Check if the member has any roles.
  if (member.roles.isNotEmpty) {
    // Get the first role, which is the highest due to Discord's role hierarchy.
    var highestRole = await member.roles.first.get();
    // Set the color to the highest role's color.
    color = highestRole.color;
  }

  // Return the determined color.
  return color;
}

/// Fetches the user's preferred color from the database using their user ID.
Future<DiscordColor?> getUserColorFromDatabase(Snowflake userId) async {
  // Establish a connection to the database.
  MySqlConnection connection = await MySqlConnection.connect(ConnectionSettings(
      host: env['db_host']!,
      user: env['db_user'],
      password: env['db_password'],
      db: env['db_name']));

  try {
    // Query the database for the user's color.
    final results = await connection.query(
      'SELECT `color` FROM `users` WHERE `id` = ? LIMIT 1;',
      [userId.toString()],
    );

    // If a result is found, return the color.
    if (results.isNotEmpty) {
      return DiscordColor.parseHexString(results.first['color']);
    } else {
      // Return null if no user with the given ID exists in the database.
      return null;
    }
  } catch (e) {
    // Log any errors that occur during the database operation.
    print('An error occurred: $e');
    // Return null to indicate failure or no result.
    return null;
  } finally {
    // Ensure the database connection is closed, regardless of the operation's outcome.
    await connection.close();
  }
}

/// Retrieves and sorts roles for either a guild member or a guild,
/// then returns up to 40 role names as a comma-separated string.
Future<String> getRoles(dynamic type) async {
  // Ensure we're dealing with either a member or a guild.
  if (!(type is Member || type is Guild)) {
    throw ArgumentError('The type must be either Member or Guild.');
  }

  List<PartialRole> partialRoles;

  if (type is Member) {
    // If it's a member, get the member's roles.
    partialRoles = type.roles.toList();
  } else if (type is Guild) {
    // If it's a guild, get all roles in the guild.
    partialRoles = type.roleList;
  } else {
    // This should never happen due to the check above, but it's good practice for completeness.
    throw StateError('Unexpected type encountered.');
  }

  // Convert all PartialRoles to Roles.
  List<Role> roles =
      await Future.wait(partialRoles.map((partial) => partial.get()));

  // Sort roles by their position
  roles.sort((a, b) => b.position.compareTo(a.position));

  // Map roles to their names, take up to 40, and join them into a string.
  return roles.take(40).map((role) => '<@&${role.id}>').join(', ');
}

/// Generates a string listing all command names in a given category.
///
/// This function reads all files in the specified command category directory,
/// extracts the command names (without file extensions), and formats them into
/// a comma-separated string for use in command help or listing.
String generateCommands(String category) {
  // Initialize an empty string to hold the list of commands.
  String commandsListed = '';

  // Get all files in the specified command category directory.
  final directory =
      Directory('${Directory.current.path}/lib/commands/$category');
  final group = directory.listSync();

  // Iterate over each file in the directory.
  for (final file in group) {
    // Check if the file is actually a file (not a directory).
    if (file is File) {
      // Extract the command name (filename without extension).
      final commandName = path.basenameWithoutExtension(file.path);
      // Append the command name to the list, formatted with backticks and a comma.
      commandsListed += ' `$commandName`,';
    }
  }

  // Remove the trailing comma if any commands were added.
  if (commandsListed.isNotEmpty) {
    commandsListed = commandsListed.substring(0, commandsListed.length - 1);
  }

  return commandsListed;
}

/// Sets a random status from the predefined list every 2 minutes.
void randomStatus(ReadyEvent event) {
  /// Defines various custom statuses for the bot.
  final List<Map<String, dynamic>> options = [
    {
      'type': ActivityType.listening,
      'name': 'nyxx',
      'status': CurrentUserStatus.online,
      'state': 'Wrapper around Discord API for Dart'
    }
  ];

  try {
    Timer.periodic(const Duration(minutes: 2), (Timer timer) {
      final random = Random();
      final statusIndex = random.nextInt(options.length);

      final selectedStatus = options[statusIndex];

      event.gateway.updatePresence(PresenceBuilder(
        since: DateTime(2024, 9, 6, 17, 35),
        activities: [
          ActivityBuilder(
              name: selectedStatus['name'],
              type: selectedStatus['type'] as ActivityType,
              state: selectedStatus['state'])
        ],
        status: selectedStatus['status'] as CurrentUserStatus,
        isAfk: false,
      ));
    });
  } catch (e) {
    print('Error in randomStatus: $e');
  }
}
