# 运维监控系统 - 部署与使用说明

**版本：v1.9.9** | **更新日期：2026-05-22**

## 项目简介

轻量级主从架构系统运维监控工具，支持多节点统一监控。
技术栈：Python 3.8+ / Flask / SQLite / ECharts / Bootstrap 5

---

## 目录结构

```
ops-monitor/
├── server/                 # 服务端代码
│   ├── app.py              # Flask主应用（路由、API）
│   ├── main.py             # 服务启动入口
│   ├── database.py         # 数据库模型定义
│   ├── services/
│   │   ├── alert_service.py    # 告警服务（阈值检查、邮件发送）
│   │   ├── offline_detector.py # 离线检测服务
│   │   └── report_service.py   # 报表生成服务
│   ├── templates/          # Jinja2 HTML模板
│   │   ├── base.html       # 公共布局模板
│   │   ├── login.html      # 登录页
│   │   ├── index.html      # 首页（节点总览）
│   │   ├── node_detail.html    # 节点详情页
│   │   ├── alerts.html     # 告警中心
│   │   ├── settings.html   # 系统设置
│   │   ├── reports.html    # 报表中心
│   │   └── assets.html     # 资产管理
│   └── static/             # 静态资源
├── agent/
│   └── agent.py            # Agent端采集脚本（纯Python标准库）
├── config/
│   └── agent.conf.template # Agent配置文件模板
├── deploy.sh               # 一键部署脚本
├── requirements.txt        # Python依赖
└── README.md               # 本文件
```

---

## 版本更新记录

| 版本 | 日期 | 更新内容 |
|------|------|----------|
| **v1.9.9** | 2026-05-22 | **安全加固 & 体验优化**：Session Cookie 添加 HttpOnly/SameSite/Lax；_run_pipe shell=True 全面消除；邮件告警时间统一为服务器时区；SMART 告警阈值放宽（坏道>50/SSD磨损<=5%/NVMe备用<=5%）；节点详情移除Swap监控项与SMART表NVMe列；群晖NVMe采集正则Bug修复；网卡历史图表补零缺陷修复；登录记录仅展示5条；系统日志移至网卡流量下方同宽度；设置页导出节点选择Bug修复；新增 re-report.sh 重新上报脚本 |
| **v1.9.8** | 2026-05-21 | **DSM SMART采集修复**：修复synodisk无输出时SATA盘SMART数据缺失，修复NVMe幽灵条目误报 |
| **v1.9.7** | 2026-05-21 | **DSM RAID假阳性修复**：修复DSM md0/md1系统盘因热备盘导致误报RAID降级的问题 |
| **v1.9.6** | 2026-05-21 | **生产数据质量修复**：修复DSM磁盘fstype显示设备路径(/dev/md0)问题；新增内存Swap信息采集与展示 |
| **v1.9.5** | 2026-05-21 | **时区修正 & 离线检测优化**：全局时间统一为服务器时区（Asia/Shanghai），Agent本地时间自动转UTC上报；离线检测改为3次心跳无上报=离线（900s），移除ICMP ping依赖；服务端版本号显示在顶部栏；Agent版本号显示在节点详情；告警中心一键批量处理（按级别/全部）；Agent版本上报与存储 |
| **v1.9.4** | 2026-05-21 | **项目恢复与重新打包**：从备份恢复全部项目文件，交叉校验完整性；所有v1.9.3功能特性确认完整无损 |
| **v1.9.3** | 2026-05-19 | **硬件告警 & 数据质量修复**：新增9类硬件故障告警（SMART故障/坏道/SSD磨损/NVMe备用/RAID降级/RAID故障/僵尸进程/进程CPU异常/进程内存泄漏）；nftables/firewalld防火墙告警归一化去除动态计数器；登录记录过滤空条目和wtmpdb；Asset CPU型号从sysinfo同步；新增内存DIMM采集(dmidecode)；移除UDP端口监控减少噪音；排除/etc/crontab自修改误报；RAID标签去除DSM字样 |
| **v1.9.2** | 2026-05-19 | **项目精简 & 安全增强**：清理运行时日志、过期缓存、session文件、__pycache__等无效文件；新增.gitignore防止运行时文件累积；手动添加节点自动生成token；离线长于7天节点不再触发告警；reset_password自动创建instance目录；SMTP未配置警告日志抑制（每60分钟最多一次）；节点注册增加ip/node_id格式校验 |
| **v1.9.1** | 2026-05-18 | **Bug修复 & 稳定性增强**：修复手动添加节点无token导致无法认证；修复告警服务每30秒日志刷屏；修复reset_password因instance目录缺失崩溃；修复已离线超7天死节点持续触发告警；修复_get_or_create_node不生成token缺陷；evil-node恶意IP数据清理 |
| **v1.9.0** | 2026-05-15 | **功能重构 & 时间统一**：导出模块重写（路径必填+黑名单校验系统目录）；设置页重构（移除离线检测和数据管理卡片，邮件告警移至最下方）；全局时间统一为服务器时区显示（新增formatLocalTime函数，告警/登录/安全事件/日志时间全部转换）；修复导出路径限制在exports子目录导致文件不可见的问题 |
| **v1.8.3** | 2026-05-15 | **systemd兼容修复**：修复CentOS systemd不支持`append:`前缀导致`Failed to parse output specifier`错误；deploy.sh每次运行自动修复已部署service文件中的`append:`和`journal:`残留 |
| **v1.8.2** | 2026-05-15 | **导出功能修复**：修复`api_export_now`中`BASE_DIR`未定义导致500错误（应为`base_dir`）；统一导出为服务器端导出（有路径→指定目录，无路径→默认exports目录），移除不稳定的浏览器下载 |
| **v1.8.1** | 2026-05-15 | **Bug修复 & 体验优化**：修复导出功能（简化为有路径→服务器导出，无路径→浏览器下载）；设置页卡片重新排版（CSS Grid统一尺寸间距）；修复systemd服务文件`journal:`语法错误 |
| **v1.8.0** | 2026-05-15 | **数据管理 & 功能增强**：新增节点历史数据清除功能（单节点/全部节点），保留配置和硬件资产；导出fallback增强（raw_data过期时从结构化字段重建导出数据）；定时导出>60天旧文件自动清理；设置页新增数据管理卡片；移除节点详情页RAID表格"成员盘"列 |
| **v1.7.8** | 2026-05-15 | **安全加固 & Bug修复**：Agent `_run()` 全面改为 `shell=False` 消除命令注入风险；导出API路径遍历修复（限制在 exports 目录内）；deploy.sh SMTP 配置改用环境变量+json.dumps 消除 Python 代码注入；密码复杂度提升（8位+大小写+数字）并强制改密拦截 API；`/tmp` 临时文件改用 mktemp 防符号链接攻击；修复 `get_login_records()` 缺失 for 循环头导致的 IndentationError；修复 `_get_disk_device_list()` synodisk 结果被无条件覆盖 |
| **v1.7.7** | 2026-05-14 | **功能增强 & DSM NVMe支持**：节点卡片网速区域新增累计上下行流量显示；DSM NVMe SMART信息采集（nvme smart-log + nvme list，含温度/磨损/寿命/容量）；DSM磁盘设备列表补全NVMe；移除报表中心告警次数趋势卡片 |
| **v1.7.6** | 2026-05-14 | **生产环境验证修复**：网卡历史图表无数据修复（times/series长度补零）；CPU温度采集重构（移除DSM磁盘温度误用，新增/sys/class/hwmon兜底）；CentOS登录记录为空修复（last DNS反解析+auth log自动检测）；导出下载403修复（CSRF token）；立即导出不再要求填写服务器路径 |
| **v1.7.5** | 2026-05-14 | **Bug修复 & 体验优化**：CPU温度采集扩展（CPUTIN/PECI/acpitz/iio_hwmon适配器）；DSM SMART型号为空修复；/tmp入侵误报修复（扩展名白名单）；防火墙规则重复告警修复（去除iptables计数器）；DSM登录记录为空修复（synossh.log直读）；新增浏览器ZIP下载导出；节点卡片网速汇总所有物理网卡 |
| **v1.7.4** | 2026-05-14 | **数据采集深度修复 & 磁盘信息增强**：CPU使用率再次修复（ps aux移出CPU采样窗口并过滤自身）；DSM登录记录修复（syslog格式解析）；DSM cpu_top5空列表修复；CentOS登录时间BSD格式支持；磁盘SMART增强（无SMART磁盘也采集型号/SN/容量）；Web新增RAID阵列展示；节点卡片UI对齐修复 |
| **v1.7.3** | 2026-05-14 | **Cron修复 & CPU精度 & 代码审查**：修复CentOS crontab不执行（Python绝对路径+完整PATH）；修复crontab注释头累积（统一标记清理）；修复CPU使用率虚高（两阶段采样避免ps aux干扰）；节点名称智能默认（localhost→操作系统名）；修复timezone-aware datetime写入SQLite；SQLAlchemy boolean比较规范；全代码安全/质量交叉审查 |
| **v1.7.2** | 2026-05-14 | **数据采集修复 & DSM兼容增强**：修复DSM系统类型检测失败（多维度检测）；修复systemd ExecStart非绝对路径；修复append:回退sed残留文件路径；修复登录记录IP/时间字段错乱；修复日志级别误判（alert-service→INFO）；修复/tmp入侵检测误报；过滤无流量虚拟网卡 |
| **v1.7.1** | 2026-05-14 | **Bug修复 & 体验优化**：修复设置页所有按钮失效（apiPost重复.json()）；节点卡片改IP为标题、精简指标；系统日志默认只显示ERR+WARN；进程监控增强（CPU/内存Top5、进程数tab）；修复CentOS定时上报（crond启动+PATH）；节点色块14→15天；网速指标独占一行；报表中心精简重构 |
| **v1.7.0** | 2026-05-14 | **安全加固 & DSM兼容 & 功能增强**：密码Werkzeug hash加密存储、CSRF防护升级、暴力破解防护；群晖DSM全面兼容（synodisk/synolog/synonet）；新增资产管理（硬件台账与变更记录）、进程监控增强、报表中心告警排行 |
| **v1.6.6** | 2026-05-11 | **时间同步 & 交互增强 & CentOS修复**：全局时间改用服务器时间（/api/server_time），新增时间源/时区配置（设置页）；节点卡片在线badge可点击触发ICMP ping检测，离线badge悬浮显示离线时长；节点卡片顶部新增14天在线状态色块（类GitHub贡献图）；修复CentOS crontab -l无任务时返回非零码导致定时任务安装失败问题（去除set -e，改用_safe_crontab_list） |
| **v1.6.5** | 2026-05-11 | **精度修复 & 功能精简**：CPU采样间隔升至1s修复虚高问题；内存加入SReclaimable修复旧内核10%误差；监听端口采集全面重写兼容所有Linux发行版（含/proc/net兜底）；去除软件资产统计、进程CPU/内存Top10；去除历史趋势图及时间范围按钮（只保留实时数据）；新增定时导出节点原始JSON数据功能（设置页配置） |
| **v1.6.4** | 2026-05-11 | **service.sh 部署修复 & 状态增强**：deploy.sh 部署时拷贝 service.sh 到安装目录；agent/service.sh 新增"上报状态"显示（上次上报时间、下次上报时间）；agent/service.sh cmd_start() 自动安装定时任务；修复 agent.conf 路径检测问题 |
| **v1.6.0** | 2026-05-09 | **稳定性修复**：修复Flask-SQLAlchemy 3.x兼容性导致服务启动失败；修复session访问异常导致页面白屏；UI优化：首页精简、设置页排版调整 |
| **v1.5.0** | 2026-05-09 | **P2/P3优化**：全局Toast提示组件、CDN本地化支持说明、Agent采集效率优化；安全增强：CSRF防护、暴力破解防护、会话管理优化 |
| **v1.4.0** | 2026-04-xx | **资产与端口监控**：新增端口监听记录(PortRecord)、资产管理页面、报表中心；新增手动删除节点功能 |
| **v1.3.0** | 2026-03-xx | **性能与稳定性**：Agent SMART/温度并发采集、进程监控合并为单次ps调用、登录日志限流；服务端查询分页限制防OOM |
| **v1.2.0** | 2025-05-09 | P1/P2 全面修复：/proc/stat严谨解析、弃用API替换（utcnow→timezone.utc） |
| v1.1.0 | - | systemd权限修复、PEP 668兼容、venv路径传递、CentOS SSL编译、Agent自动注册 |
| v1.0.0 | - | 初始版本 |

---

## 快速部署

### 前提条件

- Linux系统（CentOS 7+/Debian 10+/Ubuntu 18+）
- Python 3.6+
- root或sudo权限

### 第一步：部署服务端（在监控中心机器上执行）

```bash
# 1. 将本目录上传到服务器
scp -r ops-monitor/ root@192.168.1.100:/tmp/

# 2. 执行部署脚本
cd /tmp/ops-monitor
chmod +x deploy.sh
bash deploy.sh server

# 按提示输入：
# - Web监听端口（默认8080）
# - 部署目录（默认/opt/ops-monitor）
# - SMTP邮件配置（可选，后续在Web界面配置）
```

### 第二步：部署Agent端（在每台被监控机器上执行）

```bash
# 复制agent目录和deploy.sh到目标机
scp -r ops-monitor/ root@192.168.1.101:/tmp/

# 执行Agent部署
cd /tmp/ops-monitor
chmod +x deploy.sh
bash deploy.sh agent

# 按提示输入：
# - 服务端IP地址（如 192.168.1.100）
# - 服务端端口（默认8080）
# - 本节点名称（如 web-server-01）
```

### 第三步：访问Web界面

打开浏览器访问 `http://服务端IP:8080`  
默认账号：`admin`，密码由系统随机生成并保存至 `data/default_admin_password.txt`  
**⚠️ 首次登录后请立即修改密码！**

---

## 功能说明

### 监控数据采集（每3小时自动上报）

| 模块 | 采集内容 |
|------|----------|
| 系统基础 | CPU使用率/负载、内存、磁盘、网卡速率、开机时长 |
| 温度 | CPU温度（lm-sensors）、硬盘温度（smartctl） |
| SMART | 硬盘健康状态、坏道数、通电时长（支持SATA/SSD/NVMe） |
| 进程 | CPU/内存TOP10、僵尸进程、异常进程检测 |
| 安全 | 登录记录、配置文件变更、入侵检测、防火墙变更 |
| 资产 | 硬件台账、软件清单 |
| 日志 | 系统关键日志（journalctl/messages） |
| 端口 | TCP/UDP监听端口及进程信息 |

### 心跳与告警（实时）

- 每5分钟发送一次心跳（确保节点在线状态）
- 每15分钟进行一次安全告警检测
- 节点超过5分钟无心跳则标记为离线并触发告警

### 告警系统

- **CPU/内存/磁盘/温度**：超过阈值自动告警（默认：CPU 90%、内存 90%、磁盘 85%）
- **节点离线**：超时未上报立即告警
- **安全事件**：异地登录、暴力破解、文件变更、入侵检测
- **邮件通知**：HTML格式邮件，包含节点信息和告警详情
- **告警抑制**：相同类型告警30分钟内不重复发送

---

## 服务管理

```bash
# 查看所有服务状态
bash deploy.sh status

# 启动/停止/重启所有服务
bash deploy.sh start
bash deploy.sh stop
bash deploy.sh restart

# 查看服务日志
journalctl -u ops-monitor-web -f

# 手动触发Agent上报（调试用）
bash /opt/ops-agent/re-report.sh           # 完整上报（默认）
bash /opt/ops-agent/re-report.sh full      # 完整上报
bash /opt/ops-agent/re-report.sh alert     # 仅安全告警
bash /opt/ops-agent/re-report.sh heartbeat # 仅心跳
```

---

## 系统配置

在Web界面 **系统设置** 页面可配置：

| 配置项 | 说明 |
|--------|------|
| SMTP服务器 | 用于发送告警邮件（支持QQ邮箱/Gmail/企业邮箱） |
| 告警收件人 | 支持多个邮件地址 |
| CPU告警阈值 | 默认90% |
| 内存告警阈值 | 默认90% |
| 磁盘告警阈值 | 默认85% |
| 温度告警阈值 | CPU默认80℃，硬盘默认55℃ |
| 告警抑制时间 | 默认30分钟 |
| 离线判定超时 | 默认300秒（5分钟） |

每个节点也可单独配置告警阈值，在节点详情页进行设置。

---

## QQ邮箱SMTP配置参考

```
SMTP服务器：smtp.qq.com
端口：465（SSL加密）
用户名：你的QQ邮箱（如 123456789@qq.com）
密码：QQ邮箱授权码（非登录密码，在QQ邮箱设置→账户→开启SMTP服务获取）
```

---

## 常见问题

**Q: Agent上报失败怎么办？**  
A: 检查 /opt/ops-agent/cron.log，确认服务端地址和端口是否正确，服务端防火墙是否放行。

**Q: 温度数据显示为"-"？**  
A: 需要安装 `smartmontools`（硬盘温度）和 `lm-sensors`（CPU温度）并运行 `sensors-detect`。

**Q: SMART数据无法采集？**  
A: 确认 `smartctl -a /dev/sda` 命令可以正常执行（部分虚拟机不支持SMART）。

**Q: 如何添加更多被监控的配置文件？**  
A: 编辑 `agent.py` 中的 `WATCHED_FILES` 列表，或在 `agent.conf` 中配置 `EXTRA_WATCHED_FILES`。

**Q: 数据库在哪里？**  
A: 默认路径 `/opt/ops-monitor/data/monitor.db`（SQLite文件）。

---

## 技术架构说明

```
子节点 (Agent)                   主节点 (Server)
┌────────────────────┐           ┌──────────────────────────────┐
│  agent.py          │  HTTP     │  Flask Web Server            │
│  ├─ 系统信息采集   │ ─────────▶│  ├─ 数据接收 API             │
│  ├─ SMART采集      │  gzip压缩 │  ├─ SQLite 数据存储          │
│  ├─ 安全监控       │           │  ├─ 离线检测服务（后台线程）   │
│  └─ HTTP上报       │           │  ├─ 告警服务（后台线程）      │
│                    │  心跳     │  └─ Web仪表盘                │
│  crontab定时任务:  │ ─────────▶│                              │
│  - 每3小时完整上报 │           │  访问：http://IP:PORT        │
│  - 每5分钟心跳     │           └──────────────────────────────┘
│  - 每15分钟告警检测│
└────────────────────┘
```

---

*本系统由运维监控工具生成，使用中文注释，仅供内部使用。*
