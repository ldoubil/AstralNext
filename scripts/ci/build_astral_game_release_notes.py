"""为「手动发布 Astral Game」工作流生成 Release Markdown（Gemini）。"""

from __future__ import annotations

import os
import re
import sys

import google.generativeai as genai


def main() -> None:
    server = os.environ.get("SERVER_URL", "https://github.com").rstrip("/")
    repo = os.environ["REPO_FULL"].strip()
    tag = os.environ.get("TAG_NAME", "")
    pkg_ver = os.environ.get("PKG_VER", "")
    base = os.environ.get("BASE_REF", "")
    head = os.environ.get("HEAD_REF", "")

    api_key = (
        os.environ.get("GOOGLE_API_KEY", "").strip()
        or os.environ.get("GOOGLE", "").strip()
    )
    if not api_key:
        print("missing API key", file=sys.stderr)
        sys.exit(1)

    genai.configure(api_key=api_key)
    models = [
        m.name
        for m in genai.list_models()
        if "generateContent" in m.supported_generation_methods
    ]
    if not models:
        print("no gemini models", file=sys.stderr)
        sys.exit(1)
    model_name = models[0]
    print("using model", model_name)

    def email_to_github_mention(email: str) -> str:
        e = email.strip().lower()
        m = re.match(r"^(\d+)\+([^@]+)@users\.noreply\.github\.com$", e)
        if m:
            return "@" + m.group(2)
        m = re.match(r"^([^@+]+)@users\.noreply\.github\.com$", e)
        if m:
            return "@" + m.group(1)
        return ""

    rows: list[tuple[str, str, str, str, str, str]] = []
    if os.path.isfile("commits.tsv") and os.path.getsize("commits.tsv") > 0:
        raw = open("commits.tsv", encoding="utf-8").read().strip().splitlines()
        for line in raw:
            parts = line.split("\x1f")
            if len(parts) != 6:
                continue
            full, short, subj, aname, email, cdate = parts
            rows.append((full, short, subj, aname, email, cdate))

    if not rows:
        body = (
            f"# Astral Game {tag or pkg_ver}\n\n"
            f"> 对比范围 `{base}` … `{head}` 内无新提交。\n\n"
            "## 附件\n\n"
            "请从本 Release 下载规范命名的安装包与压缩包。\n"
        )
        open("CHANGELOG.md", "w", encoding="utf-8").write(body)
        print("empty range")
        return

    lines_out: list[str] = []
    contributors: dict[str, str] = {}
    for full, short, subj, aname, email, cdate in rows:
        url = f"{server}/{repo}/commit/{full}"
        mention = email_to_github_mention(email)
        who = mention if mention else f"**{aname}**"
        if mention:
            contributors[mention] = aname
        else:
            contributors.setdefault(f"_{aname}", aname)
        lines_out.append(
            f"- `{short}` | {subj} | 作者: {aname} <{email}> | 贡献标注: {who} | "
            f"时间: {cdate} | 链接: {url}"
        )

    commits_block = "\n".join(lines_out)
    contrib_block = "\n".join(
        sorted({f"- {k}（{v}）" for k, v in contributors.items()})
    )

    system_rules = """
你是 Astral Game 的发布说明撰写助手。必须严格遵守：
1. 输出语言：简体中文。
2. 事实来源：只能根据用户给出的「提交清单」归纳；禁止编造不存在的提交或功能。
3. 每条「用户可见的改动」必须对应到具体提交：写出短 hash（`abc1234` 形式，与清单一致），并保留清单中的 GitHub 提交链接（Markdown 链接，文案用「查看提交」）。
4. 贡献者：若清单中该条有 `@用户名`（GitHub noreply 邮箱解析出的），正文里必须使用相同的 `@用户名` 以便 GitHub 产生提及；若没有 `@`，则写「贡献者：**显示名**」不要用假 @。
5. 相似提交合并为一条时，仍须列出涉及的全部 hash 与链接（可并列）。
6. 语气：面向玩家与联机用户，少内部术语；「修复」「优化」要具体一点（仍基于提交标题合理扩写，不可离题）。
"""

    user_content = f"""
## 元数据
- 发布标签：`{tag}`
- 包版本号（文件名）：`{pkg_ver}`
- 对比范围：`{base}` → `{head}`
- 仓库：{repo}

## 提交清单（每行一条，按时间顺序）
{commits_block}

## 本区间出现过的贡献者（供你核对 @）
{contrib_block}

---

请输出 **单一 Markdown 文档**，结构如下（无内容的章节整节省略）：

# Astral Game {tag or pkg_ver}

> 用 1～2 句概括本次对玩家最重要的变化。

## 更新摘要
- 用 3～6 条要点，每条可引用多个提交。

## 新增与改进
- 子标题可按模块分（如「房间与联机」「网络」「界面」）。
- **每条**采用格式：
  `- **简述** — `短hash` [查看提交](完整URL) · 贡献者：@github 或 **姓名**`
- 简述要能让用户理解「多了什么 / 好了什么」。

## 问题修复
- 同上格式。

## 其他
- 无法归类但值得告知的改动（若有）。

## 本版贡献者
- 列出本区间实际出现过提交的贡献者；有 `@` 的用 `@` 列表，其余用 **姓名**。
- 可附一句感谢。

## 安装与升级
- 简短说明：Windows 建议下载 `astral-game-<版本>-windows-x64-setup.exe`；绿色包为 `…-windows-x64.zip`；Android APK 文件名含义等（用占位符 `<版本>` 即可）。

禁止输出「以下为 AI 生成」之类套话。不要使用代码块包裹整篇文档。
"""

    model = genai.GenerativeModel(model_name)
    resp = model.generate_content(
        [system_rules.strip(), user_content.strip()],
    )
    text = (resp.text or "").strip()
    if not text:
        text = f"# Astral Game {tag}\n\n> 模型未返回正文。\n"
    open("CHANGELOG.md", "w", encoding="utf-8").write(text)
    print("wrote CHANGELOG.md")


if __name__ == "__main__":
    main()
