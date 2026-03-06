# 上游与依赖监控策略

## Fork 项目监控

### ultimate-search
- **上游**: ckckck/UltimateSearchSkill
- **监控频率**: 每周
- **策略**: 手动检查上游更新，评估后合并
- **本地修改**: 3 个增强 commits，需保留

## 外部依赖监控

### notebooklm-py
- **类型**: Python CLI
- **监控**: 手动升级
- **当前版本**: commit 5323dd0

### agent-browser
- **类型**: npm package
- **监控**: 手动升级
- **当前版本**: 0.16.3

## 不再监控

### anything-to-notebooklm
- **原因**: 已改名为 content-bridge，不再跟上游
- **状态**: 独立维护

## 监控命令

```bash
# 检查 fork 上游更新
cd ~/projects/personal-skills
git remote add upstream-ultimate https://github.com/ckckck/UltimateSearchSkill.git
git fetch upstream-ultimate
git log HEAD..upstream-ultimate/main

# 检查依赖版本
npm outdated agent-browser
pip list | grep notebooklm
```
