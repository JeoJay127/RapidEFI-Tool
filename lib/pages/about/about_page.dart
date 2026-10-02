import 'package:fluent_ui/fluent_ui.dart';
import 'package:rapidefi/pages/shared/widgets/link_button_row.dart';
import 'package:rapidefi/pages/shared/widgets/title_card.dart';
import 'package:rapidefi/utils/image_util.dart';

class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasFluentTheme(context));
    return ScaffoldPage.scrollable(
        header: const PageHeader(
          title: Text('赞助开发者'),
          commandBar: LinkButtonRow(
            mainAxisAlignment: MainAxisAlignment.end,
            items: [
              LinkButtonItem(
                url: 'https://www.bilibili.com/video/BV1Li421h7FZ',
                buttonText: '访问作者b站',
                icon: FluentIcons.my_movies_t_v,
              ),
              LinkButtonItem(
                url: 'https://github.com/JeoJay127/RapidEFI-Tool',
                buttonText: '访问作者github',
                icon: FluentIcons.open_source,
              ),
            ],
          ),
        ),
        children: const [
          TitleCard(
            title: '请开发者喝杯奶茶',
            initiallyExpanded: true,
            expander: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 15,
                ),
                Text(
                  'RapidEFI 是一个完全免费、离线、无广告的个人项目。为了让它跟上 OpenCore、Kext、macOS 版本和真实硬件环境的变化，'
                  '背后需要持续投入很多业余时间：整理官方文档、适配规则、测试功能、修复问题，也要不断消化用户反馈中的各种特殊机器案例。',
                ),
                SizedBox(
                  height: 15,
                ),
                Text(
                  '如果 RapidEFI 曾经帮你节省时间、少走弯路，或者让配置 EFI 这件事变得没那么令人头疼，欢迎用打赏的方式支持项目继续维护。'
                  '金额多少都不重要，你的认可本身就是继续做下去的动力。',
                ),
                SizedBox(
                  height: 15,
                ),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      LoadAssetsImage(
                        'donate_alipay',
                        format: ImageFormat.png,
                        width: 213 * 0.8,
                        height: 284 * 0.8,
                      ),
                      LoadAssetsImage(
                        'donate_wechat',
                        format: ImageFormat.png,
                        width: 213 * 0.8,
                        height: 284 * 0.8,
                      )
                    ],
                  ),
                ),
                SizedBox(
                  height: 15,
                ),
                Text(
                  '如果你更希望支持实际适配，也可以提供特殊硬件样本或完整硬件资料。比如家中闲置、已经用不上的老平台或特殊主板，'
                  '像 G31、G41、H55、FM1、FM2、AM3、X58、X79、X99，以及一些魔改 BIOS、魔改 CPU、非典型芯片组的主板，都可能对测试和规则完善很有价值。'
                  '相比单纯的文字描述，真实机器、完整 ACPI 表和硬件报告往往更能帮助定位问题，也能让 RapidEFI 对更多平台的支持变得更可靠。',
                ),
                SizedBox(
                  height: 15,
                ),
                Text(
                  '捐赠作者：QQ 766264141 / 微信 JeoJay127。除此之外没有其他私人联系方式，请谨防受骗。',
                ),
              ],
            ),
          ),
          SizedBox(
            height: 10,
          ),
          TitleCard(
            title: 'RapidEFI成功案例',
            content: LinkButtonRow(
              mainAxisAlignment: MainAxisAlignment.end,
              items: [
                LinkButtonItem(
                  url:
                      'https://github.com/JeoJay127/RapidEFI-Tool/blob/main/docs/成功案例.md',
                  buttonText: 'RapidEFI成功案例',
                  icon: FluentIcons.open_source,
                )
              ],
            ),
          )
        ]);
  }
}
