var _lukasmlady$elm_broadcast_channel$Native_BroadcastChannel = function() {
  function open(channelName, settings) {
    return _elm_lang$core$Native_Scheduler.nativeBinding(function(callback) {
      var channel = new BroadcastChannel(channelName);

      channel.addEventListener("message", function(event) {
        _elm_lang$core$Native_Scheduler.rawSpawn(A2(settings.onMessage, channel, event.data));
      });

      callback(_elm_lang$core$Native_Scheduler.succeed(channel));

      return function() {
        if (channel && channel.close) {
          channel.close();
        }
      };
    });
  }

  function send(channel, string) {
    return _elm_lang$core$Native_Scheduler.nativeBinding(function(callback) {
      channel.postMessage(string);

      callback(_elm_lang$core$Native_Scheduler.succeed());
    });
  }

  function close(channel) {
    return _elm_lang$core$Native_Scheduler.nativeBinding(function(callback) {
      channel.close();

      callback(_elm_lang$core$Native_Scheduler.succeed());
    });
  }

  // expose your functions here
  return {
    open: F2(open),
    send: F2(send),
    close: close
  };
}();

