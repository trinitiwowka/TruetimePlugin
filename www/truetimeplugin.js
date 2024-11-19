// Empty constructor
function TruetimePlugin() {}

// The function that calls the native implementation
TruetimePlugin.prototype.getTrueTime = function(ntpHost, successCallback, errorCallback) {
  if (!ntpHost || typeof ntpHost !== 'string' || ntpHost.trim() === '') {
    console.error('Invalid NTP host provided');
    if (typeof errorCallback === 'function') {
      errorCallback('Invalid NTP host');
    }
    return;
  }

  // Проверяем, что successCallback и errorCallback являются функциями
  if (typeof successCallback !== 'function') {
    console.error('Success callback is not a function');
    successCallback = function() {}; // Устанавливаем заглушку
  }
  if (typeof errorCallback !== 'function') {
    console.error('Error callback is not a function');
    errorCallback = function() {}; // Устанавливаем заглушку
  }

  cordova.exec(
      successCallback,
      errorCallback,
      'TruetimePlugin',
      'getTime',
      [ntpHost] // Передаем адрес NTP сервера
  );
};

// Installation constructor
TruetimePlugin.install = function() {
  if (!window.plugins) {
    window.plugins = {};
  }
  window.plugins.truetimeplugin = new TruetimePlugin();
  return window.plugins.truetimeplugin;
};
cordova.addConstructor(TruetimePlugin.install);
