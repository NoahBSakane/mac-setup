@AGENTS.md

## Claude Code専用

### サブエージェント委譲時のモデル選択(`Agent` tool / `Workflow` tool)

メインセッションのモデルは`/model`で切り替えるものでこの指示では変えられない。制御できるのはサブエージェント委譲時のモデル(`Agent`の`model`、`Workflow`内`agent()`の`opts.model`):

- 機械的・単純(定型検索、フォーマット変換) → `haiku`
- 標準 → 省略(親セッション継承。決め打ちしない = セッションのモデルが変わっても自動追従)
- 設計判断・高リスク(アーキテクチャ、セキュリティ、破壊的操作の事前検討) → `opus`
- おすすめしたい場面(得意分野は見極め中) → `fable`。**こちらから提案する。**費用が絡むので無断で使わず、プロンプト内容を伝えた直後に理由を添えて確認を取り、OKが出たら使う

effortは**`Workflow`の`agent()`のみ** `opts.effort`(`low`/`medium`/`high`/`xhigh`/`max`)指定可(`Agent` toolには無い)。省略時は親セッション継承。

### Codex CLIへの委譲(`codex exec`)

**デフォルトはオフ**(2026-08-13〜)。ユーザーから明示的な指示(「Codexを使って」「連携再開して」等)が無い限り、実装作業はClaude Codeのみで完結させる。都度「委譲していいか」を聞き直す必要は無く、既定オフのまま進めてよい。

委譲する場合: 実装・ビルド配線・決定的な機械的修正はCodex CLIへ、Claude Codeは設計レビュー・代替案・大規模リファクタの方向づけ・最終検証を担う(別プロジェクトで運用していたAgent Splitパターンの一般化)。委譲すると決めたら実際に`codex exec`を実行する(方針を書くだけで終わらせない)。ただし富豪的な並列実行は避け、実行前に意図を確認する、機械化できる部分はCodexを介さず自分(Claude)で直接書く、effortも案件の重さに応じて下げる、を優先する。

モデル名(sol/terra/luna等)は世代が変わると変わるためハードコードしない。`~/.codex/model-tiers.env`(ログイン時に自動更新、手動更新は`~/Library/Scripts/login-items.d/refresh-codex-model-tiers.sh`を直接実行)を読んで解決する:

```
source ~/.codex/model-tiers.env   # CODEX_MODEL_FRONTIER / _BALANCED / _FAST
```

| タスクの重さ | 変数 / プロファイル | effort |
|---|---|---|
| 軽量・機械的 | `$CODEX_MODEL_FAST` / `-p fast-low` | `low` |
| 標準 | `$CODEX_MODEL_BALANCED` / `-p balanced-medium` | `medium` |
| 難度が高い・フロンティア級 | `$CODEX_MODEL_FRONTIER` / `-p frontier-high` | `high`〜`xhigh`(必要なら`ultra`/`max`) |

```
codex exec -p fast-low          "..."
codex exec -p balanced-medium   "..."
codex exec -p frontier-high     "..."
# または: codex exec -m "$CODEX_MODEL_FRONTIER" -c model_reasoning_effort="xhigh" "..."
```
`CODEX_MODEL_FALLBACK=1`の場合は判別失敗(現行デフォルト1本にフォールバック済み)。何も指定しなければbase設定のまま(`~/.codex/config.toml`、現状`sol`/`xhigh`)。

### Gemini CLIへの委譲(実体: Antigravity CLI `agy`)

このマシンに素の`gemini`コマンドは無く、実体は Antigravity CLI(`agy`)。非対話実行は`agy -p "..." --model <モデル名>`(Codexの`codex exec`に相当)。

デフォルトはオフ(2026-08-17〜)。Codexと同じ扱いで、明示的な指示が無い限り実装作業はClaude Codeのみで完結させ、都度「委譲していいか」を聞き直す必要は無い。

委譲する場合はCodexと並列運用してよいが、Geminiの強み(大コンテキスト処理、画像/動画などマルチモーダル入力、調査・大規模解析系のタスク)が活きる場面は積極的にこちらへ振る。実装・機械的修正はCodexと同様どちらへ投げてもよい。

利用プランはマシンごとに異なる(無料枠のみのMacもあれば、Workspace等の有償プランのMacもある)。いずれの場合もFableのような使用前の都度確認は不要(定額/無料どちらも従量課金の心配は無い)。ただしクォータ・レート制限には引き続き配慮する: Workflowから大量並列で叩かない、失敗時はリトライで粘らずClaude Code側で直接処理するかCodexに切り替える。特に無料枠のマシンではこの配慮を優先する。

モデル名(gemini-3.x系のバージョン)は世代交代で変わるためハードコードしない。委譲前に`agy models`で現在のラインナップを確認し、目的に応じて選ぶ(`agy`のモデル名にはeffortが内包されており、Geminiモデルに対しては`--effort`指定は基本不要):

| タスクの重さ | 選ぶモデルの目安 |
|---|---|
| 軽量・機械的 | その時点最新のflash系`-low` |
| 標準 | その時点最新のflash系`-medium`(精度優先なら`-high`) |
| 大規模コンテキスト解析・マルチモーダル・難度が高い | `pro`系の`-high` |

```
agy -p "..." --model gemini-3.7-flash-low     # 例(2026-08-17時点の最新): 軽量
agy -p "..." --model gemini-3.7-flash-medium  # 例: 標準
agy -p "..." --model gemini-3.1-pro-high      # 例: 大規模解析・高難度
```
`agy`は`claude-sonnet-4-6`や`gpt-oss-120b-medium`等の非Geminiモデルも呼べるが、この委譲ルールではGemini系モデルの利用に限定する。

### 外部CLIへの委譲提案(Codex / Gemini CLI共通、2026-08-17〜)

上記の各「デフォルトオフ・都度確認不要」はユーザーから何も指示が無い場合の基本姿勢であり、委譲するかどうかの許可を毎回取り直す必要が無いという意味。それとは別に、CCへの依頼内容(の一部でも)を見て、Codex CLIまたはGemini CLI(`agy`)に投げたほうが明らかに向いている(得意領域に合う、規模・難度的に適する等)と判断した場合は、実行を始める前にその判断根拠を添えて一言確認し、実際に委譲するかはユーザーに決めさせる。ユーザーが既にどちらを使うか明示している場合はこの確認は不要。

### 状態インジケータ・確認頻度(2026-08-17〜)

- 保留事項(未回答の質問リスト等)の再掲は毎ターンではなく5回に1回程度に抑える。急かさない
- セッション最初の応答、または上記の再掲タイミングで、Codex CLI・Gemini CLI(Antigravity)双方の連携状態を一言添える: 未使用中なら「(Codex CLIとの連携: 未使用中。Gemini CLIとの連携: 未使用中。必要なら教えてください)」、有効中の項目はそれぞれ「有効」に置き換える
