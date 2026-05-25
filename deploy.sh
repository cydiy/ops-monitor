#!/bin/bash
# ================================================================
# 运维监控系统 - 一键部署脚本 v1.9.9
# 支持：服务端部署 / Agent端部署 / 服务管理 / 密码重置
# 用法：bash deploy.sh [install|start|stop|restart|status|server|agent]
#       python3 server/main.py --reset-password [用户名]  # 重置密码
#
# 修复历史：
#   v1.9.9 - 安全加固 & 体验优化：
#        - [安全] Session Cookie 添加 HttpOnly/SameSite/Lax（P0-1）
#        - [安全] 完全移除 _run_pipe() shell=True 函数，消除代码注入隐患（P0-3）
#        - [修复] 邮件告警时间从 UTC 改为服务器本地时区（Asia/Shanghai）
#        - [优化] SMART 告警阈值放宽：坏道>50、SSD磨损<=5%、NVMe备用<=5%
#        - [优化] 节点详情页移除 Swap 监控项、移除 SMART 表 NVMe 列
#        - [修复] 群晖 DSM NVMe 磁盘采集 Bug：正则捕获 /dev/nvme0 导致路径错位为 /dev//dev/nvme0
#        - [修复] 网卡历史图表补零缺陷：新出现网卡补齐之前时间点数据
#        - [优化] 登录记录仅展示最近5条
#        - [优化] 系统日志移至网卡实时速率下方，同宽度
#        - [新增] /opt/ops-agent/re-report.sh 重新上报控制脚本
#   v1.9.8 - DSM SMART采集修复：
#        - [修复] synodisk/synohdparm 无输出时，枚举 /dev/sata* 用 smartctl 直接采集
#        - [修复] NVMe 幽灵条目：仅命名空间存在时才认为有 NVMe 盘，采集失败不创建空条目
#   v1.9.7 - DSM RAID假阳性修复：
#        - [修复] DSM md0/md1 系统盘误报RAID降级（热备盘导致的正常degraded状态）
#        - [修复] alert_service 双重防护跳过DSM系统盘degraded告警
#   v1.9.6 - 生产数据质量修复：
#        - [修复] DSM磁盘fstype显示设备路径(/dev/md0)而非文件系统类型
#        - [新增] 内存Swap信息采集(swap_total/swap_used/swap_free)
#        - [新增] 节点详情页显示Swap使用情况
#   v1.9.5 - 时区修正 & 离线检测优化：
#        - [修复] **根本原因**：formatLocalTime 用 getHours 导致浏览器时区二次叠加
#        - [修复] 改为 getUTCHours/getUTCMonth 等，时间显示不再双倍偏移
#        - [修复] _parse_iso 非UTC时区转换丢失（astimezone → UTC 后再去 tzinfo）
#        - [修复] Agent 上报前 NTP 对时（chronyd / ntpdate / timedatectl 三级回退）
#        - [修复] 时间转换改用 time.mktime + fromtimestamp（替代 time.timezone 偏移量）
#        - [修复] auth.log 登录记录时间未转换的遗漏
#        - [优化] 离线检测改为3次心跳无上报=离线（900s），移除ICMP ping依赖
#        - [新增] 服务端版本号显示（右上角）/ Agent版本号（IP|在线行）
#        - [新增] 告警中心一键批量处理（按级别/全部）
#        - [新增] Agent版本上报与存储（heartbeat/full/alert三通道）
#   v1.9.4 - 项目恢复与重新打包：
#        - [恢复] 从备份恢复全部项目文件，交叉校验完整性
#        - [验证] 所有v1.9.3功能特性确认完整无损
#   v1.9.3 - 硬件告警 & 数据质量修复：
#        - [新增] 9类硬件故障告警（SMART故障/坏道/SSD磨损/NVMe备用/RAID降级/RAID故障/僵尸进程/进程CPU异常/进程内存泄漏）
#        - [修复] nftables/firewalld防火墙告警归一化去除动态计数器
#        - [修复] 登录记录过滤空条目和wtmpdb
#        - [修复] Asset CPU型号从sysinfo同步
#        - [新增] 内存DIMM采集(dmidecode)
#        - [精简] 移除UDP端口监控减少噪音
#        - [修复] 排除/etc/crontab自修改误报
#        - [修复] RAID标签去除DSM字样
#   v1.9.2 - 项目精简 & 安全增强：
#        - [清理] 删除所有运行时日志、过期缓存、session文件、__pycache__
#        - [新增] .gitignore 防止运行时文件再次积累
#        - [修复] 手动添加节点自动生成token（api_create_node + _get_or_create_node）
#        - [修复] 离线超7天节点不再触发告警和日志刷屏
#        - [修复] 节点注册增加node_id/IP格式校验
#        - [修复] SMTP未配置警告日志从30秒一次抑制为60分钟一次
#   v1.9.1 - Bug修复 & 稳定性增强：
#        - [修复] 手动添加节点无token导致无法认证
#        - [修复] 告警服务每30秒日志刷屏
#        - [修复] reset_password因instance目录缺失崩溃
#        - [修复] evil-node恶意IP数据清理
#   v1.9.0 - 功能重构 & 时间统一：
#        - [重写] 导出模块：路径必填+黑名单校验系统目录
#        - [重构] 设置页：移除离线检测和数据管理卡片，邮件告警移至最下方
#        - [修复] 全局时间统一为服务器时区显示（formatLocalTime）
#        - [修复] 导出路径限制在exports子目录导致文件不可见
#   v1.8.3 - systemd兼容修复：
#        - [修复] StandardOutput/Error 从 append: 改为 journal（兼容 CentOS 7 systemd 219）
#        - [新增] 每次运行自动修复已部署 service 文件中的 append:/journal: 残留
#   v1.8.2 - 导出功能修复：
#        - [修复] api_export_now BASE_DIR→base_dir 未定义变量
#        - [修复] 统一导出为服务器端（有路径→指定目录，无路径→默认exports目录）
#   v1.8.1 - Bug修复 & 体验优化：
#        - [修复] 导出功能简化（有路径→服务器导出，无路径→浏览器下载）
#        - [修复] 设置页卡片重新排版（CSS Grid统一尺寸间距）
#        - [修复] systemd服务文件journal:语法错误
#   v1.8.0 - 数据管理 & 功能增强：
#        - [新增] 节点历史数据清除功能（单节点/全部节点），保留配置和硬件资产
#        - [增强] 导出fallback：raw_data过期时从结构化字段重建导出数据
#        - [增强] 定时导出>60天旧文件自动清理
#        - [优化] 设置页新增数据管理卡片
#        - [移除] 节点详情页RAID表格"成员盘"列
#   v1.7.9 - 数据质量修复：
#        - [P0修复] DSM smart[].model=null：优先匹配Device Model正则 + synodisk信息补充
#        - [P0修复] DSM NVMe磁盘缺失：改进nvme list正则 + 5级降级SMART采集策略
#        - [P0修复] CentOS/DSM登录记录为空：增加auth.log/journalctl兜底 + 扩大tail行数
#        - [P1修复] sys_logs噪音去重：按(source,message指纹)分组，每组保留≤3条
#        - [P1修复] 虚拟网络接口过滤：扩展docker/cali/flannel/cni/kube/lxc/tap/virbr前缀
#        - [P1修复] DSM raid_info degraded误报：mdstat交叉验证，mdstat正常时标记疑误报
#   v1.7.8 - 安全加固 & Bug修复：
#        - [安全] Agent _run() 从 shell=True 改为 shell=False（消除命令注入风险）
#        - [安全] 导出API路径遍历修复：export_path 限制在 exports 目录内
#        - [安全] deploy.sh SMTP配置改为环境变量+json.dumps（消除Python代码注入）
#        - [安全] 密码复杂度提升：8位+大小写+数字，强制改密拦截API
#        - [安全] /tmp 临时文件改用 mktemp 避免符号链接攻击
#        - [修复] get_login_records() 缺失 for 循环头（非DSM系统IndentationError）
#        - [修复] _get_disk_device_list() synodisk 结果被无条件覆盖
#   v1.7.7 - 功能增强 & DSM NVMe支持：
#        - [新增] 节点卡片网速区域显示累计上下行流量
#        - [新增] DSM NVMe SMART信息采集（nvme smart-log + nvme list）
#        - [修复] DSM磁盘设备列表未包含NVMe设备
#        - [移除] 报表中心告警次数趋势卡片
#   v1.7.6 - 生产环境验证修复：
#        - [修复] 网卡历史图表无数据：times/series长度不一致，补零+过滤虚拟网卡
#        - [修复] CPU温度采集重构：移除DSM错误磁盘温度方案，新增/sys/class/hwmon兜底，兼容Armbian/DSM
#        - [修复] CentOS登录记录为空：last命令DNS反解析问题+auth log格式自动检测
#        - [修复] 导出下载403：fetch未带CSRF token；立即导出不再要求填写服务器路径
#   v1.7.5 - Bug修复 & 体验优化：
#        - [修复] CPU温度采集：扩展lm-sensors匹配（CPUTIN/PECI/acpitz/iio_hwmon/k10temp等适配器）
#        - [修复] DSM SMART型号为空：JSON model_name为空时回退文本解析Device Model
#        - [修复] /tmp入侵误报：添加扩展名白名单（.tar.gz/.zip/.log等SCP传输文件）
#        - [修复] 防火墙规则重复告警：规范化iptables-save输出去除[packets:bytes]计数器
#        - [修复] DSM登录记录为空：改用synossh.log直读替代不可用的synolog命令
#        - [增强] 导出功能：新增浏览器ZIP下载，无需服务器存储路径
#        - [增强] 节点卡片网速：汇总所有物理网卡上下行速率
#   v1.7.4 - 数据采集深度修复 & 磁盘信息增强 & RAID展示：
#        - [修复] CPU使用率虚高（再次修复）：将get_process_info移出并行线程池，在CPU采样之后执行
#        - [修复] ps aux自身被列为cpu_top5进程（debian 200%, armbian 266%），过滤ps aux自身
#        - [修复] DSM采集不到登录记录：新增/var/log/messages syslog格式解析、synolog SYNO.Auth日志源
#        - [修复] DSM cpu_top5为空：改为始终显示前5进程（即使CPU%为0）
#        - [修复] CentOS登录记录时间字段为空：支持BSD时间格式(Mon May 14 02:11)
#        - [增强] 磁盘SMART采集：即使磁盘不支持SMART也提取型号/SN/容量/温度（VMware虚拟盘可用）
#        - [增强] Web磁盘SMART表格新增：型号、容量、SN号列；健康状态N/A灰显
#        - [新增] RAID阵列信息Web展示（DSM md0/md1/md2等设备、级别、状态、成员盘）
#        - [修复] 节点概览卡片上3下1矩形宽度不对齐：metric-chip改flex:1等宽
#   v1.7.3 - Cron修复 & CPU精度 & 代码质量：
#        - [修复] CentOS crontab定时任务不执行：Python路径解析为绝对路径，cron环境添加完整PATH
#        - [修复] crontab重复注释头累积：统一使用 OPS-MONITOR-CRON 标记，旧注释正确清理
#        - [修复] CPU使用率虚高：重构为两阶段采样（所有重操作前/后），避免ps aux瞬时峰值干扰
#        - [优化] 节点名称智能默认：hostname为localhost时自动使用操作系统名称(centos/debian等)
#        - [修复] timezone-aware datetime写入SQLite兼容问题（alert/offline_detector服务）
#        - [修复] SQLAlchemy boolean comparison使用.is_(False)替代==False
#        - [审查] 全代码交叉审查：安全性、时区一致性、cron健壮性、路径解析
#   v1.7.2 - 数据采集修复 & DSM兼容增强：
#        - [修复] DSM系统类型检测失败：新增多维度检测（/etc/default/synoinfo.conf + synodisk工具路径）
#        - [修复] systemd ExecStart非绝对路径：自动解析Python绝对路径，修复CentOS/DSM服务无法启动
#        - [修复] systemd append:回退sed残留路径：journal:/path 改为纯 journal:（journal不接受文件路径）
#        - [修复] 登录记录IP/时间字段错乱：tty本地登录不再将weekday/时间戳误解析为IP
#        - [修复] 日志级别误判：优先匹配[INFO]/[ERROR]结构化前缀，避免"alert-service"被标为ERROR
#        - [修复] /tmp入侵检测误报：增加白名单（ks-script/pip-/systemd-等系统临时文件）
#        - [优化] net_info过滤无流量虚拟网卡（bond/gre/tunl等零流量接口不再上报）
#        - [优化] DSM登录记录增加synolog专用日志源
#   v1.7.1 - Bug修复 & 体验优化：
#        - [修复] 修复CentOS定时上报：自动检测并启动crond服务，cron条目设置PATH和cd工作目录
#        - [修复] 修复设置页面所有保存/测试按钮失败（apiPost已解析JSON却再次调用.json()）
#        - [优化] 设置界面卡片重新排版设计，布局更清晰
#        - [优化] 节点卡片简化：只显示IP、CPU/内存/磁盘/网速4个指标
#        - [优化] 告警徽章移至在线徽章左侧
#        - [优化] 系统日志默认只展示ERR和WARN级别
#        - [功能] 进程监控增加进程总数显示和CPU/内存Top5标签页
#        - [功能] 数据库ProcessRecord新增proc_count字段
#   v1.7.0 - 安全加固 & DSM兼容 & 功能增强：
#        - [安全] Agent日志增加轮转（5MB x 5），防止日志撑满磁盘
#        - [安全] Agent总执行时间限制600秒，防止卡死影响节点
#        - [安全] pending缓存文件数量限制50个，防止堆积
#        - [安全] 服务端raw_data定期清理增强
#        - [兼容] 完整适配群辉Synology DSM 7.2系统
#        - [兼容] DSM下smartctl使用/dev/sata*路径
#        - [兼容] DSM下支持mdadm RAID信息采集
#        - [兼容] DSM下支持synodisk命令
#        - [兼容] DSM下busybox df/sensors/journalctl等命令降级
#        - [功能] 节点详情网卡速率增加历史趋势图表
#        - [功能] 节点总览增加告警状态标识（高危/告警/正常）
#        - [功能] 报表中心增加温度趋势和在线率趋势图
#        - [修复] 修复导出按钮res.json is not a function错误
#   v1.6.6 - 时间同步 & 交互增强 & CentOS修复：
#        - 全局时间改用服务器时间（/api/server_time 接口），避免告警时间混乱
#        - 新增时间源/时区配置卡片（设置页，支持 Asia/Shanghai 等）
#        - 节点卡片在线 badge 可点击触发 ICMP ping 检测真实连通性
#        - 节点卡片离线 badge 悬浮显示离线时长
#        - 节点卡片顶部新增 14 天在线状态色块（类 GitHub 贡献图）
#        - 修复 CentOS crontab -l 无任务时返回非零码导致定时任务安装失败（去除 set -e）
#   v1.6.5 - 精度修复 & 功能精简：
#        - CPU 采样间隔升至 1s，修复虚高问题；dt 小于 10 时返回 0 防噪声
#        - 内存加入 SReclaimable 修复旧内核 10% 误差
#        - 监听端口采集重写：兼容 ss/netstat/proc/net 全链路兜底
#        - 去除软件资产统计、进程 CPU/内存 Top10
#        - 去除历史趋势图及时间范围按钮，节点详情只展示实时数据
#        - 新增定时导出节点原始 JSON 数据功能（设置页配置）
#   v1.6.4 - service.sh 部署修复 & 状态增强：
#        - 修复 deploy.sh：部署时拷贝 agent/service.sh 和 server/service.sh 到安装目录
#        - 修复 agent/service.sh：新增"上报状态"显示（上次上报时间、下次上报时间）
#        - 修复 agent/service.sh cmd_start()：自动安装定时任务（如果未配置）
#        - 修复 agent.conf 路径检测问题（service.sh 现在部署到正确目录）
#   v1.6.3 - 版本号全局统一 & 重新打包：
#        - 全局版本号统一更新为 v1.6.3（agent/agent.py、server/app.py、deploy.sh banner、README.md）
#        - README.md 版本历史新增 v1.6.3 条目
#   v1.6.2 - 群晖兼容性增强 & Agent 开机自启：
#        - 修复群晖 NAS 监听端口采集（ss 缺失，降级使用 netstat）
#        - 修复群晖 NAS 登录记录采集（新增 /var/log/synolog/synossh.log 路径）
#        - 新增 _setup_agent_autostart()：支持 systemd/rc.local/群晖rc.d 三种开机自启方式
#        - 新增 agent/service.sh：Agent 服务管理脚本（start/stop/restart/status/uninstall）
#        - 新增 server/service.sh：Server 服务管理脚本（start/stop/restart/status/enable/disable/log/uninstall）
#        - 离线检测升级：超时后主动 ICMP ping 探测，双重确认才标记离线
#        - 新增 setup_cron() 智能定时任务安装（兼容标准Linux + 群晖 /etc/crontab）
#        - 群晖系统自动使用 /etc/crontab + user字段格式写入cron任务
#        - service_status() 兼容群晖 cron 任务检查
#   v1.6 - 稳定性 & UI优化：
#        - 修复 Flask-SQLAlchemy 3.x 兼容性（db.get_engine KeyError）
#        - 修复 context_processor session访问异常导致白屏
#        - 首页移除添加节点按钮（节点通过Agent自动注册）
#        - 设置页面排版优化（卡片紧凑布局）
#   v1.5 - 安全与体验优化：
#        - CSRF防护验证
#        - 暴力破解防护（连续失败5次锁定15分钟）
#        - Session清理后台线程
#        - 全局Toast提示组件
#        - 端口监听记录采集
#   v1.4 - 资产与端口监控：
#        - 新增端口监听记录(PortRecord)
#        - 新增资产管理页面
#        - 新增报表中心（Web展示+离线统计）
#        - 新增手动删除节点功能
#   v1.3 - 性能与稳定性：
#        - Agent: SMART/磁盘温度并发采集（ThreadPoolExecutor）
#        - Agent: 进程监控 4次ps→1次合并调用
#        - Agent: 登录日志限流 tail-5000
#        - Agent: /proc/stat 字段解析严谨化（标准8字段）
#        - 服务端: datetime.utcnow() → timezone.utc（Python 3.12+弃用）
#        - 服务端: 历史查询 .limit(2000) 防OOM
#        - 服务端: 报告快照 .limit(5000) 防OOM
#        - 服务端: 静默异常改为 logger.warning
# ================================================================
set -e

# ─────────────── 颜色定义 ───────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'  # 无颜色

info()    { echo -e "${CYAN}[INFO]${NC}  $1"; }
success() { echo -e "${GREEN}[OK]${NC}    $1"; }
warn()    { echo -e "${YELLOW}[WARN]${NC}  $1"; }
error()   { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }
prompt()  { echo -e "${BLUE}[INPUT]${NC} $1"; }

# ─────────────── 基础变量 ───────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_DIR="/opt/ops-monitor"
LOG_DIR="/var/log/ops-monitor"
PID_DIR="/var/run/ops-monitor"

banner() {
echo -e "${CYAN}"
echo "  ╔═══════════════════════════════════════╗"
echo "  ║     运维监控系统  Ops Monitor v1.9.8   ║"
echo "  ║     轻量级主从架构系统运维工具         ║"
echo "  ╚═══════════════════════════════════════╝"
echo -e "${NC}"
}

# ══════════════════════════════════════════
# 环境检查 & 自动升级Python
# ══════════════════════════════════════════
MIN_PYTHON_VER=38  # 最低要求 3.8 (Flask 2.3+ 需要)

check_env() {
    info "检查运行环境..."

    # 操作系统检测
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS_NAME="$PRETTY_NAME"
        OS_ID="$ID"
        OS_VERSION_ID="${VERSION_ID:-}"
    else
        OS_NAME=$(uname -sr)
        OS_ID="unknown"
    fi
    info "操作系统: $OS_NAME"

    # Python版本检查（优先找高版本）
    PYTHON_BIN=""
    for py in python3.13 python3.12 python3.11 python3.10 python3.9 python3.8 python3; do
        if command -v "$py" &>/dev/null; then
            ver=$("$py" -c 'import sys; print(sys.version_info.major*10+sys.version_info.minor)' 2>/dev/null) || continue
            if [ -n "$ver" ] && [ "$ver" -ge "$MIN_PYTHON_VER" ]; then
                PYTHON_BIN="$py"
                info "Python: $($py --version 2>&1)"
                break
            fi
        fi
    done

    # 如果没找到足够新的Python，尝试自动安装
    if [ -z "$PYTHON_BIN" ]; then
        warn "未找到 Python 3.8+，当前系统Python版本过低"
        install_new_python
        # 安装完成后重新查找（优先找刚安装的绝对路径）
        for py in /usr/local/bin/python3.10 /usr/local/bin/python3.11 /usr/local/bin/python3.12 \
                  /usr/local/bin/python3.13 /usr/local/bin/python3 \
                  /usr/bin/python3.10 /usr/bin/python3.11 /usr/bin/python3.12 \
                  python3.13 python3.12 python3.11 python3.10 python3.9 python3.8; do
            if [ -x "$py" ]; then
                ver=$("$py" -c 'import sys; print(sys.version_info.major*10+sys.version_info.minor)' 2>/dev/null) || continue
                if [ -n "$ver" ] && [ "$ver" -ge "$MIN_PYTHON_VER" ]; then
                    PYTHON_BIN="$py"
                    info "使用新安装的Python: $($py --version 2>&1)"
                    break
                fi
            fi
        done
        if [ -z "$PYTHON_BIN" ]; then
            # 尝试诊断：列出所有 python 可执行文件帮助排查
            warn "Python 安装后仍无法找到可用的 Python 3.8+，当前系统中的 Python："
            ls -la /usr/local/bin/python3* 2>/dev/null || true
            ls -la /usr/bin/python3* 2>/dev/null || true
            error "Python 3.8+ 安装失败，请手动安装后重试"
        fi
    fi

    # ── pip/venv 检查（兼容 PEP 668 externally-managed-environment） ──
    # 注意：必须在 PYTHON_BIN 确认有效后才能执行以下检查
    USE_VENV="false"
    VENV_PYTHON=""

    # 先确保 venv + ensurepip 模块可用（Debian/Ubuntu 需要单独装）
    if [ -n "$PYTHON_BIN" ] && ! "$PYTHON_BIN" -c "import venv, ensurepip" &>/dev/null; then
        info "安装 Python venv 支持包..."
        PY_VER_SHORT=$("$PYTHON_BIN" -c 'import sys; print("%d.%d" % (sys.version_info.major, sys.version_info.minor))' 2>/dev/null) || true
        if [ "$OS_ID" = "debian" ] || [ "$OS_ID" = "ubuntu" ]; then
            apt-get update -qq 2>/dev/null || true
            apt-get install -y "python${PY_VER_SHORT}-venv" "python${PY_VER_SHORT}-full" python3-venv 2>/dev/null || \
            apt-get install -y python3-venv python3-full 2>/dev/null || true
        elif command -v yum &>/dev/null || command -v dnf &>/dev/null; then
            yum install -y python3-virtualenv 2>/dev/null || dnf install -y python3-virtualenv 2>/dev/null || true
        fi
    fi

    # 判断是否需要走 venv 模式
    if ! "$PYTHON_BIN" -m pip --version &>/dev/null 2>&1; then
        warn "系统级 pip 不可用，尝试 ensurepip 安装..."
        "$PYTHON_BIN" -m ensurepip --upgrade 2>/dev/null || true
    fi

    # 检测 PEP 668：即使 pip 存在，直接 install 也可能被禁止
    # 用 --dry-run 检测（无副作用）
    if "$PYTHON_BIN" -m pip install --help &>/dev/null 2>&1; then
        if "$PYTHON_BIN" -m pip install flask --dry-run 2>&1 | grep -qi 'externally-managed\|managed-environment'; then
            USE_VENV="true"
            info "检测到系统 Python 受外部管理（PEP 668），将自动创建虚拟环境"
        fi
    else
        USE_VENV="true"
        info "pip 不可用，将使用虚拟环境方式安装依赖"
    fi

    # 对 Debian 系：直接默认走 venv，避免 PEP 668 问题
    if [ "$OS_ID" = "debian" ] || [ "$OS_ID" = "ubuntu" ]; then
        USE_VENV="true"
        info "Debian/Ubuntu 系统：默认使用虚拟环境（避免 PEP 668 限制）"
    fi

    # 如果确定用 venv，再次确认 venv 模块真的可用
    if [ "$USE_VENV" = "true" ]; then
        if ! "$PYTHON_BIN" -c "import venv, ensurepip" 2>/dev/null; then
            warn "venv 模块仍不可用，最后尝试安装..."
            PY_VER_SHORT=$("$PYTHON_BIN" -c 'import sys; print("%d.%d" % (sys.version_info.major, sys.version_info.minor))' 2>/dev/null) || true
            if [ "$OS_ID" = "debian" ] || [ "$OS_ID" = "ubuntu" ]; then
                apt-get update -qq 2>/dev/null || true
                apt-get install -y "python${PY_VER_SHORT}-venv" "python${PY_VER_SHORT}-full" 2>/dev/null || true
            fi
            "$PYTHON_BIN" -c "import venv, ensurepip" 2>/dev/null || \
                error "无法创建虚拟环境。请手动执行: apt install python${PY_VER_SHORT}-venv && 重试"
        fi
    fi

    # 必要命令检查
    for cmd in curl wget grep awk sed; do
        command -v "$cmd" &>/dev/null || warn "命令 $cmd 未找到（可选）"
    done

    success "环境检查通过"
}
# ═════════════════════════════════════════
# 智能Cron任务安装（兼容标准Linux + 群晖）
# ═════════════════════════════════════════
setup_cron() {
    # 用法: setup_cron "LOG_PATH" "cron行1" "cron行2" ...
    local CRON_LOG="$1"; shift
    local CRON_USER="root"

    info "配置定时任务..."

    # 方式1：标准 crontab 命令
    if command -v crontab &>/dev/null; then
        info "使用 crontab 命令配置..."
        ( crontab -l 2>/dev/null | grep -v 'ops-monitor\|ops-agent\|agent\.py\|# OPS-MONITOR-CRON\|运维监控' || true
          echo "# OPS-MONITOR-CRON 运维监控系统 Agent 定时任务（自动生成，请勿手动修改）"
          echo "PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
          for line in "$@"; do echo "$line"; done
        ) | crontab -
        success "定时任务已配置（crontab）"
        return 0
    fi

    # 方式2：群晖 /etc/crontab（多一个 user 字段）
    if [ -f /etc/crontab ]; then
        info "crontab 命令不可用，使用 /etc/crontab 方式（群晖系统）..."
        cp /etc/crontab /etc/crontab.bak.$(date +%Y%m%d%H%M%S) 2>/dev/null || true
        _tmp_cron=$(mktemp /tmp/ops_cron.XXXXXX) || _tmp_cron="/tmp/ops_cron.tmp"
        grep -v 'ops-monitor\|ops-agent\|agent\.py' /etc/crontab 2>/dev/null > "$_tmp_cron" || true
        [ -s "$_tmp_cron" ] && cat "$_tmp_cron" > /etc/crontab || true
        rm -f "$_tmp_cron"

        echo "" >> /etc/crontab
        echo "# ─── 运维监控系统 Agent 定时任务（自动生成，请勿手动修改）───" >> /etc/crontab
        for line in "$@"; do
            echo "$line" | sed "s/^\([*/0-9]\+ [*/0-9]\+ [*/0-9]\+ [*/0-9]\+ [*/0-9]\+ \)/\1${CRON_USER} /" >> /etc/crontab
        done

        if command -v synoservice &>/dev/null; then
            synoservice --restart crond 2>/dev/null || true
        elif [ -x /usr/syno/etc/rc.d/S20crond.sh ]; then
            /usr/syno/etc/rc.d/S20crond.sh restart 2>/dev/null || true
        fi
        success "定时任务已配置（/etc/crontab）"
        return 0
    fi

    warn "未找到 crontab，且 /etc/crontab 不可用"
    warn "请手动将以下任务加入 cron："
    for line in "$@"; do echo "  $line"; done
    return 1
}


# ══════════════════════════════════════════
# Agent 开机自启配置
# 优先 systemd，其次 rc.local（群晖/嵌入式Linux）
# ══════════════════════════════════════════
_setup_agent_autostart() {
    local AGENT_DIR="$1"
    local AGENT_PYTHON="$2"
    local CRON_LOG="${AGENT_DIR}/cron.log"

    info "配置 Agent 开机自启..."

    # ── 方式1：systemd（Debian / CentOS / Rocky 等标准发行版）──
    if command -v systemctl &>/dev/null && systemctl --version &>/dev/null 2>&1; then
        info "检测到 systemd，配置 ops-monitor-agent.service..."
        # 解析为绝对路径（systemd 要求 ExecStart 必须是绝对路径）
        AGENT_PYTHON_ABS="$(command -v "${AGENT_PYTHON}" 2>/dev/null || which "${AGENT_PYTHON}" 2>/dev/null || echo "${AGENT_PYTHON}")"
        if [[ "$AGENT_PYTHON_ABS" != /* ]]; then
            warn "无法解析 ${AGENT_PYTHON} 的绝对路径，尝试 /usr/bin/${AGENT_PYTHON}"
            AGENT_PYTHON_ABS="/usr/bin/${AGENT_PYTHON}"
        fi
        cat > /etc/systemd/system/ops-monitor-agent.service << EOF
[Unit]
Description=运维监控系统 - Agent 开机自启
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
RemainAfterExit=yes
User=root
ExecStart=${AGENT_PYTHON_ABS} ${AGENT_DIR}/agent.py --mode full
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF
        systemctl daemon-reload 2>/dev/null || true
        systemctl enable ops-monitor-agent 2>/dev/null && \
            success "开机自启已配置（systemd ops-monitor-agent.service）" || \
            warn "systemd enable 失败，尝试 rc.local 方式"
        return 0
    fi

    # ── 方式2：rc.local（群晖 DSM / 老式嵌入式 Linux）──
    local RC_LOCAL="/etc/rc.local"
    if [ -f "$RC_LOCAL" ] || [ -d /etc/rc.d ]; then
        [ ! -f "$RC_LOCAL" ] && RC_LOCAL="/etc/rc.d/rc.local"
        if [ -f "$RC_LOCAL" ]; then
            info "使用 rc.local 配置开机自启: $RC_LOCAL"
            # 备份
            cp "$RC_LOCAL" "${RC_LOCAL}.bak.$(date +%Y%m%d%H%M%S)" 2>/dev/null || true
            # 移除旧条目
            _tmp_rc=$(mktemp /tmp/rc_local.XXXXXX) || _tmp_rc="/tmp/rc_local.tmp"
            grep -v 'ops-monitor\|ops-agent' "$RC_LOCAL" > "$_tmp_rc" || true
            cat "$_tmp_rc" > "$RC_LOCAL"
            rm -f "$_tmp_rc"
            # 确保末尾有 exit 0 前插入我们的命令
            if grep -q '^exit 0' "$RC_LOCAL"; then
                sed -i '/^exit 0/i # ops-monitor agent 开机自启\n'"${AGENT_PYTHON} ${AGENT_DIR}/agent.py --mode full >> ${CRON_LOG} 2>&1 &" "$RC_LOCAL"
            else
                echo "" >> "$RC_LOCAL"
                echo "# ops-monitor agent 开机自启" >> "$RC_LOCAL"
                echo "${AGENT_PYTHON} ${AGENT_DIR}/agent.py --mode full >> ${CRON_LOG} 2>&1 &" >> "$RC_LOCAL"
            fi
            chmod +x "$RC_LOCAL" 2>/dev/null || true
            success "开机自启已配置（$RC_LOCAL）"
            return 0
        fi
    fi

    # ── 方式3：群晖 DSM 自定义开机脚本目录 ──
    if [ -d /usr/local/etc/rc.d ]; then
        local SYNO_RC="/usr/local/etc/rc.d/S99ops-monitor-agent.sh"
        info "检测到群晖自定义开机目录，写入 $SYNO_RC..."
        cat > "$SYNO_RC" << EOF
#!/bin/sh
# 运维监控系统 Agent 开机自启
# Synology DSM 自定义开机脚本
case "\$1" in
    start)
        ${AGENT_PYTHON} ${AGENT_DIR}/agent.py --mode full >> ${CRON_LOG} 2>&1 &
        ;;
    stop)
        ;;
    *)
        echo "Usage: \$0 {start|stop}"
        ;;
esac
EOF
        chmod +x "$SYNO_RC" 2>/dev/null || true
        success "开机自启已配置（群晖 $SYNO_RC）"
        return 0
    fi

    warn "未能自动配置开机自启，请手动添加以下命令到开机脚本："
    warn "  ${AGENT_PYTHON} ${AGENT_DIR}/agent.py --mode full >> ${CRON_LOG} 2>&1 &"
}



# ══════════════════════════════════════════
# 自动安装新版Python（用于CentOS 7等老系统）
# ══════════════════════════════════════════
install_new_python() {
    local target_ver="3.11"
    local PY_VER_FULL="3.11.9"

    # CentOS 7 的默认 gcc 4.8.5 无法编译 Python 3.11，自动降级到 3.10.14
    if [ "$OS_ID" = "centos" ] || [ "$OS_ID" = "rhel" ]; then
        if [ -f /etc/redhat-release ]; then
            _centos_major=$(sed -rn 's/.* ([0-9]+)\..*/\1/p' /etc/redhat-release 2>/dev/null)
            if [ "$_centos_major" = "7" ]; then
                target_ver="3.10"
                PY_VER_FULL="3.10.14"
                warn "CentOS 7 检测到，gcc 版本过低，改用 Python ${PY_VER_FULL}"
            fi
        fi
    fi

    info "尝试自动安装 Python ${target_ver}..."

    # 检查是否已安装（用 if 避免 || && 优先级陷阱）
    if [ -x "/usr/local/bin/python${target_ver}" ] || [ -x "/usr/bin/python${target_ver}" ]; then
        # 验证已存在的 Python 是否能正常运行（可能二进制在但缺依赖库）
        _existing_py=""
        [ -x "/usr/local/bin/python${target_ver}" ] && _existing_py="/usr/local/bin/python${target_ver}"
        [ -z "$_existing_py" ] && [ -x "/usr/bin/python${target_ver}" ] && _existing_py="/usr/bin/python${target_ver}"

        if "$_existing_py" -c "import sys; print('ok')" &>/dev/null; then
            info "已存在 Python ${target_ver}，跳过编译"
            return 0
        else
            warn "检测到 $_existing_py 但无法运行（可能缺少依赖库），将重新安装"
        fi
    fi

    if [ "$OS_ID" = "centos" ] || [ "$OS_ID" = "rhel" ] || [ "$OS_ID" = "rocky" ] || [ "$OS_ID" = "almalinux" ]; then
        # ── CentOS 7 / RHEL 系列：源码编译 ──
        info "RHEL/CentOS 系统将通过源码编译安装 Python ${target_ver}（约3-5分钟）..."

        info "安装编译依赖..."
        yum install -y gcc make wget openssl-devel bzip2-devel libffi-devel zlib-devel \
            sqlite-devel readline-devel xz-devel 2>/dev/null || {
            warn "yum 安装部分依赖失败，尝试继续..."
        }

        local PY_SRC_URL="https://www.python.org/ftp/python/${PY_VER_FULL}/Python-${PY_VER_FULL}.tgz"
        local PY_SRC_DIR="/tmp/Python-${PY_VER_FULL}"

        if [ ! -d "${PY_SRC_DIR}" ]; then
            info "下载 Python ${PY_VER_FULL} 源码..."
            wget -q "${PY_SRC_URL}" -O "/tmp/Python-${PY_VER_FULL}.tgz" || \
                error "下载失败，请检查网络。手动: wget ${PY_SRC_URL}"
            tar -xf "/tmp/Python-${PY_VER_FULL}.tgz" -C /tmp/
        fi

        info "编译安装 Python ${PY_VER_FULL}（请耐心等待）..."
        cd "${PY_SRC_DIR}"

        # CentOS 7：激活 devtoolset 获取较新版本的 gcc（需要预先安装）
        if [ "$OS_ID" = "centos" ] && [ -f /etc/redhat-release ]; then
            _centos_major=$(sed -rn 's/.* ([0-9]+)\..*/\1/p' /etc/redhat-release 2>/dev/null)
            if [ "$_centos_major" = "7" ]; then
                if command -v scl &>/dev/null && scl list-installed 2>/dev/null | grep -q devtoolset; then
                    info "检测到 devtoolset，激活新版 gcc..."
                    . scl_source enable devtoolset-11 2>/dev/null || \
                    . scl_source enable devtoolset-10 2>/dev/null || \
                    . scl_source enable devtoolset-9 2>/dev/null || true
                else
                    warn "CentOS 7 建议使用 devtoolset-11 编译 Python，尝试安装..."
                    yum install -y centos-release-scl 2>/dev/null && \
                    yum install -y devtoolset-11 2>/dev/null && \
                    . scl_source enable devtoolset-11 2>/dev/null || true
                fi
            fi
        fi

        # CentOS 7 需要指定 openssl 路径，否则 pip/ssl 不可用
        local OPENSSL_PATH=""
        for ossl_dir in /usr/local/openssl /usr /usr/local; do
            if [ -f "${ossl_dir}/include/openssl/ssl.h" ]; then
                OPENSSL_PATH="${ossl_dir}"
                break
            fi
        done

        local CONFIGURE_OPTS="--prefix=/usr/local --with-ensurepip=install"
        [ -n "$OPENSSL_PATH" ] && CONFIGURE_OPTS="${CONFIGURE_OPTS} --with-openssl=${OPENSSL_PATH}"

        # CentOS 7 的 gcc 4.8.5 不支持 PGO（--enable-optimizations），
        # 编译会报 SystemError: <built-in function compile> returned NULL
        if [ "$_centos_major" = "7" ] 2>/dev/null; then
            info "CentOS 7 检测到，跳过 --enable-optimizations（gcc 4.8 不支持 PGO）"
            CONFIGURE_EXTRA=""
        else
            CONFIGURE_EXTRA="--enable-optimizations"
        fi

        info "执行 ./configure ${CONFIGURE_EXTRA:-} ..."
        ./configure ${CONFIGURE_OPTS} ${CONFIGURE_EXTRA} 2>&1 | tail -20 || \
            error "Python configure 失败，请检查编译依赖（gcc, openssl-devel 等）"

        # 先尝试正常 make；如果失败且是 CentOS 7，清理后重试不带 PGO
        info "执行 make -j$(nproc) ..."
        if ! make -j$(nproc) 2>&1 | tail -30; then
            warn "make 首次失败，清理并重试..."
            make clean 2>/dev/null || true
            # 去掉 --enable-optimizations 重试 configure + make
            ./configure ${CONFIGURE_OPTS} 2>&1 | tail -10 || true
            make -j$(nproc) 2>&1 | tail -30 || error "Python 编译失败（重试也失败了），请查看上方错误信息"
        fi

        info "执行 make altinstall ..."
        make altinstall 2>&1 | tail -10 || error "Python altinstall 失败"

        cd /
        rm -rf "${PY_SRC_DIR}" "/tmp/Python-${PY_VER_FULL}.tgz" 2>/dev/null || true

        # 创建软链接（不覆盖系统 python3）
        [ ! -x /usr/local/bin/python3 ] && [ -x "/usr/local/bin/python${target_ver}" ] && \
            ln -sf "/usr/local/bin/python${target_ver}" /usr/local/bin/python3

        success "Python ${target_ver} 编译安装完成"

    elif [ "$OS_ID" = "debian" ] || [ "$OS_ID" = "ubuntu" ]; then
        info "Debian/Ubuntu 系统，通过 apt 安装 Python..."
        apt-get update -qq 2>/dev/null || true
        apt-get install -y python3 python3-venv python3-pip python3-full 2>/dev/null || \
            warn "apt 安装 Python 失败，请手动: apt install python3 python3-venv"

    else
        error "无法自动安装 Python 3.8+，请手动安装后重试。
CentOS/RHEL:
  yum install gcc openssl-devel zlib-devel libffi-devel make wget
  wget https://www.python.org/ftp/python/3.11.9/Python-3.11.9.tgz
  tar xf Python-3.11.9.tgz && cd Python-3.11.9
  ./configure --prefix=/usr/local --with-ensurepip=install
  make -j\$(nproc) && make altinstall
Debian/Ubuntu:
  apt install python3.11 python3.11-venv"
    fi
}


# ══════════════════════════════════════════
# 磁盘空间检查
# ══════════════════════════════════════════
check_disk_space() {
    local target_dir=$1
    local required_mb=${2:-100}

    info "检查磁盘空间..."
    local available_kb
    available_kb=$(df -k "${target_dir}" 2>/dev/null | awk 'NR==2 {print $4}')
    local available_mb=$(( (available_kb + 0) / 1024 ))

    if [ -z "$available_kb" ] || [ "${available_mb:-0}" -lt "$required_mb" ]; then
        warn "磁盘空间不足: 可用 ${available_mb:-0}MB，需要 ${required_mb}MB"
        prompt "是否强制继续部署？(y/n)："
        read -r CONTINUE
        [ "$CONTINUE" != "y" ] && [ "$CONTINUE" != "Y" ] && error "磁盘空间不足，部署已取消"
    else
        success "磁盘空间充足: 可用 ${available_mb}MB"
    fi
}


# ══════════════════════════════════════════
# 安装系统依赖
# ══════════════════════════════════════════
install_system_deps() {
    local deploy_type=$1
    info "安装系统依赖..."

    if command -v yum &>/dev/null; then
        PKG_MGR="yum"
    elif command -v apt-get &>/dev/null; then
        PKG_MGR="apt-get"
    elif command -v dnf &>/dev/null; then
        PKG_MGR="dnf"
    else
        warn "未检测到包管理器，请手动安装 smartmontools lm_sensors"
        return 0
    fi

    if [ "$deploy_type" = "agent" ]; then
        info "安装 Agent 端系统依赖（smartmontools、lm-sensors）..."
        if [ "$PKG_MGR" = "yum" ] || [ "$PKG_MGR" = "dnf" ]; then
            $PKG_MGR install -y smartmontools lm_sensors 2>/dev/null || \
                warn "部分依赖安装失败（smartmontools/lm_sensors）"
        elif [ "$PKG_MGR" = "apt-get" ]; then
            apt-get update -qq 2>/dev/null || true
            apt-get install -y smartmontools lm-sensors 2>/dev/null || \
                warn "部分依赖安装失败（smartmontools/lm-sensors）"
        fi
    fi

    success "系统依赖处理完成"
}


# ══════════════════════════════════════════
# 安装Python依赖（自动检测是否需要venv）
# ══════════════════════════════════════════
install_python_deps() {
    local target_dir=$1
    info "安装 Python 依赖包..."

    local REQ_FILE="${target_dir}/requirements.txt"
    [ -f "$REQ_FILE" ] || REQ_FILE="${SCRIPT_DIR}/requirements.txt"
    [ -f "$REQ_FILE" ] || { warn "未找到 requirements.txt，跳过依赖安装"; return; }

    if [ "${USE_VENV:-false}" = "true" ]; then
        # ── PEP 668 模式：创建 venv ──
        local VENV_DIR="${target_dir}/.venv"
        info "创建虚拟环境: ${VENV_DIR}"
        "$PYTHON_BIN" -m venv "${VENV_DIR}" || error "虚拟环境创建失败"
        # 使用 venv 内的 pip 升级并安装
        "${VENV_DIR}/bin/pip" install --upgrade pip -q 2>/dev/null || true
        "${VENV_DIR}/bin/pip" install -r "$REQ_FILE" || \
            error "Python 依赖安装失败（venv 模式），请检查 requirements.txt 和网络连接"
        # 设置全局 VENV_PYTHON，供后续步骤使用
        VENV_PYTHON="${VENV_DIR}/bin/python"
        success "Python 依赖已安装到虚拟环境 ${VENV_DIR}"
    else
        # ── 传统模式：系统级 pip install ──
        "$PYTHON_BIN" -m pip install -r "$REQ_FILE" || \
            error "Python 依赖安装失败，请检查 requirements.txt"
        VENV_PYTHON="${PYTHON_BIN}"
        success "Python 依赖安装完成"
    fi
}


# ══════════════════════════════════════════
# 服务端部署
# ══════════════════════════════════════════
deploy_server() {
    echo ""
    echo -e "${CYAN}═══ 服务端部署配置 ═══${NC}"

    # 询问端口
    prompt "请输入 Web 服务监听端口 [默认 8080]："
    read -r PORT
    PORT=${PORT:-8080}

    if ! [[ "$PORT" =~ ^[0-9]+$ ]] || [ "$PORT" -lt 1 ] || [ "$PORT" -gt 65535 ]; then
        error "无效端口号: ${PORT}，请输入 1-65535 之间的整数"
    fi

    # 询问部署目录
    prompt "请输入部署目录 [默认 ${INSTALL_DIR}]："
    read -r DEPLOY_DIR
    DEPLOY_DIR=${DEPLOY_DIR:-$INSTALL_DIR}

    # 路径安全检查
    [[ "$DEPLOY_DIR" =~ \.\. ]] || [[ "$DEPLOY_DIR" =~ \$ ]] && error "无效的部署目录路径: ${DEPLOY_DIR}"

    # SMTP 配置（可选）
    echo ""
    prompt "是否配置邮件告警？(y/n) [默认 n]："
    read -r CONF_SMTP
    SMTP_HOST="" SMTP_PORT="465" SMTP_USER="" SMTP_PASS="" RECIPIENTS=""
    if [ "$CONF_SMTP" = "y" ] || [ "$CONF_SMTP" = "Y" ]; then
        prompt "SMTP 服务器地址（如 smtp.qq.com）："
        read -r SMTP_HOST
        prompt "SMTP 端口 [默认 465]："
        read -r SMTP_PORT
        SMTP_PORT=${SMTP_PORT:-465}
        prompt "SMTP 用户名（发件人邮箱）："
        read -r SMTP_USER
        prompt "SMTP 密码/授权码："
        read -rs SMTP_PASS
        echo ""
        prompt "告警收件人（多个用逗号分隔）："
        read -r RECIPIENTS
    fi

    # 创建目录结构
    info "创建部署目录: ${DEPLOY_DIR}"
    mkdir -p "${DEPLOY_DIR}"/{server,data,logs}

    check_disk_space "${DEPLOY_DIR}" 100

    # 拷贝文件
    info "拷贝服务端文件..."
    cp -r "${SCRIPT_DIR}/server/"* "${DEPLOY_DIR}/server/"
    chmod +x "${DEPLOY_DIR}/server/service.sh" 2>/dev/null || true
    [ -f "${SCRIPT_DIR}/requirements.txt" ] && cp "${SCRIPT_DIR}/requirements.txt" "${DEPLOY_DIR}/"
    mkdir -p "${LOG_DIR}" "${PID_DIR}"

    # 安装 Python 依赖（设置 VENV_PYTHON）
    VENV_PYTHON="${PYTHON_BIN}"
    install_python_deps "${DEPLOY_DIR}"

    # 生成环境配置文件
    SECRET_KEY_GEN=""
    SECRET_KEY_GEN=$("${VENV_PYTHON}" -c "import secrets; print(secrets.token_hex(32))" 2>/dev/null) || \
    SECRET_KEY_GEN=$(openssl rand -hex 32 2>/dev/null) || \
        error "无法生成 SECRET_KEY，请确保 Python3 或 OpenSSL 可用"

    cat > "${DEPLOY_DIR}/server_config.env" << EOF
# 运维监控系统 - 服务端配置（自动生成）
# 生成时间：$(date)
WEB_PORT=${PORT}
WEB_HOST=0.0.0.0
DEPLOY_DIR=${DEPLOY_DIR}
SECRET_KEY=${SECRET_KEY_GEN}
EOF
    chmod 600 "${DEPLOY_DIR}/server_config.env" 2>/dev/null || true
    chmod 750 "${DEPLOY_DIR}/data" 2>/dev/null || true

    # 写入 SMTP 配置（通过环境变量 + json.dumps 安全序列化，杜绝代码注入）
    if [ -n "$SMTP_HOST" ]; then
        # 校验 SMTP_PORT 为纯数字
        if ! echo "$SMTP_PORT" | grep -qE '^[0-9]+$'; then
            SMTP_PORT=465
        fi
        # 校验 SMTP_HOST/USER/PASS 不含危险字符（仅允许字母数字常见符号）
        for _var in SMTP_HOST SMTP_USER SMTP_PASS RECIPIENTS; do
            eval "_val=\${$_var}"
            if echo "$_val" | grep -qF "'''"; then
                warn "配置项 $_var 包含非法字符，已跳过 SMTP 配置"
                continue 2
            fi
        done
        # 使用环境变量传递配置，由 Python 脚本通过 json.dumps 安全序列化
        SMTP_HOST="$SMTP_HOST" SMTP_PORT="$SMTP_PORT" SMTP_USER="$SMTP_USER" \
        SMTP_PASS="$SMTP_PASS" RECIPIENTS="$RECIPIENTS" DEPLOY_DIR="$DEPLOY_DIR" \
        "${VENV_PYTHON}" -c '
import json, os, sys

config = {
    "smtp_host": json.dumps(os.environ.get("SMTP_HOST", "")),
    "smtp_port": int(os.environ.get("SMTP_PORT", "465")),
    "smtp_user": json.dumps(os.environ.get("SMTP_USER", "")),
    "smtp_pass": json.dumps(os.environ.get("SMTP_PASS", "")),
    "smtp_ssl": "true",
    "alert_recipients": [x.strip() for x in os.environ.get("RECIPIENTS", "").split(",") if x.strip()]
}
# json.dumps 返回带引号的字符串，去掉外层引号
for k in ("smtp_host", "smtp_user", "smtp_pass"):
    config[k] = json.loads(config[k])

config_path = os.path.join(os.environ.get("DEPLOY_DIR", ""), "init_config.json")
with open(config_path, "w") as f:
    json.dump(config, f, ensure_ascii=False)
print("配置JSON已写入")
' 2>/dev/null || warn "SMTP JSON 配置写入失败，请在 Web 界面手动配置"

        # 生成初始化脚本
        cat > "${DEPLOY_DIR}/init_config.py" << 'PYEOF'
#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""服务端初始 SMTP 配置写入脚本（从JSON读取，加密存储密码）"""
import sys, os, json

sys.path.insert(0, os.path.join(os.path.dirname(__file__), 'server'))
from app import create_app
from database import db, SystemConfig
from crypto_utils import encrypt_value

config_path = os.path.join(os.path.dirname(__file__), 'init_config.json')
if not os.path.exists(config_path):
    print('配置文件不存在，跳过 SMTP 配置')
    sys.exit(0)

with open(config_path) as f:
    config = json.load(f)

app = create_app()
with app.app_context():
    fields = [
        ('smtp_host', 'SMTP服务器地址'),
        ('smtp_port', 'SMTP端口'),
        ('smtp_user', 'SMTP用户名'),
        ('smtp_pass', 'SMTP密码'),
        ('smtp_ssl',  'SMTP SSL'),
        ('alert_recipients', '告警收件人(JSON数组)'),
    ]
    for json_key, desc in fields:
        val = config.get(json_key)
        if val is None:
            continue
        # 加密 smtp_pass
        if json_key == 'smtp_pass' and val:
            val = encrypt_value(str(val), app.secret_key)
        if isinstance(val, list):
            val = json.dumps(val)
        else:
            val = str(val)
        cfg = SystemConfig.query.filter_by(key=json_key).first()
        if cfg:
            cfg.value = val
        else:
            db.session.add(SystemConfig(key=json_key, value=val, description=desc))
    db.session.commit()
    print('SMTP 配置已写入数据库（密码已加密）')

try:
    os.remove(config_path)
except Exception:
    pass
PYEOF

        "${VENV_PYTHON}" "${DEPLOY_DIR}/init_config.py" && \
            success "SMTP 配置写入成功" || warn "SMTP 配置写入失败，请在 Web 界面手动配置"
    fi

    # ── 调整目录权限（服务以 root 运行，简化权限） ──
    # 注意：systemd 服务使用 root，无需创建单独用户
    chmod 750 "${DEPLOY_DIR}" 2>/dev/null || true
    chmod 700 "${DEPLOY_DIR}/data" 2>/dev/null || true
    if [ -d "${DEPLOY_DIR}/.venv" ]; then
        chmod -R u+rX "${DEPLOY_DIR}/.venv" 2>/dev/null || true
    fi
    mkdir -p "${LOG_DIR}"
    chmod 755 "${LOG_DIR}" 2>/dev/null || true

    # ── 生成 systemd 服务文件 ──
    info "生成 systemd 服务文件..."
    # VENV_PYTHON 已由 install_python_deps 设置，解析为绝对路径
    WEB_PYTHON_ABS="${VENV_PYTHON}"
    if [[ "$WEB_PYTHON_ABS" != /* ]]; then
        WEB_PYTHON_ABS="$(command -v "${VENV_PYTHON}" 2>/dev/null || echo "/usr/bin/${VENV_PYTHON}")"
    fi
    cat > "/etc/systemd/system/ops-monitor-web.service" << EOF
[Unit]
Description=运维监控系统 - Web服务
After=network.target
Wants=network.target

[Service]
Type=simple
User=root
Group=root
WorkingDirectory=${DEPLOY_DIR}
Environment="PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
ExecStart=${WEB_PYTHON_ABS} ${DEPLOY_DIR}/server/main.py --port ${PORT} --host 0.0.0.0
Restart=on-failure
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

    # 启用并启动
    systemctl daemon-reload
    systemctl enable ops-monitor-web
    systemctl restart ops-monitor-web && \
        success "Web 服务已启动" || error "服务启动失败，请查看日志: journalctl -u ops-monitor-web -n 50"

    # 防火墙放行
    if command -v firewall-cmd &>/dev/null; then
        firewall-cmd --permanent --add-port=${PORT}/tcp 2>/dev/null && \
        firewall-cmd --reload 2>/dev/null && \
            info "防火墙(firewalld)已放行端口 ${PORT}" || warn "防火墙配置失败，请手动放行端口 ${PORT}"
    elif command -v ufw &>/dev/null; then
        ufw allow ${PORT}/tcp 2>/dev/null && \
            info "防火墙(ufw)已放行端口 ${PORT}" || warn "防火墙(ufw)配置失败，请手动放行端口 ${PORT}"
    fi

    # 获取初始管理员密码
    ADMIN_PASS_FILE="${DEPLOY_DIR}/data/default_admin_password.txt"
    if [ -f "$ADMIN_PASS_FILE" ]; then
        ADMIN_PASS=$(cat "$ADMIN_PASS_FILE" | cut -d: -f2 | tr -d '\n')
    else
        # 等待服务初始化生成密码文件
        sleep 3
        [ -f "$ADMIN_PASS_FILE" ] && ADMIN_PASS=$(cat "$ADMIN_PASS_FILE" | cut -d: -f2 | tr -d '\n')
    fi
    [ -z "$ADMIN_PASS" ] && ADMIN_PASS="（请查看 ${ADMIN_PASS_FILE}）"

    echo ""
    success "服务端部署完成！"
    echo -e "${GREEN}  ┌──────────────────────────────────────────────┐${NC}"
    echo -e "${GREEN}  │  Web访问地址: http://$(hostname -I | awk '{print $1}'):${PORT}  │${NC}"
    echo -e "${GREEN}  │  默认账号:   admin                           │${NC}"
    echo -e "${GREEN}  │  默认密码:   ${ADMIN_PASS}  │${NC}"
    echo -e "${GREEN}  │  服务日志:   ${LOG_DIR}/web.log  │${NC}"
    echo -e "${GREEN}  │  请登录后立即修改默认密码！                   │${NC}"
    echo -e "${GREEN}  └──────────────────────────────────────────────┘${NC}"
}


# ══════════════════════════════════════════
# Agent端部署
# ══════════════════════════════════════════
deploy_agent() {
    echo ""
    echo -e "${CYAN}═══ Agent端部署配置 ═══${NC}"

    prompt "请输入服务端地址（IP或域名，如 192.168.1.100）："
    read -r SERVER_IP
    [ -z "$SERVER_IP" ] && error "服务端地址不能为空"

    prompt "请输入服务端监听端口 [默认 8080]："
    read -r SERVER_PORT
    SERVER_PORT=${SERVER_PORT:-8080}

    # 智能默认节点名称：若主机名为默认值(localhost*)，则使用操作系统名称
    _hostname_val=$(hostname 2>/dev/null | tr '[:upper:]' '[:lower:]')
    case "$_hostname_val" in
        localhost|localhost.localdomain)
            DEFAULT_NODE_NAME="${OS_ID:-linux}"
            ;;
        *)
            DEFAULT_NODE_NAME="$(hostname)"
            ;;
    esac

    prompt "请输入本节点名称 [默认 ${DEFAULT_NODE_NAME}]："
    read -r NODE_NAME
    NODE_NAME=${NODE_NAME:-$DEFAULT_NODE_NAME}

    # 生成唯一节点 ID（节点名称 + 短 MAC 后缀）
    MAC=$(ip link show 2>/dev/null | grep 'link/ether' | head -1 | awk '{print $2}' | tr -d ':' | head -c 8)
    [ -z "$MAC" ] && MAC=$(date +%s | tail -c 8)
    NODE_ID="${NODE_NAME}-${MAC}"
    NODE_ID=$(echo "$NODE_ID" | tr ' ' '-' | tr '[:upper:]' '[:lower:]' | tr -cd 'a-z0-9-')

    prompt "请输入 Agent 部署目录 [默认 /opt/ops-agent]："
    read -r AGENT_DIR
    AGENT_DIR=${AGENT_DIR:-/opt/ops-agent}

    SERVER_URL="http://${SERVER_IP}:${SERVER_PORT}"

    info "创建 Agent 目录: ${AGENT_DIR}"
    mkdir -p "${AGENT_DIR}" "${AGENT_DIR}/.cache"

    # 拷贝 Agent 文件
    info "拷贝 Agent 文件..."
    cp "${SCRIPT_DIR}/agent/agent.py" "${AGENT_DIR}/"
    cp "${SCRIPT_DIR}/agent/service.sh" "${AGENT_DIR}/" 2>/dev/null && \
        chmod +x "${AGENT_DIR}/service.sh" && \
        info "Agent 服务管理脚本已安装: ${AGENT_DIR}/service.sh" || true
    cp "${SCRIPT_DIR}/agent/re-report.sh" "${AGENT_DIR}/" 2>/dev/null && \
        chmod +x "${AGENT_DIR}/re-report.sh" && \
        info "重新上报脚本已安装: ${AGENT_DIR}/re-report.sh" || true

    # 生成配置文件
    cat > "${AGENT_DIR}/agent.conf" << EOF
# 运维监控系统 Agent 配置文件
# 生成时间：$(date)

# 服务端地址（不含末尾斜杠）
SERVER_URL=${SERVER_URL}

# 节点唯一标识（部署后请勿修改）
NODE_ID=${NODE_ID}

# 节点显示名称
NODE_NAME=${NODE_NAME}
EOF
    chmod 600 "${AGENT_DIR}/agent.conf" 2>/dev/null || true

    # Agent 使用标准库，无需额外 Python 依赖
    success "Agent 无需额外 Python 依赖（全部使用标准库）"

    # 安装系统工具依赖
    install_system_deps "agent"

    # 测试连接服务端
    info "测试连接服务端 ${SERVER_URL}..."
    if command -v curl &>/dev/null; then
        if curl -sf --connect-timeout 5 "${SERVER_URL}/login" &>/dev/null; then
            success "服务端连接正常"
        else
            warn "无法连接服务端 ${SERVER_URL}，请确认服务端已启动且端口已开放"
        fi
    fi

    # 确定 Python 路径（使用 check_env 中检测到的 PYTHON_BIN，必须解析为绝对路径）
    # cron 环境的 PATH 非常有限（/usr/bin:/bin），编译安装到 /usr/local/bin 的 Python 无法被找到
    AGENT_PYTHON="${PYTHON_BIN:-$(command -v python3 || command -v python)}"
    AGENT_PYTHON_ABS="$(command -v "${AGENT_PYTHON}" 2>/dev/null || which "${AGENT_PYTHON}" 2>/dev/null || echo "${AGENT_PYTHON}")"
    if [[ "$AGENT_PYTHON_ABS" != /* ]]; then
        warn "无法解析 ${AGENT_PYTHON} 的绝对路径，尝试常见路径..."
        for _try_path in "/usr/local/bin/${AGENT_PYTHON}" "/usr/bin/${AGENT_PYTHON}"; do
            if [ -x "$_try_path" ]; then
                AGENT_PYTHON_ABS="$_try_path"
                break
            fi
        done
    fi
    info "Agent Python 路径: ${AGENT_PYTHON_ABS}"

    # 配置定时任务（兼容标准Linux + 群晖 /etc/crontab，使用绝对路径）
    CRON_LOG="${AGENT_DIR}/cron.log"
    # 日志截断行：cron.log 超过 20MB 时保留末尾 5MB
    LOG_TRUNCATE_CMD="0 4 * * * [ -f ${CRON_LOG} ] && tail -c 5242880 ${CRON_LOG} > ${CRON_LOG}.tmp && mv ${CRON_LOG}.tmp ${CRON_LOG}"
    setup_cron "${CRON_LOG}" \
        "0 */3 * * * flock -n /tmp/ops-monitor.lock ${AGENT_PYTHON_ABS} ${AGENT_DIR}/agent.py --mode full >> ${CRON_LOG} 2>&1 || true" \
        "*/5 * * * * flock -n /tmp/ops-monitor.lock ${AGENT_PYTHON_ABS} ${AGENT_DIR}/agent.py --mode heartbeat >> ${CRON_LOG} 2>&1 || true" \
        "*/15 * * * * flock -n /tmp/ops-monitor.lock ${AGENT_PYTHON_ABS} ${AGENT_DIR}/agent.py --mode alert >> ${CRON_LOG} 2>&1 || true" \
        "${LOG_TRUNCATE_CMD}"

    # ── 开机自启配置 ──
    _setup_agent_autostart "${AGENT_DIR}" "${AGENT_PYTHON}"

    # 立即执行首次完整上报
    info "执行首次完整数据上报（首次将自动注册节点并获取 token）..."
    "${AGENT_PYTHON}" "${AGENT_DIR}/agent.py" --mode full --config "${AGENT_DIR}/agent.conf" && \
        success "首次上报成功！节点已在服务端自动注册。" || \
        warn "首次上报失败，请检查服务端连接后手动执行: ${AGENT_PYTHON} ${AGENT_DIR}/agent.py --mode full"

    echo ""
    success "Agent 部署完成！"
    echo -e "${GREEN}  ┌────────────────────────────────────────────────────┐${NC}"
    echo -e "${GREEN}  │  节点ID:    ${NODE_ID}${NC}"
    echo -e "${GREEN}  │  节点名称:  ${NODE_NAME}${NC}"
    echo -e "${GREEN}  │  服务端:    ${SERVER_URL}${NC}"
    echo -e "${GREEN}  │  配置文件:  ${AGENT_DIR}/agent.conf${NC}"
    echo -e "${GREEN}  │  日志文件:  ${CRON_LOG}${NC}"
    echo -e "${GREEN}  │  查看任务: cat /etc/crontab | grep ops-monitor（群晖）或 crontab -l | grep ops-monitor${NC}"
    echo -e "${GREEN}  └────────────────────────────────────────────────────┘${NC}"
}


# ══════════════════════════════════════════
# 服务管理
# ══════════════════════════════════════════
service_status() {
    echo ""
    echo -e "${CYAN}═══ 服务状态 ═══${NC}"
    for svc in ops-monitor-web; do
        if systemctl is-active --quiet "$svc" 2>/dev/null; then
            echo -e "  ${GREEN}●${NC} ${svc} - 运行中"
        elif systemctl list-unit-files 2>/dev/null | grep -q "${svc}.service"; then
            echo -e "  ${RED}●${NC} ${svc} - 已停止"
        else
            echo -e "  ${YELLOW}○${NC} ${svc} - 未安装"
        fi
    done
    echo ""
    # 兼容标准 crontab 和群晖 /etc/crontab
    if command -v crontab &>/dev/null && crontab -l 2>/dev/null | grep -q 'ops-monitor'; then
        echo -e "  ${GREEN}●${NC} Agent 定时任务 - 已配置（crontab）"
        crontab -l 2>/dev/null | grep 'ops-monitor'
    elif [ -f /etc/crontab ] && grep -q 'ops-monitor' /etc/crontab; then
        echo -e "  ${GREEN}●${NC} Agent 定时任务 - 已配置（/etc/crontab）"
        grep 'ops-monitor' /etc/crontab
    else
        echo -e "  ${YELLOW}○${NC} Agent 定时任务 - 未配置"
    fi
}

service_start() {
    local svc=${1:-"all"}
    info "启动服务..."
    [ "$svc" = "all" ] || [ "$svc" = "web" ] && \
        systemctl start ops-monitor-web 2>/dev/null && success "Web 服务已启动" || warn "Web 服务启动失败"
}

service_stop() {
    local svc=${1:-"all"}
    info "停止服务..."
    [ "$svc" = "all" ] || [ "$svc" = "web" ] && \
        systemctl stop ops-monitor-web 2>/dev/null && success "Web 服务已停止" || warn "Web 服务停止失败"
}

service_restart() {
    service_stop "${1:-all}"
    sleep 1
    service_start "${1:-all}"
}


# ══════════════════════════════════════════
# 主入口
# ══════════════════════════════════════════
banner

# 自动修复已部署 service 文件中的 systemd 语法错误（append: 和 journal: 冒号后缀）
_fix_systemd_spec() {
    local svc_file
    for svc_file in /etc/systemd/system/ops-monitor-agent.service /etc/systemd/system/ops-monitor-web.service; do
        [ -f "$svc_file" ] || continue
        local changed=0
        if grep -qE '^StandardOutput=append:' "$svc_file"; then
            sed -i 's|^StandardOutput=append:.*|StandardOutput=journal|' "$svc_file"
            changed=1
        fi
        if grep -qE '^StandardError=append:' "$svc_file"; then
            sed -i 's|^StandardError=append:.*|StandardError=journal|' "$svc_file"
            changed=1
        fi
        if grep -qE '^StandardOutput=journal:' "$svc_file"; then
            sed -i 's|^StandardOutput=journal:.*|StandardOutput=journal|' "$svc_file"
            changed=1
        fi
        if grep -qE '^StandardError=journal:' "$svc_file"; then
            sed -i 's|^StandardError=journal:.*|StandardError=journal|' "$svc_file"
            changed=1
        fi
        if [ "$changed" -eq 1 ]; then
            info "已修复 $svc_file 中的 systemd 输出 specifier"
            systemctl daemon-reload 2>/dev/null || true
        fi
    done
}
_fix_systemd_spec

COMMAND=${1:-"install"}

case "$COMMAND" in
    install)
        check_env
        echo ""
        echo -e "${CYAN}请选择部署类型：${NC}"
        echo "  1) 服务端（主节点）"
        echo "  2) Agent端（子节点）"
        prompt "请输入选择 [1/2]："
        read -r DEPLOY_TYPE_CHOICE
        case "$DEPLOY_TYPE_CHOICE" in
            1|server) deploy_server ;;
            2|agent)  deploy_agent ;;
            *)        error "无效选择，请输入 1 或 2" ;;
        esac
        ;;
    start)   service_start "${2:-all}" ;;
    stop)    service_stop  "${2:-all}" ;;
    restart) service_restart "${2:-all}" ;;
    status)  service_status ;;
    server)  check_env; deploy_server ;;
    agent)   check_env; deploy_agent ;;
    *)
        echo "用法: $0 [install|start|stop|restart|status|server|agent]"
        echo ""
        echo "  install      交互式安装（询问服务端/Agent端）"
        echo "  server       直接部署服务端"
        echo "  agent        直接部署Agent端"
        echo "  start [svc]  启动服务（web / all）"
        echo "  stop  [svc]  停止服务"
        echo "  restart      重启服务"
        echo "  status       查看服务状态"
        ;;
esac
