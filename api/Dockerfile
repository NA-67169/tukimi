FROM ruby:3.3.6

WORKDIR /api

# 必要なパッケージをインストール（順序と依存関係を考慮）
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
    build-essential \
    default-mysql-client \
    default-libmysqlclient-dev \
    pkg-config \
    cmake \
    && rm -rf /var/lib/apt/lists/*

# GemfileとGemfile.lockをコピー
COPY Gemfile* ./

# bundle installの前に既存のGemfile.lockがある場合は削除
RUN rm -f Gemfile.lock

# MySQLのビルド設定とgemのインストール
RUN bundle config build.mysql2 "--with-ldflags=-L/usr/lib/aarch64-linux-gnu" && \
    bundle install

COPY . .

COPY entrypoint.sh /usr/bin/
RUN chmod +x /usr/bin/entrypoint.sh
ENTRYPOINT ["entrypoint.sh"]

CMD ["rails", "server", "-b", "0.0.0.0"]

EXPOSE 3000