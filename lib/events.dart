import "package:dotenv/dotenv.dart";
import "package:cassandra_discord_bot/commands/configuration/announcements.dart";
import "package:cassandra_discord_bot/commands/configuration/autorole.dart";
// import "package:cassandra_discord_bot/commands/configuration/autorole.dart";
import "package:cassandra_discord_bot/commands/configuration/color.dart";
import "package:cassandra_discord_bot/commands/configuration/language.dart";
import "package:cassandra_discord_bot/commands/developer/system.dart";
import "package:cassandra_discord_bot/commands/fun/someone.dart";
import "package:cassandra_discord_bot/commands/general/info.dart";
import "package:cassandra_discord_bot/commands/general/ping.dart";
import "package:cassandra_discord_bot/commands/image/neko.dart";
import "package:cassandra_discord_bot/commands/moderation/clear.dart";
import "package:cassandra_discord_bot/database.dart";
import "package:cassandra_discord_bot/utils/functions.dart";
import "package:mysql1/mysql1.dart";
import "package:nyxx/nyxx.dart";
import "package:nyxx_commands/nyxx_commands.dart";
import "package:nyxx_extensions/nyxx_extensions.dart";

var env = DotEnv(includePlatformEnvironment: true)..load();

final Set<Snowflake> currentGuildIds = {};

CommandsPlugin setupCommandHandler(CommandsPlugin commands) {
  commands.addCommand(announcements);
  commands.addCommand(autorole);
  commands.addCommand(color);
  commands.addCommand(language);
  commands.addCommand(system);
  commands.addCommand(someone);
  commands.addCommand(info);
  commands.addCommand(ping);
  commands.addCommand(neko);
  commands.addCommand(clear);

  return commands;
}

void setupReadyHandler(NyxxGateway client) async {
  client.onReady.listen((event) async {
    print(
        "Client logged in as ${event.user.username} with ${event.guilds.length} guilds on ${event.totalShards} shards.");
    currentGuildIds.addAll(event.guilds.map((guild) => guild.id));

    randomStatus(event);
    clearOldGuilds(client);
    clearOldUsers(client);
  });
}

void setupGuildCreateHandler(NyxxGateway client) async {
  client.onGuildCreate.listen((event) async {
    try {
      final fullGuild = await client.guilds.get(event.guild.id);
      await checkForDatabase(fullGuild);

      if (currentGuildIds.contains(event.guild.id)) {
        return;
      }

      final channelId = Snowflake(1288846653704376462);
      final channel = await client.channels[channelId].get();

      if (channel is TextChannel) {
        channel.sendMessage(MessageBuilder(embeds: [
          EmbedBuilder(
              timestamp: DateTime.now().toUtc(),
              color: DiscordColor.parseHexString("#57f287"),
              description:
                  "Joined Server: ${fullGuild.name} which has ${fullGuild.members.cache.length} members.")
        ]));
        return;
      }
    } catch (e) {
      print("Error in setupGuildCreateHandler: $e");
      return;
    }
  });
}

void setupGuildMemberAddHandler(NyxxGateway client) async {
  client.onGuildMemberAdd.listen((event) async {
    MySqlConnection connection =
        await MySqlConnection.connect(ConnectionSettings(
      host: env["db_host"]!,
      user: env["db_user"],
      password: env["db_password"],
      db: env["db_name"],
    ));

    try {
      final fullGuild = await client.guilds.get(event.guild.id);

      final result = await connection.query(
          "SELECT * FROM `guilds` WHERE `id` = ? LIMIT 1;",
          [fullGuild.id.toString()]);

      if (result.isNotEmpty) {
        var guildSettings = result.first;

        if (guildSettings["autorole"] != null) {
          try {
            await event.member.addRole(Snowflake(guildSettings["autorole"]));
          } catch (e) {
            print("Failed to add autorole: $e");
          }
        }

        if (guildSettings["welcome_msg"] != null &&
            guildSettings["welcome_channel"] != null) {
          final welcomeChannelId = Snowflake(guildSettings["welcome_channel"]);
          final welcomeChannel = await client.channels[welcomeChannelId].get();

          if (welcomeChannel is TextChannel) {
            String welcomeMessage = (guildSettings["welcome_msg"] as String?)
                    ?.replaceAll("\$member",
                        "${event.member} (${event.member.user?.globalName})")
                    .replaceAll("\$guild", fullGuild.name) ??
                "Default message if welcome_msg is null.";

            try {
              await welcomeChannel
                  .sendMessage(MessageBuilder(content: welcomeMessage));
              return;
            } catch (e) {
              print("Failed to send welcome message: $e");
              return;
            }
          } else {
            print(
                "Welcome channel not found or not a text channel: $welcomeChannelId");
          }
        }
      }
    } catch (e) {
      print("Error in setupGuildMemberAddHandler: $e");
    } finally {
      await connection.close();
    }
  });
}

void setupGuildMemberRemoveHandler(NyxxGateway client) async {
  client.onGuildMemberRemove.listen((event) async {
    MySqlConnection connection =
        await MySqlConnection.connect(ConnectionSettings(
      host: env["db_host"]!,
      user: env["db_user"],
      password: env["db_password"],
      db: env["db_name"],
    ));

    try {
      if (client.guilds.cache.containsKey(event.guild.id)) {
        final fullGuild = await client.guilds.get(event.guild.id);

        final result = await connection.query(
            "SELECT * FROM `guilds` WHERE `id` = ? LIMIT 1;",
            [fullGuild.id.toString()]);

        if (result.isNotEmpty) {
          var guildSettings = result.first;

          if (guildSettings["bye_msg"] != null &&
              guildSettings["bye_channel"] != null) {
            final byeChannelId = Snowflake(guildSettings["bye_channel"]);
            final byeChannel = await client.channels[byeChannelId].get();

            if (byeChannel is TextChannel) {
              String byeMessage = (guildSettings["bye_msg"] as String?)
                      ?.replaceAll("\$member",
                          "${event.removedMember} (${event.user.globalName})")
                      .replaceAll("\$guild", fullGuild.name) ??
                  "Default message if bye_msg is null.";

              try {
                await byeChannel
                    .sendMessage(MessageBuilder(content: byeMessage));
                return;
              } catch (e) {
                print("Failed to send message: $e");
                return;
              }
            } else {
              print("Channel not found or not a text channel: $byeChannelId");
            }
          }
        }
      }
    } catch (e) {
      print("Error in setupGuildMemberRemoveHandler: $e");
    } finally {
      await connection.close();
    }
  });
}

void setupGuildDeleteHandler(NyxxGateway client) async {
  client.onGuildDelete.listen((event) async {
    try {
      if (event.isUnavailable) {
        return;
      }

      if (client.guilds.cache.containsKey(event.guild.id)) {
        if (event.deletedGuild != null) {
          final fullGuild = await client.guilds.get(event.guild.id);
          await checkForDatabase(fullGuild);

          final channelId = Snowflake(1288846653704376462);
          final channel = await client.channels[channelId].get();

          if (channel is TextChannel) {
            channel.sendMessage(MessageBuilder(embeds: [
              EmbedBuilder(
                  timestamp: DateTime.now().toUtc(),
                  color: DiscordColor.parseHexString("#ed4245"),
                  description:
                      "Left Server: ${fullGuild.name} which had ${fullGuild.members.cache.length} members.")
            ]));
          }
        } else {
          return;
        }
      }
    } catch (e) {
      print("Error in setupGuildDeleteHandler: $e");
      return;
    }
  });
}

void setupErrorHandler(CommandsPlugin commands) async {
  commands.onCommandError.listen((error) async {
    if (error is ConverterFailedException) {
      if (error.context case CommandContext context) {
        await context.respond(
            MessageBuilder(embeds: [
              EmbedBuilder(
                color: DiscordColor.parseHexString("#c41111"),
                title: await getString(context.user, "global_error"),
                description: codeBlock(error.input.remaining, "sh"),
              )
            ]),
            level: ResponseLevel.hint);
        return;
      }
    } else if (error is CheckFailedException) {
      if (error.context case CommandContext context) {
        await context.respond(
            MessageBuilder(embeds: [
              EmbedBuilder(
                color: DiscordColor.parseHexString("#c41111"),
                title: await getString(context.user, "global_error"),
                description: codeBlock(error.toString(), "sh"),
              )
            ]),
            level: ResponseLevel.hint);
        return;
      }
    } else {
      print("Uncaught error: $error");
    }
  });
}

void setupCommandPreCallHandler(
    CommandsPlugin commands, NyxxGateway client) async {
  commands.onPreCall.listen((context) async {
    try {
      if (context.channel.type == ChannelType.guildText) {
        final fullGuild = await client.guilds.get(context.guild!.id);
        await checkForDatabase(fullGuild);
      }
    } catch (e) {
      print("Error in setupCommandPreCallHandler: $e");
      return;
    }
  });
}

void setupCommandPostCallHandler(
    CommandsPlugin commands, NyxxGateway client) async {
  commands.onPostCall.listen((context) async {
    try {
      final channelId = Snowflake(1288846653704376462);
      final channel = await client.channels[channelId].get();

      if (channel is TextChannel) {
        if (context.user.id != Snowflake(402483602094555138)) {
          channel.sendMessage(MessageBuilder(embeds: [
            EmbedBuilder(
                timestamp: DateTime.now().toUtc(),
                color: DiscordColor.parseHexString("#7289da"),
                description:
                    "${context.user.globalName} (${context.user.id}) executed ${bold(context.command.name)}.")
          ]));
          return;
        }
      }
    } catch (e) {
      print("Error in setupCommandPostCallHandler: $e");
      return;
    }
  });
}