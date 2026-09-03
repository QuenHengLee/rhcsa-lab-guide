# RHCSA 實作練習與題解手冊 · RHCSA Hands-on Lab & Guide

一套為 **RHCSA (EX200, RHEL 10)** 準備的自我練習環境與雙語題解,涵蓋 33 個可自動評分的練習題,對照 Red Hat 官方考綱。適合在自己的 Rocky Linux / RHEL 10 虛擬機上反覆操作。

A self-contained practice environment and bilingual (English + 繁體中文) study guide for the **RHCSA (EX200, RHEL 10)** exam: 33 auto-graded exercises mapped to the official objectives, meant to be run over and over on your own Rocky Linux / RHEL 10 VM.

> ⚠️ 這是**非官方**的社群學習素材,與 Red Hat 無任何關係。練習環境用 Rocky Linux 10(與 RHEL 相容)。
> Unofficial community study material, not affiliated with Red Hat.

---

## 內容 · What's inside

| 目錄 | 內容 |
|------|------|
| `guide/rhcsa-guide.html` | **題解手冊**:33 題的標準解法,每題四步驟(啟動 → 逐步解法 → 評分驗證 → 收尾),含考場心法與 man 查法 |
| `guide/disk-partition.html` | **磁碟分割圖解**:五層流程、MBR/GPT、fstab、LVM 積木池、swap 的概念圖 |
| `labs/*.lab` | 33 個練習題定義(題目、環境佈置、自動評分、清理),中英雙語題目敘述 |
| `setup/` | 部署腳本、`lab` 主程式、共用函式庫、彩色提示字元設定 |

兩份 HTML 用瀏覽器直接打開即可閱讀(不需要任何伺服器)。
Open the two HTML files directly in any browser — no server needed.

---

## 練習環境長怎樣 · The lab environment

- 兩台虛擬機:**servera** 與 **serverb**(大部分題目在 servera,rsync / NFS / SSH 金鑰等雙機題需要 serverb 一起開)。
- 每台是 Rocky Linux 10 minimal,2 GB RAM / 2 CPU。
- 練習碟:兩顆空白磁碟(如 `/dev/vdb`、`/dev/vdc` 或 `/dev/nvme0n1`、`/dev/nvme0n2`)專供分割 / LVM / swap 練習;系統碟不要動。
- 帳號慣例:`student` / `student`(免密碼 sudo)、`root` / `student`。

你可以用任何方式建立這兩台 VM(VirtualBox、KVM、Vagrant…),只要是 RHEL 10 相容系統即可。

---

## 安裝 · Install the lab framework

在你的練習 VM 上(以 root)：

```bash
git clone https://github.com/QuenHengLee/rhcsa-lab-guide.git
cd rhcsa-lab-guide
sudo ./setup/install-labs.sh
```

腳本會把 `lab` 指令、函式庫與 33 個練習裝到系統。裝好後,以任何有 sudo 權限的使用者：

```bash
lab list                    # 列出全部 33 題
lab describe storage-lvm    # 只看題目(中英雙語),不動系統
lab start   storage-lvm     # 重置並佈置環境,顯示題目 → 開始作答
lab grade   storage-lvm     # 評分:告訴你哪些還沒達成(可重複執行)
lab finish  storage-lvm     # 清除該題建立的東西
```

**建議流程**:先 `lab describe` 或 `lab start` 讀題、自己動手做,卡住再翻 `guide/rhcsa-guide.html`;做到 `lab grade` 全 PASS 才算過關。

**循序規則 · Sequential rule**:上一題沒完成,不能開始下一題。某題 `lab start` 之後,必須 `lab grade` 全 PASS 或 `lab finish` 收掉,才能對別題 `lab start`;否則會被擋下。這逼你養成「做完、驗過、收乾淨」的紀律。緊急覆寫用 `LAB_FORCE=1 lab start <name>`(不建議)。
You can't start the next exercise until the current one is finished — pass its grade or `lab finish` it first. Override with `LAB_FORCE=1` if you really must.

---

## 彩色提示字元(選用) · Colourful prompt (optional)

讓兩台機器一眼可辨(避免在錯的機器上操作)：

```bash
sudo cp setup/prompt.sh /etc/profile.d/prompt.sh
# 編輯 setup/prompt.sh 裡的 _HOSTCOLOUR:servera 用 36(青)、serverb 用 33(黃)
# 重新登入後生效
```

root 顯示紅色使用者名 + `#`,一般使用者顯示綠色 + `$`。

---

## 題目涵蓋範圍 · Topics covered

essential-tools（find / grep+tar / links）· users-and-groups · permissions（ACL / setgid+sticky / umask）· storage（分割+UUID掛載 / LVM / LVM擴充 / Stratis / swap）· network-filesystems（rsync / NFS+autofs）· scheduling-and-services（at / cron / systemd timer / 服務控制 / tuned）· network-and-time（nmcli / chrony）· security（firewalld / SELinux boolean / SELinux 修復 / 非標準埠 httpd / SSH 金鑰）· containers（rootless podman）· shell-scripting · processes-and-logs（nice / journal 持久化）· boot-and-recovery（emergency mode 修復）

---

## 授權 · License

教材與 lab 定義以 [MIT License](LICENSE) 釋出,歡迎自由使用、修改、分享。
祝考試順利 — good luck on your exam! 🐧
