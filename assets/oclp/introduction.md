# OpenCore Legacy Patcher
![OpenCore Patcher Logo](images/OC-Patcher.png)

----------


## 什么是 OCLP？

OpenCore Legacy Patcher(以下简称OCLP,不再赘述) 是一个 Python 项目，围绕 [Acidanthera 的 OpenCorePkg](https://github.com/acidanthera/OpenCorePkg) 和 [Lilu](https://github.com/acidanthera/Lilu) 开发，旨在在受支持和不受支持的 Mac 上运行 macOS 并解锁其功能。它最初由 Dortania 创建并维护，旨在帮助苹果官方不再支持的 Mac 焕发新生，使2007年及更新的设备能够安装和使用macOS Big Sur及更新版本。

最初的用途（老款白苹果）

	•	由于 Apple 在 macOS 更新中逐步淘汰了老旧硬件支持，OCLP 诞生的初衷是为 官方不再支持的新 macOS 版本的旧款 Mac 提供补丁，使其能够继续运行最新的 macOS。
	•	主要提供 启动补丁 和 内核扩展（kexts） 以解决老 Mac 上 显卡驱动、Wi-Fi、USB 设备兼容性 等问题。

后来的发展（黑苹果）

	•	OCLP 的补丁系统不仅适用于老款Apple官方Mac，后来也被Hackintosh（黑苹果）用户用于非官方新系统支持的硬件，例如：
	•	旧款或 AMD 显卡的驱动补丁
	•	非官方支持的 Wi-Fi / 蓝牙适配
	•	USB 设备补丁

OCLP 结合 OpenCore 的强大功能，使老Mac和 Hackintosh设备(OCLP补丁操作与引导方式无关,Clover,OpenCore都支持)都能更稳定地运行新版本macOS，成为黑苹果社区的重要补丁工具之一。

----------

## OpenCore Legacy Patcher 官方修改版 

点击访问[OpenCore Legacy Patcher 修改版 by JeoJay](https://github.com/JeoJay127/OCLP-X/releases),下载OpenCore-Patcher.pkg

(可以关注该仓库，第一时间对官方最新版本进行patch更新！)

----------

## 官方原版OCLP的重要功能：


* 支持 macOS Big Sur、Monterey、Ventura、Sonoma 和 Sequoia
* 原生支持 OTA（在线）系统更新
* 兼容 Penryn 及更新的 Mac 机型
* 完全支持 WPA Wi-Fi 及个人热点，适用于 BCM943224 及更新的无线芯片组
* 支持系统完整性保护（SIP）、FileVault 2、.im4m 安全启动和 Vaulting
* 在非原生操作系统上支持恢复模式（Recovery OS）、安全模式（Safe Mode）和单用户模式（Single-user Mode）启动
* 解锁原生 Mac 设备上的 Sidecar 和 AirPlay to Mac 等功能
* 在非 Apple 存储设备上启用增强的 SATA 和 NVMe 电源管理
* 无需固件补丁（即 APFS ROM 补丁）
* 支持 Metal 和非 Metal GPU 的图形加速


----------


## 修改版OCLP新增功能：

* **增强对 macOS Sequoia 上 Intel 无线网卡的支持(修改版支持)** 
* **新增对 Atheros WiFi 网卡及部分旧款 Broadcom WiFi 网卡 ID 的支持(修改版支持)**
* **新增AppleHDA音频支持(AppleALC 所需)，支持macOS Tahoe 26 Beta 2 (26.0-25A5295e)及后续版本**

----------


## 从源码运行

要从源码运行本项目，请参考：[从源码构建和运行](https://github.com/JeoJay127/OCLP-X/blob/main/SOURCE.md)

## 鸣谢

* [Dortania](https://github.com/dortania)  
  * 项目原作者，创建并维护了 OpenCore Legacy Patcher 项目

* [Acidanthera](https://github.com/Acidanthera)  
  * 提供 OpenCorePkg 以及许多核心 kext 和工具

* [zxystd](https://github.com/zxystd)  
  * macOS Intel Wi-Fi 适配器内核扩展的开发者

* Apple  
  * 提供 macOS 及我们在新系统中重新实现的众多 kext、框架和其他二进制文件
