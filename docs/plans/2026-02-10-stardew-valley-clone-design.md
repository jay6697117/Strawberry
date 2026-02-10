# Strawberry - 星露谷物语克隆游戏设计文档

## 项目概述

**项目名称**：Strawberry（草莓）
**类型**：2D 像素风农场模拟 RPG
**引擎**：Godot 4.3+（GDScript）
**美术资源**：[Sprout Lands Asset Pack](https://cupnooble.itch.io/sprout-lands-asset-pack)（主素材），[Pixel Plains](https://snowhex.itch.io/pixel-plains)（补充素材）
**分辨率**：基础 320×180（16:9），放大至窗口分辨率
**瓦片尺寸**：16×16 像素

---

## 一、项目结构

```
Strawberry/
├── project.godot                # Godot 项目配置
├── assets/                      # 所有美术/音频资源
│   ├── sprites/                 # 角色、作物、物品精灵图
│   ├── tilesets/                # 地图瓦片素材
│   └── ui/                      # UI 界面素材
├── scenes/                      # 所有场景文件（.tscn）
│   ├── main/                    # 主场景、游戏入口
│   ├── player/                  # 玩家角色场景
│   ├── farm/                    # 农场地图场景
│   ├── town/                    # 小镇地图场景
│   ├── npcs/                    # NPC 场景
│   ├── ui/                      # UI 场景（背包、对话框、商店）
│   └── items/                   # 物品/作物场景
├── scripts/                     # GDScript 脚本
│   ├── autoload/                # 全局单例（GameTime, Inventory, GameData, EventBus）
│   ├── player/                  # 玩家相关脚本
│   ├── farming/                 # 种植系统脚本
│   ├── npc/                     # NPC 行为脚本
│   ├── ui/                      # UI 控制脚本
│   └── data/                    # 数据定义（作物、物品、对话）
└── data/                        # JSON 数据文件
    ├── crops.json               # 作物数据表
    ├── items.json               # 物品数据表
    ├── npcs.json                # NPC 数据表
    └── dialogues/               # 对话文本文件
```

---

## 二、核心架构

### 全局单例（Autoload）

通过 Godot 的 Autoload 机制注册四个全局单例，管理跨场景的游戏状态：

| 单例名 | 职责 |
|--------|------|
| `GameTime` | 时间流逝、日期、季节管理 |
| `Inventory` | 背包物品管理 |
| `GameData` | 游戏进度（金钱、好感度、农场状态、存档） |
| `EventBus` | 全局事件总线，系统间通信 |

### 系统间通信

使用 Godot 的 **信号（Signal）** 机制实现系统解耦：
- `GameTime` 发出 `day_started`、`season_changed` 信号
- 种植系统监听 `day_started` 来推进作物生长
- NPC 系统监听 `time_tick` 来更新位置
- UI 监听各种信号来更新显示

---

## 三、玩家系统

### 节点结构
```
Player (CharacterBody2D)
├── CollisionShape2D          # 碰撞体
├── AnimatedSprite2D          # 角色动画
├── ToolHitArea (Area2D)      # 工具作用范围
│   └── CollisionShape2D
├── InteractionArea (Area2D)  # 交互检测范围
│   └── CollisionShape2D
└── Camera2D                  # 跟随摄像机
```

### 玩家能力
- **移动**：8 方向移动（上下左右 + 4 对角线）
- **工具使用**：锄头（翻地）、水壶（浇水）、镰刀（收割）
- **物品使用**：种子（种植）、其他消耗品
- **交互**：与 NPC 对话、开箱子、进商店
- **快捷栏**：数字键 1-9 切换当前手持物品

### 工具作用机制
玩家面朝的方向前方 1 格（16px）为工具作用目标。按动作键时：
1. 检测 `ToolHitArea` 内的 TileMap 格子
2. 根据当前工具类型执行对应操作
3. 播放工具使用动画

---

## 四、农场种植系统

### TileMap 分层

使用 3 个 `TileMapLayer` 节点：

| 层级 | 名称 | 用途 |
|------|------|------|
| 0 | Ground | 草地、泥土、路径等基础地形 |
| 1 | Farmland | 耕地状态（干燥/湿润） |
| 2 | Crops | 作物各生长阶段 |

### 种植流程

```
锄头 → 草地变耕地 → 种子 → 种下作物 → 水壶 → 浇水
                                              ↓
每日结算：浇水的作物生长+1阶段，未浇水不生长，耕地重置为干燥
                                              ↓
                                  作物成熟 → 镰刀收割 → 物品进背包
```

### 作物数据

```json
{
  "parsnip": {
    "name": "防风草",
    "seasons": ["spring"],
    "growth_days": 4,
    "stages": 5,
    "sell_price": 35,
    "seed_price": 20,
    "seed_id": "parsnip_seed"
  },
  "potato": {
    "name": "土豆",
    "seasons": ["spring"],
    "growth_days": 6,
    "stages": 5,
    "sell_price": 80,
    "seed_price": 50,
    "seed_id": "potato_seed"
  },
  "tomato": {
    "name": "番茄",
    "seasons": ["summer"],
    "growth_days": 11,
    "stages": 6,
    "sell_price": 60,
    "seed_price": 50,
    "seed_id": "tomato_seed"
  },
  "pumpkin": {
    "name": "南瓜",
    "seasons": ["autumn"],
    "growth_days": 13,
    "stages": 6,
    "sell_price": 320,
    "seed_price": 100,
    "seed_id": "pumpkin_seed"
  }
}
```

### 耕地状态机

```
草地 --[锄头]--> 干燥耕地 --[种子]--> 已种植(干燥) --[水壶]--> 已种植(湿润)
                                                                    ↓
                                                            [日终结算]
                                                                    ↓
                                                        已种植(干燥) + 生长+1
```

---

## 五、时间与季节系统

### 时间规则
- 游戏内 1 天 ≈ 现实 12-15 分钟（可在设置中调节）
- 每 N 秒 = 游戏内 10 分钟（用 Timer 节点控制）
- 每天从 6:00 开始，2:00AM（26:00）强制结束
- 日程：早晨(6:00) → 白天 → 傍晚(18:00) → 夜晚(22:00)

### 日历
- 每季 28 天
- 四季循环：春(Spring) → 夏(Summer) → 秋(Autumn) → 冬(Winter)
- 年份从第 1 年开始递增

### 季节影响
| 季节 | 可种作物 | 地图颜色 | 特殊事件 |
|------|----------|----------|----------|
| 春 | 防风草、土豆、花椰菜 | 绿色草地、樱花 | 开局季节 |
| 夏 | 番茄、蓝莓、甜瓜 | 深绿色、明亮 | — |
| 秋 | 南瓜、茄子、蔓越莓 | 橙色、落叶 | — |
| 冬 | 无（不能种地） | 白雪覆盖 | 可钓鱼/采矿 |

### 日终处理流程

当玩家上床睡觉后，依次执行：
1. 日期 +1
2. 检查是否换季（第 28 天 → 下一季第 1 天）
3. 遍历所有耕地：
   - 浇过水的作物 → 生长阶段 +1
   - 没浇水的作物 → 不生长（不会死）
   - 所有耕地重置为"未浇水"状态
4. 如果换季 → 清除不属于新季节的作物
5. 更新 NPC 好感度衰减（每天 -1）
6. 自动保存游戏

### GameTime 接口

```gdscript
# 属性
var current_season: String   # "spring" / "summer" / "autumn" / "winter"
var current_day: int         # 1-28
var current_year: int        # 从 1 开始
var current_hour: int        # 6-26
var is_night: bool           # 18:00 后为 true

# 信号
signal day_started           # 新的一天开始时触发
signal season_changed(new_season: String)  # 换季时触发
signal time_tick(hour: int)  # 每游戏内 10 分钟触发
```

---

## 六、NPC 与对话系统

### NPC 节点结构
```
NPC (CharacterBody2D)
├── CollisionShape2D
├── AnimatedSprite2D
├── NavigationAgent2D         # 自动寻路
├── InteractionArea (Area2D)  # 可交互范围
│   └── CollisionShape2D
└── DialogueBubble (Sprite2D) # 头顶对话气泡（靠近时显示）
```

### MVP NPC 列表

| NPC | 角色 | 位置 | 功能 |
|-----|------|------|------|
| 皮埃尔 | 种子商人 | 商店 | 买卖种子和农具 |
| 罗宾 | 木匠 | 木匠铺 | 升级房屋/建筑（后期） |
| 老李 | 村长 | 村中心 | 教程引导、任务 |
| 小花 | 邻居 | 隔壁农场 | 友好NPC、送礼对象 |
| 神秘人 | ??? | 森林深处 | 解锁隐藏内容（后期） |

### NPC 日程表

每个 NPC 有按时间段定义的位置列表：

```json
{
  "merchant": {
    "name": "皮埃尔",
    "schedules": {
      "default": [
        {"time": 8,  "location": "shop",        "position": [200, 150]},
        {"time": 12, "location": "town_square",  "position": [400, 300]},
        {"time": 17, "location": "shop",        "position": [200, 150]},
        {"time": 22, "location": "home",        "position": [100, 100]}
      ],
      "rain": [
        {"time": 8,  "location": "home",        "position": [100, 100]}
      ]
    }
  }
}
```

NPC 在时间点到达时，使用 `NavigationAgent2D` 自动寻路到目标位置。

### 好感度系统

- 范围：0 - 1000
- 等级划分：

| 等级 | 好感度 | 解锁内容 |
|------|--------|----------|
| 陌生人 | 0-199 | 基础对话 |
| 认识 | 200-399 | 更多对话选项 |
| 朋友 | 400-599 | 特殊对话、小任务 |
| 好友 | 600-799 | 赠送配方/物品 |
| 挚友 | 800-1000 | 特殊剧情事件 |

- 送礼规则：每个 NPC 有喜欢/讨厌的物品列表
  - 最爱：+80 好感
  - 喜欢：+45 好感
  - 普通：+20 好感
  - 不喜欢：-20 好感
  - 讨厌：-40 好感
- 每天自然衰减 -1（鼓励持续互动）

### 对话系统

对话数据结构（JSON）：
```json
{
  "merchant_greeting": {
    "conditions": {
      "friendship_min": 0,
      "friendship_max": 199,
      "season": "spring"
    },
    "text": "你好啊新来的，需要买些种子吗？春天正是种防风草的好时候。",
    "choices": [
      {"text": "好的，我看看。", "action": "open_shop"},
      {"text": "不用了，谢谢。", "next": "merchant_farewell"}
    ]
  },
  "merchant_farewell": {
    "text": "好吧，有需要随时来找我。",
    "choices": []
  }
}
```

对话显示采用逐字打印效果（typewriter），按确认键可跳过直接显示全文。

---

## 七、商店与经济系统

### 背包系统

- **容量**：36 格（6×6 网格）
- **快捷栏**：底部 12 格（映射背包前 12 格）
- **堆叠**：同类物品可堆叠，最多 999
- **物品分类**：工具(tool)、种子(seed)、作物(crop)、矿石(ore)、杂项(misc)

### 物品数据

```json
{
  "parsnip_seed": {
    "id": "parsnip_seed",
    "name": "防风草种子",
    "type": "seed",
    "stackable": true,
    "max_stack": 999,
    "description": "春天种下，4天成熟",
    "sell_price": 10,
    "buy_price": 20,
    "crop_id": "parsnip"
  },
  "parsnip": {
    "id": "parsnip",
    "name": "防风草",
    "type": "crop",
    "stackable": true,
    "max_stack": 999,
    "description": "常见的春季根茎蔬菜",
    "sell_price": 35,
    "buy_price": null
  },
  "hoe": {
    "id": "hoe",
    "name": "锄头",
    "type": "tool",
    "stackable": false,
    "description": "用来翻地",
    "sell_price": null,
    "buy_price": null
  }
}
```

### 商店机制

- 与商人 NPC 对话 → 选择"买东西"→ 打开商店 UI
- 商店商品列表随季节变化（春天卖春季种子等）
- 买东西扣金币，物品进背包
- 卖东西从背包移除，加金币

### 出货箱

- 农场固定放置一个出货箱
- 玩家把作物/物品放进出货箱
- 日终睡觉时结算，弹出收入明细界面

### 经济循环

```
买种子(花钱) → 种植 → 浇水 → 等待成熟 → 收割 → 卖出/出货箱(赚钱)
      ↑                                                    ↓
      └──────────────── 金币循环 ←──────────────────────────┘
```

**初始金币**：500G
**春季种子价格参考**：防风草种 20G，土豆种 50G

---

## 八、UI 界面

| UI 组件 | 触发方式 | 功能 |
|---------|----------|------|
| HUD | 常驻显示 | 时间、日期、金币、体力条、当前工具/物品 |
| 快捷栏 | 常驻底部 | 12 格物品快速切换 |
| 背包界面 | 按 Tab/E 打开 | 查看/整理/丢弃物品 |
| 对话框 | 与 NPC 交互 | 显示对话文字和选项 |
| 商店界面 | NPC 触发 | 买卖物品列表、金币余额 |
| 日终结算 | 睡觉后 | 显示当日出货收入明细 |
| 暂停菜单 | 按 ESC | 继续、保存、设置、退出 |

---

## 九、实现优先级

### Phase 1：基础框架
- Godot 项目初始化、目录结构搭建
- 全局单例创建（GameTime, Inventory, GameData, EventBus）
- 玩家角色移动（8方向 + 碰撞）
- 基础农场地图（TileMap + 占位瓦片）
- 摄像机跟随

### Phase 2：种植核心循环
- 工具系统（锄头翻地、水壶浇水、镰刀收割）
- 作物种植与生长（数据驱动）
- 日终结算逻辑
- 时间/季节系统

### Phase 3：背包与经济
- 背包 UI + 快捷栏
- 物品拾取/使用/丢弃
- 出货箱机制
- 金币系统

### Phase 4：NPC 与社交
- NPC 场景 + 日程寻路
- 对话系统 UI
- 好感度系统
- 商店买卖

### Phase 5：打磨
- 替换正式美术素材
- 音效/BGM
- 存档/读档
- 菜单界面
- Bug 修复与平衡调整
