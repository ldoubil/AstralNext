import 'package:flutter/material.dart';
import 'package:astral_game/di.dart';
import 'package:astral_game/data/state/server_state.dart';
import 'package:astral_game/data/models/server_mod.dart';

import 'blocked_servers.dart';

Future<void> showAddServerDialog(BuildContext context) async {
  return showDialog(
    context: context,
    builder: (context) =>
        ServerDialog(title: '添加服务器', confirmText: '添加'),
  );
}

Future<void> showEditServerDialog(
  BuildContext context, {
  required ServerMod server,
}) async {
  return showDialog(
    context: context,
    builder: (context) =>
        ServerDialog(title: '编辑服务器', confirmText: '保存', server: server),
  );
}

class ServerDialog extends StatefulWidget {
  final String title;
  final String confirmText;
  final ServerMod? server;

  const ServerDialog({
    super.key,
    required this.title,
    required this.confirmText,
    this.server,
  });

  @override
  State<ServerDialog> createState() => _ServerDialogState();
}

class _ServerDialogState extends State<ServerDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _urlController = TextEditingController();

  bool _tcp = true;
  bool _faketcp = false;
  bool _udp = true;
  bool _ws = false;
  bool _wss = false;
  bool _quic = false;
  bool _wg = false;
  bool _txt = false;
  bool _srv = false;
  bool _http = false;
  bool _https = false;

  @override
  void initState() {
    super.initState();
    if (widget.server != null) {
      _nameController.text = widget.server!.name;
      _urlController.text = widget.server!.url;

      _tcp = widget.server!.tcp;
      _faketcp = widget.server!.faketcp;
      _udp = widget.server!.udp;
      _ws = widget.server!.ws;
      _wss = widget.server!.wss;
      _quic = widget.server!.quic;
      _wg = widget.server!.wg;
      _txt = widget.server!.txt;
      _srv = widget.server!.srv;
      _http = widget.server!.http;
      _https = widget.server!.https;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  void _saveServer() {
    if (_formKey.currentState!.validate()) {
      final server = ServerMod(
        id: widget.server?.id,
        enable: widget.server?.enable ?? false,
        name: _nameController.text,
        url: _urlController.text,
        tcp: _tcp,
        faketcp: _faketcp,
        udp: _udp,
        ws: _ws,
        wss: _wss,
        quic: _quic,
        wg: _wg,
        txt: _txt,
        srv: _srv,
        http: _http,
        https: _https,
      );

      if (widget.server == null) {
        getIt<ServerState>().addServer(server);
      } else {
        getIt<ServerState>().updateServer(server);
      }
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AlertDialog(
      title: Text(widget.title),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: '服务器名称',
                  hintText: '输入服务器名称',
                  border: const OutlineInputBorder(),
                  prefixIcon:
                      Icon(Icons.dns, color: colorScheme.primary),
                  floatingLabelBehavior: FloatingLabelBehavior.always,
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 12,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '请输入服务器名称';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _urlController,
                enabled: widget.server == null ||
                    !BlockedServers.isBlocked(widget.server!.url),
                decoration: InputDecoration(
                  labelText: '服务器地址',
                  hintText: '输入服务器地址',
                  border: const OutlineInputBorder(),
                  prefixIcon:
                      Icon(Icons.language, color: colorScheme.primary),
                  floatingLabelBehavior: FloatingLabelBehavior.always,
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 12,
                  ),
                  helperText: widget.server != null &&
                          BlockedServers.isBlocked(widget.server!.url)
                      ? '此服务器地址不可修改'
                      : null,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '请输入服务器地址';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              const Text(
                '支持的协议:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 16,
                runSpacing: 8,
                children: [
                  _buildProtocolSwitch(
                      'TCP', _tcp, (v) => setState(() => _tcp = v!)),
                  _buildProtocolSwitch('FAKETCP', _faketcp,
                      (v) => setState(() => _faketcp = v!)),
                  _buildProtocolSwitch(
                      'UDP', _udp, (v) => setState(() => _udp = v!)),
                  _buildProtocolSwitch(
                      'WS', _ws, (v) => setState(() => _ws = v!)),
                  _buildProtocolSwitch(
                      'WSS', _wss, (v) => setState(() => _wss = v!)),
                  _buildProtocolSwitch(
                      'QUIC', _quic, (v) => setState(() => _quic = v!)),
                  _buildProtocolSwitch(
                      'WG', _wg, (v) => setState(() => _wg = v!)),
                  _buildProtocolSwitch(
                      'TXT', _txt, (v) => setState(() => _txt = v!)),
                  _buildProtocolSwitch(
                      'SRV', _srv, (v) => setState(() => _srv = v!)),
                  _buildProtocolSwitch(
                      'HTTP', _http, (v) => setState(() => _http = v!)),
                  _buildProtocolSwitch(
                      'HTTPS', _https, (v) => setState(() => _https = v!)),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: _saveServer,
          style: ElevatedButton.styleFrom(
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
          ),
          child: Text(widget.confirmText),
        ),
      ],
    );
  }

  Widget _buildProtocolSwitch(
    String label,
    bool value,
    Function(bool?) onChanged,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [Switch(value: value, onChanged: onChanged), Text(label)],
    );
  }
}
