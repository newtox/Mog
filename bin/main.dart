import 'package:dotenv/dotenv.dart';
import 'package:mog_discord_bot/events.dart';
import 'package:nyxx/nyxx.dart';
import 'package:nyxx_commands/nyxx_commands.dart';

void main() async {
  var env = DotEnv(includePlatformEnvironment: true)..load();

  final commands = CommandsPlugin(
      prefix: mentionOr((_) => 'm.'),
      options: CommandsOptions(
          acceptBotCommands: false,
          acceptSelfCommands: false,
          defaultResponseLevel: ResponseLevel.public,
          type: CommandType.slashOnly));

  final client = await Nyxx.connectGateway(env['token']!, GatewayIntents.all,
      options: GatewayClientOptions(
          plugins: [logging, cliIntegration, setupCommandHandler(commands)]));

  setupReadyHandler(client);
  setupGuildCreateHandler(client);
  setupGuildMemberAddHandler(client);
  setupGuildMemberRemoveHandler(client);
  setupGuildDeleteHandler(client);
  setupErrorHandler(commands);
  setupCommandPreCallHandler(commands, client);
  setupCommandPostCallHandler(commands, client);
}
