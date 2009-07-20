function feedstory_send(url_prefix, uid, uuid, st1, st2)
{
  var img = document.createElement('img');

  var param_array = {
    'uid' : String(uid),
    'uuid' : String(uuid)
  };
  var query_str = http_build_query(param_array);
  img.src = url_prefix+'/ajax_kt_feedstory_send/?' + query_str;
}