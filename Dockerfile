FROM dart:stable

RUN apt-get update && apt-get install -y libsqlite3-dev && apt-get clean

WORKDIR /app
COPY . .

RUN dart pub get

CMD ["dart", "bin/main.dart"]
