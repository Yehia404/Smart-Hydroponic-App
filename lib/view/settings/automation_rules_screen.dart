import 'package:flutter/material.dart';

class AutomationRulesScreen extends StatefulWidget {
  const AutomationRulesScreen({super.key});

  @override
  State<AutomationRulesScreen> createState() => _AutomationRulesScreenState();
}

class _AutomationRulesScreenState extends State<AutomationRulesScreen> {
  bool isLoading = false;
  bool isAutoMode = true;
  List<Map<String, dynamic>> rules = [
    {
      'id': 1,
      'sensor': 'Temperature',
      'condition': '>',
      'threshold': 30.0,
      'actuator': 'fans',
      'action': 'ON',
      'isEnabled': 1,
    },
  ];

  void addRule(
    String sensor,
    String condition,
    double threshold,
    String actuator,
    String action,
  ) {
    setState(() {
      rules.add({
        'id': rules.length + 1,
        'sensor': sensor,
        'condition': condition,
        'threshold': threshold,
        'actuator': actuator,
        'action': action,
        'isEnabled': 1,
      });
    });
  }

  void deleteRule(int id) {
    setState(() {
      rules.removeWhere((rule) => rule['id'] == id);
    });
  }

  void toggleRule(int id, bool enabled) {
    setState(() {
      final index = rules.indexWhere((rule) => rule['id'] == id);
      if (index != -1) {
        rules[index]['isEnabled'] = enabled ? 1 : 0;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Automation Rules')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddRuleDialog(context),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          if (!isAutoMode)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: Colors.orange.withOpacity(0.2),
              child: const Row(
                children: [
                  Icon(Icons.warning_amber, color: Colors.orange),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'System is in Manual Mode. Rules will not execute until switched to Auto.',
                      style: TextStyle(
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : rules.isEmpty
                ? const Center(child: Text('No automation rules defined'))
                : ListView.builder(
                    itemCount: rules.length,
                    itemBuilder: (context, index) {
                      final rule = rules[index];
                      return Dismissible(
                        key: Key(rule['id'].toString()),
                        background: Container(color: Colors.red),
                        onDismissed: (_) => deleteRule(rule['id']),
                        child: Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          child: ListTile(
                            title: Text(
                              'IF ${rule['sensor']} ${rule['condition']} ${rule['threshold']} THEN ${rule['actuator']} ${rule['action']}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              rule['isEnabled'] == 1 ? 'Active' : 'Disabled',
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Switch(
                                  value: rule['isEnabled'] == 1,
                                  onChanged: (val) =>
                                      toggleRule(rule['id'], val),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                  ),
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: const Text('Delete Rule'),
                                        content: const Text(
                                          'Are you sure you want to delete this automation rule?',
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context),
                                            child: const Text('Cancel'),
                                          ),
                                          ElevatedButton(
                                            onPressed: () {
                                              deleteRule(rule['id']);
                                              Navigator.pop(context);
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.red,
                                            ),
                                            child: const Text('Delete'),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showAddRuleDialog(BuildContext context) {
    String sensor = 'Temperature';
    String condition = '>';
    String actuator = 'fans';
    String action = 'ON';
    final TextEditingController thresholdController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Automation Rule'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: sensor,
                items: ['Temperature', 'Humidity', 'Water Level', 'Light']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (val) => sensor = val!,
                decoration: const InputDecoration(labelText: 'Sensor'),
              ),
              DropdownButtonFormField<String>(
                initialValue: condition,
                items: ['>', '<']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (val) => condition = val!,
                decoration: const InputDecoration(labelText: 'Condition'),
              ),
              TextField(
                controller: thresholdController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Threshold Value'),
              ),
              DropdownButtonFormField<String>(
                initialValue: actuator,
                items: ['fans', 'pump', 'lights']
                    .map(
                      (e) => DropdownMenuItem(
                        value: e,
                        child: Text(e.toUpperCase()),
                      ),
                    )
                    .toList(),
                onChanged: (val) => actuator = val!,
                decoration: const InputDecoration(labelText: 'Actuator'),
              ),
              DropdownButtonFormField<String>(
                initialValue: action,
                items: ['ON', 'OFF']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (val) => action = val!,
                decoration: const InputDecoration(labelText: 'Action'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (thresholdController.text.isNotEmpty) {
                addRule(
                  sensor,
                  condition,
                  double.parse(thresholdController.text),
                  actuator,
                  action,
                );
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}
