### ER図
[![Image from Gyazo](https://i.gyazo.com/09f7761884a337f07c73a093ef89d1bf.png)](https://gyazo.com/09f7761884a337f07c73a093ef89d1bf)

■サービス概要
夜に散歩する人のためのCGMサービスです。  
コアとなる機能は夜景などの画像を投稿する機能です。  
サブの機能として月の満ち欠けを表示などを行うようにしたいと思います。

■ このサービスへの思い・作りたい理由
夜に散歩をすることが趣味で、特に満月の日に散歩をすることが好きだったので、満月の日を忘れないようにLINE通知するものが欲しいと思ったのが始まりです。  
そこから派生して、夜の風景などを共有できるwebアプリケーションを作成したいと思いました。

■ ユーザー層について
夜に散歩をするまたは、夜景などを共有したい人が対象です。

■サービスの利用イメージ
外出する前に天気情報、月の満ち欠けを確認できる。  
外出後は夜景などを共有することができる。  
夜の外出時に真っ先に開くアプリに、そしてできるだけ完結するようにしたいと考えています。

■ ユーザーの獲得について
Xでの宣伝を行う。

■ サービスの差別化ポイント・推しポイント
Xとの違いは、夜にフォーカスしたものになっていることです。  
夜景など夜に関連したものを共有できるようなサイトにできればいいなと思っています。  
夜景など以外の投稿が行われないようにまず、
- トップページとヘルプページで、夜景など夜に関するものを投稿するサイトであることを明示する。
- まずは自分で手動の検閲を行い、将来的にAIなどによってある程度自動化して検閲ができるようにしていきたいです。

■ 機能候補
- MVPまでに実装する機能
  - ユーザー登録機能
  - ログイン機能
  - パスワード変更機能
  - メールアドレス変更機能
  - 画像テキスト投稿機能
  - 画像テキスト一覧表示機能
  - 画像テキスト詳細閲覧機能
  - 画像テキスト編集機能
  - 画像テキスト削除機能
  - コメント投稿機能
  - コメント編集機能
  - コメント削除機能
  - タグ投稿機能
  - タグ編集機能
  - タグ削除機能
- 本リリースまでに実装する機能
  - タグ検索機能
  - いいね機能
  - いいね解除機能
  - 月の満ち欠け表示機能
  - 天気表示機能
  - LINE通知機能（登録された月の満ち欠けのタイミング）
  - AIによる自動検閲

■ 機能の実装方針予定
月の満ち欠け表示機能は'AstronomyAPI'を使用予定  
天気表示機能は'OpenWeatherMap API'を使用予定  
LINE通知機能は'Messaging API'を使用予定  
AIによる自動検閲は'google vision API'を使用予定

■ 画面遷移図
Figma: https://www.figma.com/design/Wq4fWrvRpfI9Sa1QQA0hzG/tukimi%E7%94%BB%E9%9D%A2%E9%81%B7%E7%A7%BB%E5%9B%B3?node-id=0-1&t=SCC4GwV8BQe4OWFF-1
