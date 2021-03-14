# 駅メモマップ2 とは

# アーキテクチャ

- Cloud Storage
- Cloud Load Ballancing (無料 SSL 証明書付き)
- Cloud DNS

# 構築手順

- Maps Javascript API を有効化
- GCP コンソール > APIとサービス > 認証情報の「認証情報を作成」で新しい API キーを作成する。
  - HTTPリファラーは下記。
    - ekimemo-map2.net/*
    - *.ekimemo-map2.net/*

  - APIの制限
    - Maps Javascript API

- static/maps/index.html の下記を修正。
    <script src="//maps.googleapis.com/maps/api/js?key=..."></script>
- レジストラでドメイン取得
- ウェブマスターセントラルで TXT レコードに登録するコード取得
- terraform 下記 ... 部分にコード埋め込み
```
  resource "google_dns_record_set" "owner-txt" {
    rrdatas = ["google-site-verification=....."]
  }
```
- terraform実行
- レジストラでNSレコード登録 (手動)
```
Ex:
  ns-cloud-b1.googledomains.com.
  ns-cloud-b2.googledomains.com.
  ns-cloud-b3.googledomains.com.
  ns-cloud-b4.googledomains.com.
```
- ウェブマスターセントラルで所有者であることを証明 (ボタン押下)
