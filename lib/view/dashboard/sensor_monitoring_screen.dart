import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/models/sensor_data.dart';
import '../../viewmodels/sensor_monitoring_viewmodel.dart';
import '../../data/models/sensor_calibration.dart';

class SensorMonitoringScreen extends StatelessWidget {
  const SensorMonitoringScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sensor Monitoring'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Data',
            onPressed: () {
              context.read<SensorMonitoringViewModel>().refreshSensorData();
            },
          ),
        ],
      ),
      body: const SensorMonitoringBody(),
    );
  }
}

// ✅ This is the reusable part
class SensorMonitoringBody extends StatelessWidget {
  const SensorMonitoringBody({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SensorMonitoringViewModel>(
      builder: (context, viewModel, child) {
        if (viewModel.isLoading && viewModel.sensors.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (viewModel.errorMessage != null && viewModel.sensors.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                const SizedBox(height: 16),
                Text(viewModel.errorMessage!),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: viewModel.refreshSensorData,
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        final sensors = viewModel.sensors;
        
        if (sensors.isEmpty) {
          return const Center(
            child: Text('No sensor data available'),
          );
        }

        return RefreshIndicator(
          onRefresh: viewModel.loadSensorData,
          child: ListView.builder(
            itemCount: sensors.length,
            itemBuilder: (context, index) {
              final sensor = sensors[index];
              final status = viewModel.getSensorStatus(sensor);
              final statusColor = viewModel.getStatusColor(status);
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: Icon(sensor.icon, color: sensor.color, size: 40),
                  title: Text(sensor.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Row(
                    children: [
                      Expanded(
                        child: Text.rich(
                          TextSpan(
                            children: [
                              const TextSpan(text: 'Status: '),
                              TextSpan(
                                text: status,
                                style: TextStyle(color: statusColor, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ),
                      ),
                      TextButton(
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        onPressed: () => _showCalibrationDialog(context, sensor.name),
                        child: const Text('Calibrate'),
                      ),
                    ],
                  ),
                  trailing: Text(
                    '${sensor.value} ${sensor.unit}',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  void _showCalibrationDialog(BuildContext context, String sensorName) {
    final calibration = SensorCalibration.instance;
    final viewModel = context.read<SensorMonitoringViewModel>();
    
    // Map sensor names to calibration getters/setters
    double getCurrentOffset() {
      switch (sensorName) {
        case 'Temperature':
          return calibration.temperatureOffset;
        case 'Water pH':
          return calibration.phOffset;
        case 'Water Level':
          return calibration.waterLevelOffset;
        case 'Light Intensity':
          return calibration.lightIntensityOffset;
        case 'Nutrient TDS':
          return calibration.tdsOffset;
        case 'Humidity':
          return calibration.humidityOffset;
        default:
          return 0.0;
      }
    }

    void setOffset(double value) {
      switch (sensorName) {
        case 'Temperature':
          calibration.temperatureOffset = value;
          break;
        case 'Water pH':
          calibration.phOffset = value;
          break;
        case 'Water Level':
          calibration.waterLevelOffset = value;
          break;
        case 'Light Intensity':
          calibration.lightIntensityOffset = value;
          break;
        case 'Nutrient TDS':
          calibration.tdsOffset = value;
          break;
        case 'Humidity':
          calibration.humidityOffset = value;
          break;
      }
    }

    double currentOffset = getCurrentOffset();
    
    showDialog(
      context: context,
      builder: (context) => _CalibrationDialog(
        sensorName: sensorName,
        currentOffset: currentOffset,
        onOffsetChanged: setOffset,
        onCalibrate: () {
          viewModel.calibrateSensor(sensorName);
          Navigator.of(context).pop();
        },
      ),
    );
  }
}

class _CalibrationDialog extends StatefulWidget {
  final String sensorName;
  final double currentOffset;
  final Function(double) onOffsetChanged;
  final VoidCallback onCalibrate;

  const _CalibrationDialog({
    required this.sensorName,
    required this.currentOffset,
    required this.onOffsetChanged,
    required this.onCalibrate,
  });

  @override
  State<_CalibrationDialog> createState() => _CalibrationDialogState();
}

class _CalibrationDialogState extends State<_CalibrationDialog> {
  late double _offset;
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _offset = widget.currentOffset;
    _controller = TextEditingController(text: _offset.toStringAsFixed(1));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Get appropriate range for each sensor type
  double _getMinValue() {
    switch (widget.sensorName) {
      case 'Temperature':
        return -10.0;
      case 'Water pH':
        return -3.0;
      case 'Nutrient TDS':
        return -500.0;
      default:
        return -50.0;
    }
  }

  double _getMaxValue() {
    switch (widget.sensorName) {
      case 'Temperature':
        return 10.0;
      case 'Water pH':
        return 3.0;
      case 'Nutrient TDS':
        return 500.0;
      default:
        return 50.0;
    }
  }

  String _getUnit() {
    switch (widget.sensorName) {
      case 'Temperature':
        return '°C';
      case 'Water pH':
        return 'pH';
      case 'Nutrient TDS':
        return 'ppm';
      default:
        return '%';
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Calibrate ${widget.sensorName}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Adjust the calibration offset for ${widget.sensorName}.',
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 20),
          Text(
            'Current Offset: ${_offset.toStringAsFixed(1)} ${_getUnit()}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Slider(
            value: _offset,
            min: _getMinValue(),
            max: _getMaxValue(),
            divisions: (((_getMaxValue() - _getMinValue()) * 10).toInt()),
            label: '${_offset.toStringAsFixed(1)} ${_getUnit()}',
            onChanged: (value) {
              setState(() {
                _offset = value;
                _controller.text = value.toStringAsFixed(1);
              });
            },
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _controller,
            keyboardType: TextInputType.numberWithOptions(decimal: true, signed: true),
            decoration: InputDecoration(
              labelText: 'Offset Value',
              suffixText: _getUnit(),
              border: const OutlineInputBorder(),
            ),
            onChanged: (value) {
              final parsed = double.tryParse(value);
              if (parsed != null) {
                setState(() {
                  _offset = parsed.clamp(_getMinValue(), _getMaxValue());
                });
              }
            },
          ),
          const SizedBox(height: 10),
          const Text(
            'Positive values increase the reading, negative values decrease it.',
            style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.grey),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            // Reset to zero
            setState(() {
              _offset = 0.0;
              _controller.text = '0.0';
            });
          },
          child: const Text('Reset'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onOffsetChanged(_offset);
            widget.onCalibrate();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${widget.sensorName} calibrated with offset: ${_offset.toStringAsFixed(1)} ${_getUnit()}'),
                duration: const Duration(seconds: 2),
              ),
            );
          },
          child: const Text('Apply'),
        ),
      ],
    );
  }
}
