import "dart:convert";
import "dart:math";

import "package:http/http.dart" as http;
import "package:nyxx/nyxx.dart";

/// Formats a number with commas as thousand separators.
String numberWithCommas(num numb) {
  // Use regex to find every three digits from the right and insert a comma.
  return numb.toString().replaceAllMapped(
      RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (Match m) => "${m[1]},");
}

/// Cleans the text by escaping backticks and @ symbols with a zero-width space
/// to prevent code execution or mentions in certain contexts.
String clean(String text) {
  // Replace backticks and @ with themselves plus a zero-width space.
  return text.replaceAll("`", "`\u{200B}").replaceAll("@", "@\u{200B}");
}

/// Mockingly capitalizes random letters in the given text, mimicking a meme style.
String mock(String text) {
  final random = Random();
  var result = StringBuffer();
  var next = random.nextInt(3) + 1;

  for (var i = 0; i < text.length; i++) {
    if (i == next) {
      // Capitalize this character and set the next position for capitalization.
      result.write(text[i].toUpperCase());
      next += random.nextInt(3) + 1;
    } else {
      result.write(text[i]);
    }
  }
  return result.toString();
}

/// Compares two roles based on their position in the role hierarchy.
/// Returns:
/// -1 if "a" is above "b",
///  1 if "b" is above "a",
///  0 if they are at the same level or equal.
int compare(Role a, Role b) {
  if (a.position > b.position) {
    return -1;
  } else if (a.position < b.position) {
    return 1;
  } else {
    return 0;
  }
}

/// Uploads the given content to hastebin.newtox.de and returns the generated URL.
///
/// This function sends a POST request to hastebin.newtox.de/documents with the provided content.
/// If successful, it returns a URL where the content can be accessed.
/// Throws an exception if there's an error during the upload or if the response is unexpected.
Future<String> uploadToHastebin(String content) async {
  // Define the URI for the Hastebin API endpoint.
  final uri = Uri.https("hastebin.newtox.de", "/documents");

  try {
    // Send a POST request with the content.
    final response = await http.post(
      uri,
      headers: {"Content-Type": "text/plain"},
      body: content,
    );

    // Check if the request was successful.
    if (response.statusCode == 200) {
      // Decode the JSON response
      final jsonResponse = jsonDecode(response.body);
      // Check if the response contains a 'key' for the URL.
      if (jsonResponse.containsKey("key")) {
        // Return the URL where the content is hosted.
        return "https://hastebin.newtox.de/${jsonResponse["key"]}";
      } else {
        // Throw an exception if the response format is unexpected.
        throw Exception("Unexpected response from Hastebin: $jsonResponse");
      }
    } else {
      // Throw an exception if the status code indicates failure.
      throw Exception(
          "Failed to upload to Hastebin. Status code: ${response.statusCode}");
    }
  } catch (e) {
    // Catch and rethrow any exceptions that occur during the process.
    throw Exception("Error uploading to Hastebin: $e");
  }
}
