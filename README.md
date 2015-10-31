# Ring a Bell

[![Deploy](https://www.herokucdn.com/deploy/button.png)](https://heroku.com/deploy)


## 概要

Flickr のアルバムに写真が追加されたことを、一日に一度家族にメールで通知します。

## 使い方

### 設定項目

ローカル環境用には `.env` ファイルを準備します。

動作させるために設定が必要な項目は以下になります。

```
API_KEY=""
API_SECRET=""
TOKEN=""
GMAIL_ACCOUNT=""
GMAIL_PASSWORD=""
TARGET_ALBUM=""
ALBUM_URL=""
SEND_TARGET_EMAILS=""
MAIL_SUBJECT=""
MAIL_MESSAGE=""
```

> ローカルで動作確認をしない場合には、後述する事前準備で必要になる項目のみ設定します。
> それ以外は、heroku に設定します。

### 事前準備

heroku では Flickr の認証トークンを利用して動作させるため、事前にトークンを取得しておきます。

#### .env に Flickr の API キーを設定する

https://www.flickr.com/services/api/misc.api_keys.html

上記から Flickr の API key と secret を取得し、`.env` に設定しておきます。

```
API_KEY=""
API_SECRET=""
```

#### トークンの取得コマンドを実行します

```
% bundle exec rake auth
```

途中 URL が表示されるので、それをブラウザに入力して Flickr サイト上での認証を行ってください。

#### トークンを確認する

`token_cache.yml` というファイルが生成されています。その中の `token` の項目が対象となります。

設定項目の `TOKEN` にその値を設定します。

### 設定項目の詳細

### GMAIL_ACCOUNT

利用する Gmail のメールアドレスを設定してください。通知メールの from にも利用されます。

### GMAIL_PASSWORD

GMail のアカウントに二段階認証を設定すると、App password が取得できるようになりますので、取得しておいてください。

> 通常利用している GMail のパスワードは利用しないでください。

### TARGET_ALBUM

Flickr 上のアルバム名を指定してください。日本語のアルバム名でもそのまま設定します。

### ALBUM_URL

アルバムそのものの URL ではなく、共有用の URL を使ってください。

### SEND_TARGET_EMAILS

通知したいメールアドレスをカンマ区切りで指定してください。

### MAIL_SUBJECT

通知メールの件名に利用します。件名には先頭に日付が設定されます。

`[11/1] アルバムに写真が追加されました`

### MAIL_MESSAGE

通知メールの本文に利用します。
