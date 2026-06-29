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
                    '如果有幸帮到了你，可以对开发者随意打赏！感谢支持！！！\n\n作者联系方式:QQ766264141或者WX:JeoJay127。除此之外没有其他私人联系方式,谨防受骗!'),
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
                )
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
                      'https://github.com/JeoJay127/RapidEFI-Tool/blob/main/成功案例.md',
                  buttonText: 'RapidEFI成功案例',
                  icon: FluentIcons.open_source,
                )
              ],
            ),
          )
        ]);
  }
}
