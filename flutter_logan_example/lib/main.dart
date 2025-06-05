import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_logan/flutter_logan.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String _showText = 'you should init log first';

  @override
  void initState() {
    super.initState();
  }

  Future<void> initLog() async {
    String result = 'Failed to init log';
    try {
      final bool back = await FlutterLogan.init(
        '0123456789012345',
        '0123456789012345',
        1024 * 1024 * 10,
      );
      if (back) {
        result = 'Init log succeed';
      }
    } on PlatformException {
      result = 'Failed to init log';
    }
    if (!mounted) return;
    setState(() {
      _showText = result;
    });
  }

  Future<void> log() async {
    String result = 'Write log succeed';
    try {
      await FlutterLogan.log(10, 'this is log string');
    } on PlatformException {
      result = 'Failed to write log';
    }
    if (!mounted) return;
    setState(() {
      _showText = result;
    });
  }

  Future<void> getUploadPath() async {
    String result;
    try {
      final today = DateTime.now();
      final date =
          "${today.year.toString()}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";
      String? path = await FlutterLogan.getUploadPath(date);
      result = 'upload path = $path';
    } on PlatformException {
      result = 'Failed to get upload path';
    }
    if (!mounted) return;
    setState(() {
      _showText = result;
    });
  }

  Future<void> flush() async {
    String result = 'Flush log succeed';
    try {
      await FlutterLogan.flush();
    } on PlatformException {
      result = 'Failed to flush log';
    }
    if (!mounted) return;
    setState(() {
      _showText = result;
    });
  }

  Future<void> cleanAllLog() async {
    String result = 'Clean log succeed';
    try {
      await FlutterLogan.cleanAllLogs();
    } on PlatformException {
      result = 'Failed to clean log';
    }
    if (!mounted) return;
    setState(() {
      _showText = result;
    });
  }

  Future<void> uploadToServer() async {
    String result = 'Failed upload to server';
    try {
      final today = DateTime.now();
      final date =
          "${today.year.toString()}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";
      final bool back = await FlutterLogan.upload(
        'http://127.0.0.1:3000/logupload',
        date,
        'FlutterTestAppId',
        'FlutterTestUnionId',
        'FlutterTestDeviceId',
      );
      if (back) {
        result = 'Upload to server succeed';
      }
    } on PlatformException {
      result = 'Failed upload to server';
    }
    if (!mounted) return;
    setState(() {
      _showText = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    // 构建包含日志操作按钮列表的界面
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // 状态显示区域
            Container(
              padding: const EdgeInsets.all(16.0),
              margin: const EdgeInsets.only(bottom: 20.0),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8.0),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Text(
                _showText,
                style: const TextStyle(fontSize: 16.0),
                textAlign: TextAlign.center,
              ),
            ),
            // 按钮列表
            Expanded(
              child: ListView(
                children: [
                  // 初始化日志按钮
                  _buildActionButton(
                    '初始化日志',
                    '初始化Logan日志系统',
                    Icons.settings,
                    initLog,
                  ),
                  const SizedBox(height: 12.0),

                  // 写入日志按钮
                  _buildActionButton('写入日志', '向日志系统写入一条测试日志', Icons.edit, log),
                  const SizedBox(height: 12.0),

                  // 获取上传路径按钮
                  _buildActionButton(
                    '获取上传路径',
                    '获取今日日志文件的上传路径',
                    Icons.folder,
                    getUploadPath,
                  ),
                  const SizedBox(height: 12.0),

                  // 刷新日志按钮
                  _buildActionButton(
                    '刷新日志',
                    '将缓存中的日志写入文件',
                    Icons.refresh,
                    flush,
                  ),
                  const SizedBox(height: 12.0),

                  // 清除所有日志按钮
                  _buildActionButton(
                    '清除所有日志',
                    '删除所有本地日志文件',
                    Icons.delete,
                    cleanAllLog,
                  ),
                  const SizedBox(height: 12.0),

                  // 上传到服务器按钮
                  _buildActionButton(
                    '上传到服务器',
                    '将今日日志上传到测试服务器',
                    Icons.cloud_upload,
                    uploadToServer,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 构建操作按钮的辅助方法
  Widget _buildActionButton(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onPressed,
  ) {
    return Card(
      elevation: 2.0,
      child: ListTile(
        leading: Icon(icon, size: 32.0, color: Theme.of(context).primaryColor),
        title: Text(
          title,
          style: const TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(fontSize: 14.0, color: Colors.grey[600]),
        ),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: onPressed,
      ),
    );
  }
}
