# 钓鱼大师 (Fishing Assistant) App

## 如何获得 APK 安装包 (两种最便捷方案)

### 方案 1: GitHub 自动化一键打包 (推荐，零代码/免电脑配置)
1. 将解压后的整个项目文件夹上传/Push 到你的 GitHub 仓库。
2. 打开 GitHub 仓库页面的 **Actions** 标签。
3. 系统会自动运行云端打包任务（约 2 分钟）。
4. 运行完成后，在 **Artifacts** 中直接点击下载编译好的 `release-apk` (包含 arm64 / v7a / universal APK 安装包)！

### 方案 2: 本地 Flutter 命令行编译
在根目录下打开终端：
```bash
flutter pub get
flutter build apk --release
```
生成的 APK 存放路径：`build/app/outputs/flutter-apk/app-release.apk`
