# mac-setup

nbsさんの個人Mac設定を再現可能にするためのスナップショット集。サブフォルダごとに独立した1機能が入っており、それぞれの`install-*.sh`を実行すれば新しいMac・別ユーザーアカウントにも再設置できる(全て`$HOME`基準で解決するためユーザー名を問わず動き、いずれも再実行安全)。

## 構成

| ディレクトリ | 内容 |
| --- | --- |
| [ai-agent-config/](ai-agent-config/ai-agent-config.md) | Claude Code / Codex CLIの指示ファイル(モデル選択方針・外部CLIへの委譲ルールなど)を他Macへ複製する仕組み |
| [cursor-sidebar-icon-patch/](cursor-sidebar-icon-patch/cursor-claude-codex-sidebar-fix.md) | Cursorの左サイドバーにClaude Code/Codexアイコンが出ない問題への対処(launchdで自動・再パッチ) |
| [login-items/](login-items/login-items-startup-scripts.md) | ログイン時に自動実行したいスクリプトを置くだけで動く汎用フォルダの仕組み(login-items.d) |

## `AGENTS.md` / `CLAUDE.md`がリポジトリ直下にある理由

この2つだけはサブフォルダに移していない。[ai-agent-config/](ai-agent-config/ai-agent-config.md)が管理する「他Macへ複製するスナップショット」であると同時に、Claude Code/Codex CLIがこの`mac-setup`リポジトリ自体で作業する際に読み込む**このプロジェクトの指示ファイルそのもの**でもあるため(移動するとプロジェクト指示として自動で読み込まれなくなる)。中身の由来・更新の仕方は[ai-agent-config/ai-agent-config.md](ai-agent-config/ai-agent-config.md)を参照。

## 他Macへ持っていく

`git clone`(または既存クローンなら`git pull`)でこのリポジトリを取得し、各ディレクトリの`install-*.sh`を実行する。
