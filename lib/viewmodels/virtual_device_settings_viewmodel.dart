import 'package:flutter/material.dart';
import '../utils/virtual_device.dart';

class VirtualDeviceSettingsViewModel extends ChangeNotifier {
  final VirtualDevice _virtualDevice;
  // Temperature ranges (°C)
  double _tempMin = 22.0;
  double _tempMax = 27.0;

  // pH ranges
  double _phMin = 6.5;
  double _phMax = 7.5;

  // Water Level ranges (%)
  double _waterLevelMin = 80.0;
  double _waterLevelMax = 100.0;

  // Light Intensity ranges (%)
  double _lightMin = 60.0;
  double _lightMax = 100.0;

  // TDS ranges (ppm)
  double _tdsMin = 800.0;
  double _tdsMax = 1200.0;

  // Humidity ranges (%)
  double _humidityMin = 50.0;
  double _humidityMax = 70.0;

  // Getters
  double get tempMin => _tempMin;
  double get tempMax => _tempMax;
  double get phMin => _phMin;
  double get phMax => _phMax;
  double get waterLevelMin => _waterLevelMin;
  double get waterLevelMax => _waterLevelMax;
  double get lightMin => _lightMin;
  double get lightMax => _lightMax;
  double get tdsMin => _tdsMin;
  double get tdsMax => _tdsMax;
  double get humidityMin => _humidityMin;
  double get humidityMax => _humidityMax;

  // Constructor
  VirtualDeviceSettingsViewModel(this._virtualDevice);

  // Helper method to update virtual device
  void _updateVirtualDevice() {
    _virtualDevice.updateRanges(
      tempMin: _tempMin,
      tempMax: _tempMax,
      phMin: _phMin,
      phMax: _phMax,
      waterLevelMin: _waterLevelMin,
      waterLevelMax: _waterLevelMax,
      lightMin: _lightMin,
      lightMax: _lightMax,
      tdsMin: _tdsMin,
      tdsMax: _tdsMax,
      humidityMin: _humidityMin,
      humidityMax: _humidityMax,
    );
  }

  // Temperature setters
  void setTempMin(double value) {
    if (value < _tempMax) {
      _tempMin = value;
      _updateVirtualDevice();
      notifyListeners();
    }
  }

  void setTempMax(double value) {
    if (value > _tempMin) {
      _tempMax = value;
      _updateVirtualDevice();
      notifyListeners();
    }
  }

  // pH setters
  void setPhMin(double value) {
    if (value < _phMax) {
      _phMin = value;
      _updateVirtualDevice();
      notifyListeners();
    }
  }

  void setPhMax(double value) {
    if (value > _phMin) {
      _phMax = value;
      _updateVirtualDevice();
      notifyListeners();
    }
  }

  // Water Level setters
  void setWaterLevelMin(double value) {
    if (value < _waterLevelMax) {
      _waterLevelMin = value;
      _updateVirtualDevice();
      notifyListeners();
    }
  }

  void setWaterLevelMax(double value) {
    if (value > _waterLevelMin) {
      _waterLevelMax = value;
      _updateVirtualDevice();
      notifyListeners();
    }
  }

  // Light Intensity setters
  void setLightMin(double value) {
    if (value < _lightMax) {
      _lightMin = value;
      _updateVirtualDevice();
      notifyListeners();
    }
  }

  void setLightMax(double value) {
    if (value > _lightMin) {
      _lightMax = value;
      _updateVirtualDevice();
      notifyListeners();
    }
  }

  // TDS setters
  void setTdsMin(double value) {
    if (value < _tdsMax) {
      _tdsMin = value;
      _updateVirtualDevice();
      notifyListeners();
    }
  }

  void setTdsMax(double value) {
    if (value > _tdsMin) {
      _tdsMax = value;
      _updateVirtualDevice();
      notifyListeners();
    }
  }

  // Humidity setters
  void setHumidityMin(double value) {
    if (value < _humidityMax) {
      _humidityMin = value;
      _updateVirtualDevice();
      notifyListeners();
    }
  }

  void setHumidityMax(double value) {
    if (value > _humidityMin) {
      _humidityMax = value;
      _updateVirtualDevice();
      notifyListeners();
    }
  }

  // Reset to defaults
  void resetToDefaults() {
    _tempMin = 22.0;
    _tempMax = 27.0;
    _phMin = 6.5;
    _phMax = 7.5;
    _waterLevelMin = 80.0;
    _waterLevelMax = 100.0;
    _lightMin = 60.0;
    _lightMax = 100.0;
    _tdsMin = 800.0;
    _tdsMax = 1200.0;
    _humidityMin = 50.0;
    _humidityMax = 70.0;
    _updateVirtualDevice();
    notifyListeners();
  }
}
