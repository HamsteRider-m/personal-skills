# /obos vault

管理多个 Obsidian vault 的注册、切换和默认设置。

## Usage

```
/obos vault add <alias> <path>    # 注册 vault
/obos vault list                   # 列出所有已注册 vault
/obos vault default <alias>        # 设置默认 vault
/obos vault remove <alias>         # 移除注册
```

## 配置文件

所有 vault 配置持久化到 `~/.proma/agent-workspaces/obsidian/obos-config.json`。

结构：
```json
{
  "vaults": {
    "personal": { "path": "D:/obsidian/personal", "default": true },
    "work": { "path": "C:/Users/.../work-vault" }
  },
  "lastUsedVault": "personal"
}
```

## Step 1: 解析子命令

解析 `/obos vault` 后的第一个参数：`add`、`list`、`default`、`remove`。

无参数 → 等同于 `list`。

## Step 2: 执行子命令

### vault add

1. 验证 `<path>` 目录存在
2. 验证目录包含 `.obsidian/` 子目录（如果不包含，警告但仍允许注册）
3. 读取 obos-config.json（不存在则创建空配置）
4. 写入新 vault 条目
5. 如果是第一个注册的 vault，自动设为 default
6. 输出确认：`已注册 vault: <alias> → <path>`

### vault list

1. 读取 obos-config.json
2. 如果无配置或无 vault，提示用户先注册
3. 输出表格：

```
已注册 Vault：
| 别名 | 路径 | 默认 |
|------|------|------|
| personal | D:/obsidian/personal | ✓ |
| work | C:/Users/.../work-vault | |
```

### vault default

1. 验证 `<alias>` 已注册
2. 将所有 vault 的 default 设为 false
3. 将目标 vault 的 default 设为 true
4. 输出确认：`默认 vault 已切换为: <alias>`

### vault remove

1. 验证 `<alias>` 已注册
2. 用 AskUserQuestion 确认删除："确认移除 vault 注册 '<alias>'？（不会删除实际文件）"
3. 从配置中移除
4. 如果移除的是 default vault 且还有其他 vault，提示用户设置新的 default
5. 输出确认：`已移除 vault 注册: <alias>`

## 错误处理

- alias 重复 → 提示已存在，询问是否覆盖
- path 不存在 → 报错，不注册
- 配置文件损坏 → 备份后重建空配置
